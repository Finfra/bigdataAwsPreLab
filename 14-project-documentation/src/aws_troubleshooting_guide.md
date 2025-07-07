# AWS 클라우드 환경 트러블슈팅 가이드

## 1. 일반적인 AWS 서비스 문제 해결

### 1.1 Amazon Kinesis 문제 해결

#### 처리량 제한 (Throttling) 문제
**증상:**
- `ProvisionedThroughputExceededException` 에러
- 데이터 손실 또는 지연 발생
- CloudWatch에서 WriteProvisionedThroughputExceeded 메트릭 증가

**원인:**
- 샤드당 1000 records/sec 또는 1MB/sec 초과
- Hot Partition (특정 샤드에 트래픽 집중)
- 파티션 키 설계 문제

**해결방안:**
```bash
# 1. 샤드 수 증가
aws kinesis update-shard-count \
    --stream-name fms-sensor-stream \
    --target-shard-count 4 \
    --scaling-type UNIFORM_SCALING

# 2. 파티션 키 개선
# 기존: device_id (Hot Partition 발생)
# 개선: device_id + timestamp (균등 분산)
partition_key = f"{device_id}_{timestamp % 1000}"

# 3. Enhanced Fan-Out 활성화
aws kinesis register-stream-consumer \
    --stream-arn arn:aws:kinesis:region:account:stream/fms-sensor-stream \
    --consumer-name enhanced-consumer
```

#### 데이터 중복 문제
**증상:**
- 같은 데이터가 여러 번 처리됨
- Exactly-once 보장 실패

**해결방안:**
```python
# 멱등성 키 사용
def process_record(record):
    sequence_number = record['kinesis']['sequenceNumber']
    partition_key = record['kinesis']['partitionKey']
    idempotency_key = f"{partition_key}_{sequence_number}"
    
    # DynamoDB에서 중복 처리 확인
    if not is_already_processed(idempotency_key):
        # 실제 처리 로직
        process_data(record['kinesis']['data'])
        mark_as_processed(idempotency_key)
```

### 1.2 Amazon EMR 문제 해결

#### 클러스터 시작 실패
**증상:**
- 클러스터가 STARTING에서 TERMINATED로 변경
- `VALIDATION_ERROR` 또는 `BOOTSTRAP_FAILURE`

**일반적인 원인 및 해결:**
```bash
# 1. 서브넷 IP 부족
aws ec2 describe-subnets --subnet-ids subnet-12345678 \
    --query 'Subnets[0].AvailableIpAddressCount'

# 해결: 더 큰 CIDR 블록 사용 또는 다른 서브넷 선택

# 2. 보안 그룹 규칙 문제
aws emr describe-cluster --cluster-id j-ABCDEFGHIJKLM \
    --query 'Cluster.Ec2InstanceAttributes'

# 해결: EMR 필수 포트 허용 (8443, 8442, 8441)

# 3. 인스턴스 타입 용량 부족
# 해결: 다른 인스턴스 타입 사용 또는 다른 AZ 선택
```

#### Out of Memory (OOM) 에러
**증상:**
- Spark 작업이 실패하며 `OutOfMemoryError`
- YARN 컨테이너 killed 메시지

**해결방안:**
```bash
# 1. Spark 메모리 설정 조정
spark-submit \
    --conf spark.executor.memory=4g \
    --conf spark.executor.memoryFraction=0.8 \
    --conf spark.sql.adaptive.enabled=true \
    --conf spark.sql.adaptive.coalescePartitions.enabled=true \
    your_application.py

# 2. 파티션 수 조정
df.repartition(200).write.mode("overwrite").parquet("s3://bucket/path/")

# 3. 배치 크기 최적화
spark.conf.set("spark.sql.files.maxPartitionBytes", "134217728")  # 128MB
```

#### Spot Instance 중단 문제
**증상:**
- 워커 노드가 예고 없이 종료
- 작업 진행 중 갑작스런 실패

