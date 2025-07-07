#!/bin/bash

# AWS 고급 분석 서비스 설정 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== AWS 고급 분석 서비스 구성 도구 ===${NC}"

# 변수 설정
REGION=${AWS_REGION:-ap-northeast-2}
BUCKET_NAME="bigdata-analytics-$(date +%s)"
KINESIS_STREAM="fms-sensor-stream"
EMR_CLUSTER_NAME="bigdata-emr-cluster"

echo -e "${YELLOW}리전: ${REGION}${NC}"
echo -e "${YELLOW}S3 버킷: ${BUCKET_NAME}${NC}"

# 1. S3 버킷 생성 (Data Lake)
echo -e "\n${GREEN}1. S3 Data Lake 버킷 생성${NC}"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# S3 폴더 구조 생성
aws s3api put-object --bucket $BUCKET_NAME --key raw-data/
aws s3api put-object --bucket $BUCKET_NAME --key processed-data/
aws s3api put-object --bucket $BUCKET_NAME --key curated-data/
aws s3api put-object --bucket $BUCKET_NAME --key temp/

echo -e "${BLUE}S3 Data Lake 구조:${NC}"
echo "  ├─ raw-data/     (원시 데이터)"
echo "  ├─ processed-data/ (전처리 데이터)"
echo "  ├─ curated-data/ (큐레이션 데이터)"
echo "  └─ temp/         (임시 데이터)"

# 2. Kinesis Data Streams 생성
echo -e "\n${GREEN}2. Kinesis Data Streams 생성${NC}"
aws kinesis create-stream \
    --stream-name $KINESIS_STREAM \
    --shard-count 2 \
    --region $REGION

echo "Kinesis Stream 준비 대기..."
aws kinesis wait stream-exists --stream-name $KINESIS_STREAM --region $REGION
echo -e "${BLUE}Kinesis Stream 생성 완료: ${KINESIS_STREAM}${NC}"

# 3. Kinesis Data Firehose 생성
echo -e "\n${GREEN}3. Kinesis Data Firehose 생성${NC}"
cat > firehose-config.json << EOF
{
    "DeliveryStreamName": "fms-firehose-s3",
    "S3DestinationConfiguration": {
        "RoleARN": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/firehose-delivery-role",
        "BucketARN": "arn:aws:s3:::${BUCKET_NAME}",
        "Prefix": "raw-data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/",
        "ErrorOutputPrefix": "error-data/",
        "BufferingHints": {
            "SizeInMBs": 1,
            "IntervalInSeconds": 60
        },
        "CompressionFormat": "GZIP",
        "DataFormatConversionConfiguration": {
            "Enabled": true,
            "OutputFormatConfiguration": {
                "Serializer": {
                    "ParquetSerDe": {}
                }
            }
        }
    }
}
EOF

# 4. AWS Glue 데이터 카탈로그 설정
echo -e "\n${GREEN}4. AWS Glue 데이터 카탈로그 설정${NC}"
aws glue create-database \
    --database-input Name=bigdata_catalog,Description="Big Data Analytics Catalog" \
    --region $REGION

# Glue Crawler 생성
cat > crawler-config.json << EOF
{
    "Name": "fms-data-crawler",
    "Role": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/GlueServiceRole",
    "Targets": {
        "S3Targets": [
            {
                "Path": "s3://${BUCKET_NAME}/processed-data/"
            }
        ]
    },
    "DatabaseName": "bigdata_catalog",
    "Schedule": "cron(0 2 * * ? *)"
}
EOF

aws glue create-crawler --cli-input-json file://crawler-config.json --region $REGION

# 5. EMR Serverless 애플리케이션 생성
echo -e "\n${GREEN}5. EMR Serverless 애플리케이션 생성${NC}"
cat > emr-serverless-config.json << EOF
{
    "name": "fms-spark-analytics",
    "releaseLabel": "emr-6.9.0",
    "type": "Spark",
    "initialCapacity": {
        "driver": {
            "workerCount": 1,
            "workerConfiguration": {
                "cpu": "2 vCPU",
                "memory": "4 GB"
            }
        },
        "executor": {
            "workerCount": 2,
            "workerConfiguration": {
                "cpu": "2 vCPU",
                "memory": "4 GB"
            }
        }
    },
    "maximumCapacity": {
        "cpu": "16 vCPU",
        "memory": "32 GB"
    },
    "autoStartConfiguration": {
        "enabled": true
    },
    "autoStopConfiguration": {
        "enabled": true,
        "idleTimeoutMinutes": 10
    }
}
EOF

