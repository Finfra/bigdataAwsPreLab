import boto3
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import json

class SageMakerAnomalyDetector:
    """
    SageMaker Random Cut Forest를 이용한 이상탐지 시스템
    """
    
    def __init__(self, region='ap-northeast-2'):
        self.region = region
        self.sagemaker = boto3.client('sagemaker', region_name=region)
        self.sagemaker_runtime = boto3.client('sagemaker-runtime', region_name=region)
        self.s3 = boto3.client('s3', region_name=region)
        
        self.model_name = 'fms-anomaly-detector'
        self.endpoint_name = 'fms-anomaly-endpoint'
        self.endpoint_config_name = 'fms-anomaly-config'
        
    def prepare_training_data(self, bucket_name, key_prefix='processed-data/'):
        """
        S3에서 학습 데이터 준비
        """
        print("학습 데이터 준비 중...")
        
        # S3에서 데이터 읽기
        response = self.s3.list_objects_v2(
            Bucket=bucket_name,
            Prefix=key_prefix,
            MaxKeys=100
        )
        
        data_frames = []
        for obj in response.get('Contents', []):
            if obj['Key'].endswith('.csv'):
                obj_response = self.s3.get_object(
                    Bucket=bucket_name,
                    Key=obj['Key']
                )
                df = pd.read_csv(obj_response['Body'])
                data_frames.append(df)
        
        if not data_frames:
            # 샘플 데이터 생성
            df = self.generate_sample_data()
        else:
            df = pd.concat(data_frames, ignore_index=True)
        
        # 특성 엔지니어링
        features = self.feature_engineering(df)
        
        # 학습 데이터를 S3에 저장
        train_file = 'training-data/anomaly-training.csv'
        features.to_csv(f's3://{bucket_name}/{train_file}', index=False)
        
        return f's3://{bucket_name}/{train_file}'
    
    def generate_sample_data(self, days=30):
        """
        테스트용 샘플 데이터 생성
        """
        print("샘플 데이터 생성 중...")
        
        # 시간 범위 생성
        end_time = datetime.now()
        start_time = end_time - timedelta(days=days)
        time_range = pd.date_range(start_time, end_time, freq='1min')
        
        data = []
        for timestamp in time_range:
            # 정상 패턴 (사인파 + 노이즈)
            hour = timestamp.hour
            temp_base = 20 + 10 * np.sin(2 * np.pi * hour / 24)
            humidity_base = 50 + 20 * np.sin(2 * np.pi * hour / 24 + np.pi/4)
            
            # 노이즈 추가
            temperature = temp_base + np.random.normal(0, 2)
            humidity = humidity_base + np.random.normal(0, 5)
            
            # 가끔 이상값 추가 (5% 확률)
            if np.random.random() < 0.05:
                temperature += np.random.normal(0, 20)
                humidity += np.random.normal(0, 30)
            
            data.append({
                'timestamp': timestamp,
                'device_id': f'device_{np.random.randint(1, 21)}',
                'temperature': round(temperature, 2),
                'humidity': round(max(0, min(100, humidity)), 2),
                'pressure': round(1013 + np.random.normal(0, 10), 2)
            })
        
        return pd.DataFrame(data)
    
    def feature_engineering(self, df):
        """
        특성 엔지니어링
        """
        print("특성 엔지니어링 수행 중...")
        
        # 시간 변환
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df = df.sort_values('timestamp')
        
        # 시간 관련 특성
        df['hour'] = df['timestamp'].dt.hour
        df['day_of_week'] = df['timestamp'].dt.dayofweek
        df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)
        
        # 롤링 통계 특성
        for col in ['temperature', 'humidity', 'pressure']:
            df[f'{col}_rolling_mean_5'] = df[col].rolling(window=5).mean()
            df[f'{col}_rolling_std_5'] = df[col].rolling(window=5).std()
            df[f'{col}_rolling_mean_30'] = df[col].rolling(window=30).mean()
            
        # Lag 특성
        for col in ['temperature', 'humidity']:
            df[f'{col}_lag_1'] = df[col].shift(1)
            df[f'{col}_lag_5'] = df[col].shift(5)
        
        # 비율 특성
        df['temp_humidity_ratio'] = df['temperature'] / (df['humidity'] + 1)
        
        # 결측값 제거
        features = df.select_dtypes(include=[np.number]).dropna()
        
        # timestamp와 device_id 제외 (수치형이 아니므로)
        exclude_cols = ['timestamp', 'device_id'] if 'device_id' in features.columns else ['timestamp']
        features = features.drop(columns=[col for col in exclude_cols if col in features.columns])
        
        return features
    
    def create_training_job(self, train_data_path, output_path):
        """
        SageMaker 학습 작업 생성
        """
        print("SageMaker 학습 작업 생성 중...")
        
        # Random Cut Forest 알고리즘 이미지
        image_uri = f"382416733822.dkr.ecr.{self.region}.amazonaws.com/randomcutforest:1"
        
        training_job_name = f"anomaly-detector-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        
        training_params = {
            'TrainingJobName': training_job_name,
            'AlgorithmSpecification': {
                'TrainingImage': image_uri,
                'TrainingInputMode': 'File'
            },
            'RoleArn': f'arn:aws:iam::{boto3.client("sts").get_caller_identity()["Account"]}:role/SageMakerExecutionRole',
            'InputDataConfig': [
                {
                    'ChannelName': 'training',
                    'DataSource': {
                        'S3DataSource': {
                            'S3DataType': 'S3Prefix',
                            'S3Uri': train_data_path,
                            'S3DataDistributionType': 'FullyReplicated'
                        }
                    },
                    'ContentType': 'text/csv',
                    'CompressionType': 'None'
                }
            ],
            'OutputDataConfig': {
                'S3OutputPath': output_path
            },
            'ResourceConfig': {
                'InstanceType': 'ml.m5.large',
                'InstanceCount': 1,
                'VolumeSizeInGB': 30
            },
            'StoppingCondition': {
                'MaxRuntimeInSeconds': 3600
            },
            'HyperParameters': {
                'feature_dim': '20',
                'eval_metrics': 'accuracy,precision_recall_fscore',
                'num_trees': '100',
                'num_samples_per_tree': '256'
            }
        }
        
        response = self.sagemaker.create_training_job(**training_params)
        return training_job_name
    
    def create_model_and_endpoint(self, training_job_name, model_data_url):
        """
        모델 및 엔드포인트 생성
        """
        print("모델 및 엔드포인트 생성 중...")
        
        # 모델 생성
        image_uri = f"382416733822.dkr.ecr.{self.region}.amazonaws.com/randomcutforest:1"
        
        model_params = {
            'ModelName': self.model_name,
            'PrimaryContainer': {
                'Image': image_uri,
                'ModelDataUrl': model_data_url
            },
            'ExecutionRoleArn': f'arn:aws:iam::{boto3.client("sts").get_caller_identity()["Account"]}:role/SageMakerExecutionRole'
        }
        
        self.sagemaker.create_model(**model_params)
        
        # 엔드포인트 구성 생성
        endpoint_config_params = {
            'EndpointConfigName': self.endpoint_config_name,
            'ProductionVariants': [
                {
                    'VariantName': 'AllTraffic',
                    'ModelName': self.model_name,
                    'InitialInstanceCount': 1,
                    'InstanceType': 'ml.t2.medium',
                    'InitialVariantWeight': 1
                }
            ]
        }
        
        self.sagemaker.create_endpoint_config(**endpoint_config_params)
        
        # 엔드포인트 생성
        endpoint_params = {
            'EndpointName': self.endpoint_name,
            'EndpointConfigName': self.endpoint_config_name
        }
        
        self.sagemaker.create_endpoint(**endpoint_params)
        
        print(f"엔드포인트 생성 중: {self.endpoint_name}")
        return self.endpoint_name
    
    def predict_anomaly(self, data):
        """
        실시간 이상탐지 예측
        """
        if isinstance(data, pd.DataFrame):
            # 특성 엔지니어링 적용
            features = self.feature_engineering(data)
            payload = features.to_csv(index=False, header=False)
        else:
            payload = data
        
        response = self.sagemaker_runtime.invoke_endpoint(
            EndpointName=self.endpoint_name,
            ContentType='text/csv',
            Body=payload
        )
        
        result = response['Body'].read().decode('utf-8')
        scores = [float(x) for x in result.strip().split('\n')]
        
        # 이상값 임계값 설정 (상위 5%)
        threshold = np.percentile(scores, 95)
        anomalies = [score > threshold for score in scores]
        
        return {
            'anomaly_scores': scores,
            'anomalies': anomalies,
            'threshold': threshold
        }
    
    def real_time_monitoring(self, kinesis_stream_name):
        """
        실시간 스트림 모니터링
        """
        kinesis = boto3.client('kinesis', region_name=self.region)
        
        # 스트림 샤드 정보 가져오기
        response = kinesis.describe_stream(StreamName=kinesis_stream_name)
        shards = response['StreamDescription']['Shards']
        
        for shard in shards:
            shard_id = shard['ShardId']
            
            # 샤드 이터레이터 생성
            iterator_response = kinesis.get_shard_iterator(
                StreamName=kinesis_stream_name,
                ShardId=shard_id,
                ShardIteratorType='LATEST'
            )
            
            shard_iterator = iterator_response['ShardIterator']
            
            print(f"샤드 {shard_id} 모니터링 시작...")
            
            while shard_iterator:
                # 레코드 읽기
                records_response = kinesis.get_records(
                    ShardIterator=shard_iterator,
                    Limit=10
                )
                
                records = records_response['Records']
                
                if records:
                    # 데이터 처리
                    for record in records:
                        data = json.loads(record['Data'].decode('utf-8'))
                        
                        # 이상탐지 수행
                        df = pd.DataFrame([data])
                        result = self.predict_anomaly(df)
                        
                        if result['anomalies'][0]:
                            print(f"⚠️  이상값 감지: {data}")
                            print(f"   이상값 점수: {result['anomaly_scores'][0]:.4f}")
                            
                            # 알림 발송 (SNS, Slack 등)
                            self.send_alert(data, result['anomaly_scores'][0])
                
                shard_iterator = records_response.get('NextShardIterator')
    
    def send_alert(self, data, anomaly_score):
        """
        이상값 감지 시 알림 발송
        """
        sns = boto3.client('sns', region_name=self.region)
        
        message = {
            'alert_type': 'anomaly_detected',
            'timestamp': datetime.now().isoformat(),
            'device_id': data.get('device_id'),
            'anomaly_score': anomaly_score,
            'data': data
        }
        
        # SNS 토픽으로 알림 발송
        try:
            sns.publish(
                TopicArn='arn:aws:sns:ap-northeast-2:123456789012:anomaly-alerts',
                Message=json.dumps(message, indent=2),
                Subject='FMS 센서 이상값 감지'
            )
        except Exception as e:
            print(f"알림 발송 실패: {e}")

def main():
    """
    메인 실행 함수
    """
    detector = SageMakerAnomalyDetector()
    
    # 1. 학습 데이터 준비
    bucket_name = 'bigdata-analytics-bucket'
    train_data_path = detector.prepare_training_data(bucket_name)
    
    # 2. 모델 학습
    output_path = f's3://{bucket_name}/model-output/'
    training_job_name = detector.create_training_job(train_data_path, output_path)
    
    print(f"학습 작업 생성됨: {training_job_name}")
    print("학습 완료 후 모델 배포를 진행하세요.")

if __name__ == "__main__":
    main()