**해결방안:**
```bash
# 1. Mixed Instance Types 사용
aws emr create-cluster \
    --instance-fleets '[
        {
            "Name": "Master",
            "InstanceFleetType": "MASTER",
            "TargetOnDemandCapacity": 1,
            "InstanceTypeConfigs": [
                {"InstanceType": "m5.large"}
            ]
        },
        {
            "Name": "Worker",
            "InstanceFleetType": "CORE",
            "TargetOnDemandCapacity": 1,
            "TargetSpotCapacity": 2,
            "InstanceTypeConfigs": [
                {"InstanceType": "m5.large", "BidPrice": "0.05"},
                {"InstanceType": "m5.xlarge", "BidPrice": "0.10"}
            ]
        }
    ]'

# 2. Checkpointing 활성화
spark.conf.set("spark.sql.streaming.checkpointLocation", "s3://bucket/checkpoints/")
```

### 1.3 AWS Lambda 문제 해결

#### Cold Start 지연시간
**증상:**
- 첫 번째 호출 시 긴 응답 시간 (1-3초)
- 간헐적인 타임아웃 발생

**해결방안:**
```python
# 1. Provisioned Concurrency 설정
aws lambda put-provisioned-concurrency-config \
    --function-name fms-data-processor \
    --qualifier 1 \
    --provisioned-concurrency-capacity 10

# 2. 초기화 코드 최적화
import json
import boto3

# 글로벌 변수로 클라이언트 재사용
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    # 함수 로직
    pass

# 3. Lightweight 라이브러리 사용
# pandas → polars (더 빠른 시작)
# requests → urllib3 (내장 모듈)
```

#### 메모리 부족 문제
**증상:**
- `Runtime.ExitError` 또는 메모리 에러
- CloudWatch에서 MaxMemoryUsed가 할당량 근접

**해결방안:**
```python
# 1. 메모리 사용량 모니터링
import psutil
import os

def get_memory_usage():
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / 1024 / 1024  # MB

# 2. 스트리밍 처리로 메모리 절약
def process_large_file(bucket, key):
    s3_object = s3_client.get_object(Bucket=bucket, Key=key)
    
    # 전체 파일을 메모리에 로드하지 않고 스트리밍 처리
    for line in s3_object['Body'].iter_lines():
        process_line(line)

# 3. 메모리 증가 및 처리 최적화
# 메모리를 1024MB → 3008MB로 증가
# 동시에 처리 시간도 단축됨
```

#### VPC Lambda 타임아웃
**증상:**
- VPC 내 Lambda가 외부 API 호출 시 타임아웃
- ENI 생성 지연

**해결방안:**
```bash
# 1. VPC Endpoint 생성 (S3, DynamoDB)
aws ec2 create-vpc-endpoint \
    --vpc-id vpc-12345678 \
    --service-name com.amazonaws.ap-northeast-2.s3 \
    --route-table-ids rtb-12345678

# 2. NAT Gateway 대신 NAT Instance (비용 절감)
# 3. Lambda Layer 사용으로 패키지 크기 최소화
```

### 1.4 Amazon S3 문제 해결

#### 403 Forbidden 에러
**증상:**
- S3 객체 접근 시 권한 거부
- `AccessDenied` 또는 `SignatureDoesNotMatch`

**진단 및 해결:**
```bash
# 1. IAM 정책 확인
aws iam get-role-policy \
    --role-name EMR_EC2_DefaultRole \
    --policy-name S3Access

# 2. 버킷 정책 확인
aws s3api get-bucket-policy --bucket bigdata-analytics-bucket

# 3. ACL 확인
aws s3api get-object-acl --bucket bigdata-analytics-bucket --key data/file.parquet

# 해결: 최소 권한 원칙으로 정책 수정
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::bigdata-analytics-bucket/data/*"
        }
    ]
}
```

#### Eventually Consistent 문제
**증상:**
- 새로 업로드한 파일이 즉시 보이지 않음
- LIST 작업에서 최신 객체 누락

**해결방안:**
```python
import time
import boto3
from botocore.exceptions import ClientError

def wait_for_object_exists(bucket, key, max_attempts=30):
    """S3 객체 존재 확인 (Eventually Consistent 대응)"""
    s3_client = boto3.client('s3')
    
    for attempt in range(max_attempts):
        try:
            s3_client.head_object(Bucket=bucket, Key=key)
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                time.sleep(1)
                continue
            else:
                raise
    
    return False

# 사용 예시
if wait_for_object_exists('my-bucket', 'data/new-file.parquet'):
    # 파일이 존재할 때만 다음 작업 수행
    process_file('my-bucket', 'data/new-file.parquet')
```

### 1.5 Amazon Athena 문제 해결