EMR_APP_ID=$(aws emr-serverless create-application --cli-input-json file://emr-serverless-config.json --region $REGION --query 'applicationId' --output text)
echo -e "${BLUE}EMR Serverless 애플리케이션 ID: ${EMR_APP_ID}${NC}"

# 6. Athena 워크그룹 생성
echo -e "\n${GREEN}6. Athena 워크그룹 생성${NC}"
aws athena create-work-group \
    --name bigdata-analytics \
    --description "Big Data Analytics Workgroup" \
    --configuration ResultConfigurationUpdates='{OutputLocation=s3://'$BUCKET_NAME'/athena-results/}',EnforceWorkGroupConfiguration=true \
    --region $REGION

# 7. QuickSight 데이터 소스 준비
echo -e "\n${GREEN}7. QuickSight 데이터 소스 정보${NC}"
echo -e "${BLUE}QuickSight 설정을 위한 정보:${NC}"
echo "  - 데이터 소스: Athena"
echo "  - 데이터베이스: bigdata_catalog"
echo "  - 워크그룹: bigdata-analytics"
echo "  - S3 버킷: s3://$BUCKET_NAME"

# 8. Lambda 함수 생성 (데이터 처리)
echo -e "\n${GREEN}8. Lambda 데이터 처리 함수 생성${NC}"
cat > lambda-function.py << 'EOF'
import json
import boto3
import base64
from datetime import datetime

def lambda_handler(event, context):
    """
    Kinesis 트리거로 실행되는 실시간 데이터 처리 함수
    """
    output = []
    
    for record in event['Records']:
        # Kinesis 데이터 디코딩
        payload = base64.b64decode(record['kinesis']['data'])
        data = json.loads(payload.decode('utf-8'))
        
        # 데이터 품질 검증
        if validate_data(data):
            # 데이터 변환 및 강화
            transformed_data = transform_data(data)
            
            output.append({
                'recordId': record['recordId'],
                'result': 'Ok',
                'data': base64.b64encode(
                    json.dumps(transformed_data).encode('utf-8')
                ).decode('utf-8')
            })
        else:
            # 유효하지 않은 데이터는 에러 처리
            output.append({
                'recordId': record['recordId'],
                'result': 'ProcessingFailed'
            })
    
    return {'records': output}

def validate_data(data):
    """데이터 품질 검증"""
    required_fields = ['device_id', 'timestamp', 'temperature', 'humidity']
    return all(field in data for field in required_fields)

def transform_data(data):
    """데이터 변환 및 강화"""
    # 타임스탬프 ISO 형식으로 변환
    if isinstance(data['timestamp'], (int, float)):
        data['timestamp'] = datetime.fromtimestamp(data['timestamp']).isoformat()
    
    # 온도 단위 변환 (섭씨 → 화씨)
    if 'temperature' in data:
        data['temperature_fahrenheit'] = data['temperature'] * 9/5 + 32
    
    # 이상값 플래그 추가
    data['anomaly_flag'] = detect_anomaly(data)
    
    # 파티션 키 추가 (년/월/일)
    dt = datetime.fromisoformat(data['timestamp'])
    data['year'] = dt.year
    data['month'] = dt.month
    data['day'] = dt.day
    
    return data

def detect_anomaly(data):
    """간단한 이상값 탐지"""
    temp = data.get('temperature', 0)
    humidity = data.get('humidity', 0)
    
    # 온도나 습도가 정상 범위를 벗어나면 이상값으로 판단
    return temp < -40 or temp > 60 or humidity < 0 or humidity > 100
EOF

# 9. CloudWatch 대시보드 생성
echo -e "\n${GREEN}9. CloudWatch 대시보드 생성${NC}"
cat > dashboard-config.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["AWS/Kinesis", "IncomingRecords", "StreamName", "${KINESIS_STREAM}"],
                    ["AWS/Kinesis", "OutgoingRecords", "StreamName", "${KINESIS_STREAM}"]
                ],
                "period": 300,
                "stat": "Sum",
                "region": "${REGION}",
                "title": "Kinesis 스트림 처리량"
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    ["AWS/EMR", "AppsRunning"],
                    ["AWS/EMR", "AppsCompleted"]
                ],
                "period": 300,
                "stat": "Average",
                "region": "${REGION}",
                "title": "EMR 애플리케이션 상태"
            }
        }
    ]
}
EOF

aws cloudwatch put-dashboard \
    --dashboard-name "BigDataAnalytics" \
    --dashboard-body file://dashboard-config.json \
    --region $REGION

# 10. 설정 완료 요약
echo -e "\n${GREEN}=== AWS 고급 분석 서비스 설정 완료 ===${NC}"
echo -e "${YELLOW}생성된 리소스:${NC}"
echo "  ✓ S3 Data Lake: s3://$BUCKET_NAME"
echo "  ✓ Kinesis Stream: $KINESIS_STREAM"
echo "  ✓ Glue Database: bigdata_catalog"
echo "  ✓ EMR Serverless: $EMR_APP_ID"
echo "  ✓ Athena Workgroup: bigdata-analytics"
echo "  ✓ CloudWatch Dashboard: BigDataAnalytics"

echo -e "\n${YELLOW}다음 단계:${NC}"
echo "1. IAM 역할 생성 및 권한 설정"
echo "2. QuickSight에서 Athena 데이터 소스 연결"
echo "3. SageMaker 모델 학습 및 배포"
echo "4. Lambda 함수 배포 및 Kinesis 트리거 설정"
echo "5. 실시간 데이터 파이프라인 테스트"

# 임시 파일 정리
rm -f firehose-config.json crawler-config.json emr-serverless-config.json dashboard-config.json

echo -e "\n${GREEN}설정 스크립트 실행 완료!${NC}"