#### 쿼리 타임아웃
**증상:**
- 쿼리가 30분 후 자동 취소
- 대량 데이터 스캔으로 인한 성능 저하

**해결방안:**
```sql
-- 1. 파티션 필터링으로 스캔량 감소
SELECT device_id, AVG(temperature)
FROM sensor_data
WHERE year = 2025 AND month = 1 AND day >= 15  -- 파티션 필터 필수
GROUP BY device_id;

-- 2. LIMIT 사용으로 결과 제한
SELECT *
FROM sensor_data
WHERE anomaly_flag = true
ORDER BY timestamp DESC
LIMIT 1000;

-- 3. 압축 및 컬럼형 저장
CREATE TABLE optimized_sensor_data
WITH (
    format = 'PARQUET',
    external_location = 's3://bucket/optimized-data/',
    partitioned_by = ARRAY['year', 'month', 'day']
) AS
SELECT device_id, temperature, humidity, timestamp,
       YEAR(timestamp) as year,
       MONTH(timestamp) as month,
       DAY(timestamp) as day
FROM raw_sensor_data;
```

#### 스키마 불일치 문제
**증상:**
- `HIVE_BAD_DATA` 에러
- 컬럼 타입 불일치

**해결방안:**
```sql
-- 1. 스키마 진화 대응
ALTER TABLE sensor_data 
ADD COLUMNS (new_field string);

-- 2. 파티션 스키마 수정
ALTER TABLE sensor_data 
PARTITION (year=2025, month=1, day=15)
SET LOCATION 's3://bucket/corrected-data/year=2025/month=1/day=15/';

-- 3. 데이터 타입 안전한 변환
SELECT 
    device_id,
    CAST(temperature as DOUBLE) as temperature,
    CASE 
        WHEN humidity ~ '^[0-9]+\.?[0-9]*$' 
        THEN CAST(humidity as DOUBLE)
        ELSE NULL 
    END as humidity
FROM sensor_data;
```

## 2. 네트워크 및 연결 문제

### 2.1 VPC 네트워크 문제

#### 인터넷 연결 실패
**증상:**
- Private Subnet의 인스턴스에서 외부 API 호출 실패
- 패키지 다운로드 불가

**진단 단계:**
```bash
# 1. 라우팅 테이블 확인
aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=vpc-12345678"

# 2. NAT Gateway 상태 확인
aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=vpc-12345678"

# 3. Security Group 규칙 확인
aws ec2 describe-security-groups \
    --group-ids sg-12345678

# 해결: 라우팅 테이블에 NAT Gateway 경로 추가
aws ec2 create-route \
    --route-table-id rtb-private \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id nat-12345678
```

#### Cross-AZ 통신 문제
**증상:**
- 다른 AZ의 서비스 간 연결 실패
- 레이턴시 증가

**해결방안:**
```bash
# 1. Security Group 상호 참조 설정
aws ec2 authorize-security-group-ingress \
    --group-id sg-emr-master \
    --source-group sg-emr-workers \
    --protocol tcp \
    --port 9000

# 2. Network ACL 확인
aws ec2 describe-network-acls \
    --filters "Name=vpc-id,Values=vpc-12345678"

# 3. 동일 AZ 배치로 비용 최적화
# Placement Group 사용
aws ec2 create-placement-group \
    --group-name emr-cluster-pg \
    --strategy cluster
```

### 2.2 DNS 및 서비스 검색 문제

#### 서비스간 통신 실패
**증상:**
- EMR에서 Kinesis endpoint 접근 불가
- DNS resolution 실패

**해결방안:**
```bash
# 1. VPC Endpoint 생성
aws ec2 create-vpc-endpoint \
    --vpc-id vpc-12345678 \
    --service-name com.amazonaws.ap-northeast-2.kinesis-streams \
    --vpc-endpoint-type Interface \
    --subnet-ids subnet-12345678 subnet-87654321

# 2. Route 53 Private Hosted Zone
aws route53 create-hosted-zone \
    --name internal.company.com \
    --vpc VPCRegion=ap-northeast-2,VPCId=vpc-12345678

# 3. EMR에서 직접 endpoint 사용
kinesis_client = boto3.client(
    'kinesis',
    endpoint_url='https://kinesis.ap-northeast-2.amazonaws.com'
)
```

## 3. 성능 문제 진단 및 해결

### 3.1 지연시간 문제

#### End-to-End 지연시간 분석
**진단 도구:**
```bash
# 1. X-Ray 분산 트레이싱 활성화
aws xray create-service-map \
    --service-names "fms-api-gateway,fms-lambda,fms-kinesis"

# 2. CloudWatch Insights로 로그 분석
aws logs start-query \
    --log-group-name "/aws/lambda/fms-processor" \
    --start-time $(date -d "1 hour ago" +%s) \
    --end-time $(date +%s) \
    --query-string 'fields @timestamp, @duration, @requestId | filter @duration > 5000'
```

**병목지점 식별:**
```python
import time
import boto3
from contextlib import contextmanager

@contextmanager
def timer(description):
    start = time.time()
    yield
    print(f"{description}: {time.time() - start:.2f}초")

def process_sensor_data(record):
    with timer("전체 처리 시간"):
        with timer("데이터 파싱"):
            data = json.loads(record['body'])
        
        with timer("품질 검증"):
            if not validate_data(data):
                return
        
        with timer("Kinesis 전송"):
            kinesis_client.put_record(
                StreamName='fms-stream',
                Data=json.dumps(data),
                PartitionKey=data['device_id']
            )
```

### 3.2 처리량 병목 해결

#### Kinesis 샤드 재분할
```bash
# 1. 현재 샤드 사용률 확인
aws cloudwatch get-metric-statistics \
    --namespace AWS/Kinesis \
    --metric-name IncomingRecords \
    --dimensions Name=StreamName,Value=fms-sensor-stream \
    --start-time $(date -d "1 hour ago" --iso-8601) \
    --end-time $(date --iso-8601) \
    --period 300 \
    --statistics Sum

# 2. Hot Shard 식별
aws kinesis list-shards --stream-name fms-sensor-stream

# 3. 샤드 분할
aws kinesis split-shard \
    --stream-name fms-sensor-stream \
    --shard-to-split shardId-000000000000 \
    --new-starting-hash-key 12345678901234567890
```

#### EMR 최적화
```python
# Spark 설정 최적화
spark_conf = {
    # 메모리 최적화
    "spark.executor.memory": "6g",
    "spark.executor.memoryFraction": "0.8",
    "spark.executor.cores": "4",
    
    # I/O 최적화
    "spark.sql.files.maxPartitionBytes": "134217728",  # 128MB
    "spark.sql.files.openCostInBytes": "4194304",     # 4MB
    
    # 셔플 최적화
    "spark.sql.shuffle.partitions": "200",
    "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
    
    # 동적 할당
    "spark.dynamicAllocation.enabled": "true",
    "spark.dynamicAllocation.minExecutors": "2",
    "spark.dynamicAllocation.maxExecutors": "20"
}
```

## 4. 데이터 품질 문제

### 4.1 데이터 손실 감지
```python
def monitor_data_completeness():
    """데이터 완전성 모니터링"""
    
    # 예상 레코드 수 계산
    devices = 50
    minutes_per_hour = 60
    expected_records = devices * minutes_per_hour
    
    # 실제 레코드 수 확인
    actual_records = count_records_last_hour()
    
    completeness = actual_records / expected_records
    
    if completeness < 0.95:
        send_alert(f"데이터 완전성 저하: {completeness:.1%}")
    
    return completeness

def detect_duplicate_data():
    """중복 데이터 탐지"""
    query = """
    SELECT device_id, timestamp, COUNT(*) as count
    FROM sensor_data
    WHERE year = YEAR(CURRENT_DATE) 
      AND month = MONTH(CURRENT_DATE)
      AND day = DAY(CURRENT_DATE)
    GROUP BY device_id, timestamp
    HAVING COUNT(*) > 1
    """
    
    duplicates = athena_client.execute_query(query)
    if duplicates:
        send_alert(f"중복 데이터 감지: {len(duplicates)}건")
```

### 4.2 스키마 드리프트 대응
```python
import great_expectations as ge

def validate_schema_evolution():
    """스키마 변화 감지 및 검증"""
    
    # 예상 스키마 정의
    expected_schema = {
        'device_id': 'string',
        'timestamp': 'timestamp',
        'temperature': 'double',
        'humidity': 'double',
        'pressure': 'double'
    }
    
    # Glue Data Catalog에서 실제 스키마 확인
    table = glue_client.get_table(
        DatabaseName='bigdata_catalog',
        Name='sensor_data'
    )
    
    actual_schema = {
        col['Name']: col['Type'] 
        for col in table['Table']['StorageDescriptor']['Columns']
    }
    
    # 스키마 차이 검출
    schema_diff = set(expected_schema.items()) ^ set(actual_schema.items())
    
    if schema_diff:
        handle_schema_evolution(schema_diff)
```

## 5. 보안 문제 해결

### 5.1 IAM 권한 문제
```bash
# 1. CloudTrail에서 권한 거부 이벤트 확인
aws logs filter-log-events \
    --log-group-name CloudTrail/CloudWatchLogGroup \
    --filter-pattern "{ $.errorCode = \"AccessDenied\" }"

# 2. IAM Access Analyzer 사용
aws accessanalyzer create-analyzer \
    --analyzer-name bigdata-access-analyzer \
    --type ACCOUNT

# 3. 최소 권한 정책 생성
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::123456789012:role/EMR-Role \
    --action-names s3:GetObject \
    --resource-arns arn:aws:s3:::bigdata-bucket/*
```

### 5.2 암호화 키 관리
```bash
# 1. KMS 키 교체
aws kms schedule-key-deletion \
    --key-id alias/bigdata-key \
    --pending-window-in-days 7

# 2. 새 키로 데이터 재암호화
aws s3 cp s3://bucket/data/ s3://bucket/data/ \
    --recursive \
    --sse aws:kms \
    --sse-kms-key-id alias/new-bigdata-key
```

## 6. 비용 최적화 문제

### 6.1 예상치 못한 비용 급증
```bash
# 1. Cost Explorer API로 비용 분석
aws ce get-cost-and-usage \
    --time-period Start=2025-01-01,End=2025-01-31 \
    --granularity DAILY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE

# 2. 리소스 태깅 점검
aws resourcegroupstaggingapi get-resources \
    --resource-type-filters "AWS::S3::Bucket,AWS::EC2::Instance" \
    --tag-filters "Key=Project,Values=BigData"

# 3. 사용하지 않는 리소스 정리
aws ec2 describe-volumes \
    --filters Name=status,Values=available \
    --query 'Volumes[*].[VolumeId,Size,CreateTime]'
```

## 7. 모니터링 및 알림 설정

### 7.1 CloudWatch 알람 설정
```bash
# 처리량 감소 알람
aws cloudwatch put-metric-alarm \
    --alarm-name "Kinesis-Low-Throughput" \
    --alarm-description "Kinesis throughput below threshold" \
    --metric-name IncomingRecords \
    --namespace AWS/Kinesis \
    --statistic Sum \
    --period 300 \
    --threshold 100 \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:ap-northeast-2:123456789012:alerts

# 지연시간 증가 알람
aws cloudwatch put-metric-alarm \
    --alarm-name "EMR-High-Latency" \
    --alarm-description "EMR processing latency too high" \
    --metric-name ProcessingTime \
    --namespace Custom/BigData \
    --statistic Average \
    --period 300 \
    --threshold 30 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 3
```

### 7.2 자동 복구 스크립트
```python
def auto_remediation(alarm_name, metric_name):
    """자동 문제 해결"""
    
    remediation_actions = {
        'Kinesis-Low-Throughput': scale_kinesis_shards,
        'EMR-High-Latency': restart_emr_applications,
        'Lambda-High-Errors': update_lambda_concurrency,
        'S3-High-Costs': cleanup_old_data
    }
    
    action = remediation_actions.get(alarm_name)
    if action:
        action()
        send_notification(f"자동 복구 실행: {alarm_name}")

def scale_kinesis_shards():
    """Kinesis 샤드 자동 스케일링"""
    current_shards = get_shard_count('fms-sensor-stream')
    new_shard_count = min(current_shards * 2, 10)
    
    kinesis_client.update_shard_count(
        StreamName='fms-sensor-stream',
        TargetShardCount=new_shard_count,
        ScalingType='UNIFORM_SCALING'
    )
```

이 트러블슈팅 가이드를 통해 AWS 클라우드 환경에서 발생할 수 있는 다양한 문제들을 체계적으로 진단하고 해결할 수 있습니다. 각 문제별로 단계적 접근 방법과 자동화된 해결책을 제시하여 운영 효율성을 극대화합니다.
