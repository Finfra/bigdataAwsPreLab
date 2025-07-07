# AWS 클라우드 기반 빅데이터 시스템 아키텍처 문서

## 1. 전체 시스템 아키텍처

### 1.1 아키텍처 개요
FMS(Fleet Management System) 센서 데이터를 실시간으로 수집, 처리, 분석하는 AWS 클라우드 네이티브 빅데이터 시스템

### 1.2 아키텍처 원칙
- **Well-Architected Framework**: 5개 기둥 (운영 우수성, 보안, 안정성, 성능 효율성, 비용 최적화)
- **클라우드 네이티브**: AWS Managed Service 우선 활용
- **서버리스 우선**: 운영 부담 최소화 및 자동 스케일링
- **마이크로서비스**: 느슨한 결합과 높은 응집도
- **이벤트 기반**: 비동기 처리 및 확장성

## 2. 계층별 아키텍처

### 2.1 데이터 수집 계층 (Data Ingestion Layer)
```
FMS API → API Gateway → Lambda → Kinesis Data Streams
                              ↓
                         Kinesis Data Firehose → S3 (Raw Data)
```

**주요 구성요소:**
- **Amazon API Gateway**: RESTful API 엔드포인트, 요청 검증, 스로틀링
- **AWS Lambda**: 실시간 데이터 검증 및 변환
- **Amazon Kinesis Data Streams**: 실시간 스트림 처리 (2 샤드, 1000 records/sec/shard)
- **Amazon Kinesis Data Firehose**: 배치 적재 (S3, 1MB 또는 60초 버퍼)

**데이터 플로우:**
1. FMS 장비 → HTTPS POST → API Gateway
2. API Gateway → Lambda 트리거 → 데이터 검증/변환
3. Lambda → Kinesis Data Streams → 실시간 처리
4. Kinesis Firehose → S3 압축 저장 (Parquet + GZIP)

### 2.2 데이터 처리 계층 (Data Processing Layer)
```
Kinesis Data Streams → EMR Spark Streaming → S3 (Processed Data)
                    ↓
Lambda (Real-time) → DynamoDB (State Store)
                    ↓
                 CloudWatch (Metrics)
```

**주요 구성요소:**
- **Amazon EMR**: Spark 클러스터 (Serverless 또는 EC2)
- **AWS Lambda**: 서버리스 실시간 처리
- **Amazon DynamoDB**: 상태 저장소 및 메타데이터
- **Amazon S3**: 계층화된 데이터 레이크

**처리 로직:**
- **실시간 처리**: Lambda 함수로 이상값 탐지, 알림 발송
- **마이크로배치**: EMR Spark Streaming (10초 마이크로배치)
- **배치 처리**: EMR Spark Job (일일 집계, ETL)

### 2.3 데이터 저장 계층 (Data Storage Layer)
```
S3 Data Lake (Multi-Tier Storage)
├── raw-data/           (Standard)
├── processed-data/     (Standard)
├── curated-data/       (IA after 30 days)
└── archived-data/      (Glacier after 365 days)
```

**스토리지 전략:**
- **Hot Data**: S3 Standard (최근 30일)
- **Warm Data**: S3 IA (30-365일)
- **Cold Data**: S3 Glacier (1년 이후)
- **파티셔닝**: year/month/day/hour 구조
- **압축**: Parquet + Snappy (70% 공간 절약)

### 2.4 데이터 분석 계층 (Data Analytics Layer)
```
Athena (Serverless SQL) → QuickSight (BI Dashboard)
    ↓
Glue Data Catalog (Schema Registry)
    ↓
SageMaker (ML/AI Models)
```

**주요 구성요소:**
- **Amazon Athena**: 서버리스 SQL 쿼리 엔진
- **AWS Glue**: 데이터 카탈로그, ETL, 크롤러
- **Amazon QuickSight**: 비즈니스 인텔리전스 대시보드
- **Amazon SageMaker**: 머신러닝 모델 학습/배포

### 2.5 모니터링 계층 (Monitoring Layer)
```
CloudWatch → SNS → Email/Slack
    ↓         ↓
X-Ray → GuardDuty → Security Hub
    ↓
CloudTrail → OpenSearch
```

**모니터링 스택:**
- **CloudWatch**: 메트릭, 로그, 알람
- **X-Ray**: 분산 트레이싱
- **CloudTrail**: API 호출 감사
- **GuardDuty**: 위협 탐지
- **Config**: 리소스 구성 추적

## 3. 네트워크 아키텍처

### 3.1 VPC 설계
```
VPC (10.0.0.0/16)
├── Public Subnet AZ-1a (10.0.1.0/24)
│   ├── Bastion Host
│   ├── NAT Gateway
│   └── Application Load Balancer
├── Public Subnet AZ-1c (10.0.2.0/24)
│   ├── NAT Gateway (HA)
│   └── ALB (Multi-AZ)
├── Private Subnet AZ-1a (10.0.11.0/24)
│   ├── EMR Master Node
│   ├── EMR Worker Nodes
│   └── EC2 Instances
├── Private Subnet AZ-1c (10.0.12.0/24)
│   ├── EMR Worker Nodes
│   └── EC2 Instances (HA)
├── Database Subnet AZ-1a (10.0.21.0/24)
│   └── RDS Aurora (Primary)
└── Database Subnet AZ-1c (10.0.22.0/24)
    └── RDS Aurora (Replica)
```

### 3.2 보안 그룹 설계
```yaml
BastionSG:
  Inbound: [SSH:22 from MyIP]
  Outbound: [SSH:22 to PrivateSubnet]

EMRSG:
  Inbound: [SSH:22 from BastionSG, 9000:9870 from EMRSG]
  Outbound: [All to 0.0.0.0/0]

DatabaseSG:
  Inbound: [MySQL:3306 from PrivateSubnet]
  Outbound: [None]

LambdaSG:
  Inbound: [None]
  Outbound: [HTTPS:443 to 0.0.0.0/0]
```

## 4. 데이터 모델링

### 4.1 원시 데이터 스키마
```json
{
  "device_id": "string",
  "timestamp": "timestamp",
  "temperature": "double",
  "humidity": "double", 
  "pressure": "double",
  "location": {
    "latitude": "double",
    "longitude": "double"
  },
  "metadata": {
    "version": "string",
    "source": "string"
  }
}
```

### 4.2 처리된 데이터 스키마
```sql
CREATE EXTERNAL TABLE processed_sensor_data (
    device_id string,
    temperature double,
    humidity double,
    pressure double,
    timestamp timestamp,
    temperature_fahrenheit double,
    anomaly_flag boolean,
    anomaly_score double,
    hour int,
    day_of_week int,
    is_weekend boolean
)
PARTITIONED BY (
    year int,
    month int,
    day int,
    hour int
)
STORED AS PARQUET
LOCATION 's3://bigdata-bucket/processed-data/'
```

### 4.3 집계 데이터 스키마
```sql
CREATE TABLE hourly_summary (
    device_id string,
    hour timestamp,
    record_count bigint,
    avg_temperature double,
    min_temperature double,
    max_temperature double,
    temp_stddev double,
    anomaly_count bigint,
    data_quality_score double
)
PARTITIONED BY (year int, month int, day int)
```

## 5. 서비스 통합 아키텍처

### 5.1 이벤트 기반 아키텍처
```
Kinesis → Lambda → SNS → [Email, Slack, PagerDuty]
    ↓       ↓
EventBridge → Step Functions → [SageMaker, EMR]
    ↓
DynamoDB → Lambda → QuickSight API
```

### 5.2 API 아키텍처
```
Client → CloudFront → API Gateway → Lambda → [Kinesis, DynamoDB, S3]
           ↓
       WAF (보안 필터링)
           ↓
    Route 53 (DNS 라우팅)
```

## 6. 재해 복구 아키텍처

### 6.1 Multi-AZ 배포
- **Primary AZ**: ap-northeast-2a (서울)
- **Secondary AZ**: ap-northeast-2c (서울)
- **DR Region**: ap-northeast-1 (도쿄)

### 6.2 백업 전략
```yaml
RTO: 2시간    # Recovery Time Objective
RPO: 15분     # Recovery Point Objective

백업 계층:
  - EBS Snapshot: 일일 (7일 보관)
  - S3 Cross-Region: 실시간
  - RDS Backup: 30일 보관
  - DynamoDB PITR: 35일
```

## 7. 보안 아키텍처

### 7.1 IAM 역할 기반 접근 제어
```yaml
Roles:
  - DataEngineerRole: [EMR, Glue, Athena 전체 권한]
  - DataAnalystRole: [Athena 읽기, QuickSight 전체]
  - DeveloperRole: [Lambda, API Gateway 개발]
  - OperatorRole: [CloudWatch 모니터링만]
```

### 7.2 데이터 암호화
- **전송 중**: TLS 1.2 (모든 API 통신)
- **저장 시**: 
  - S3: SSE-S3 (AES-256)
  - EBS: KMS 암호화
  - RDS: TDE (Transparent Data Encryption)
  - DynamoDB: KMS 암호화

## 8. 성능 및 확장성

### 8.1 Auto Scaling 설계
```yaml
EMR:
  - Managed Scaling: 2-50 노드
  - Spot Instance: 70% 비용 절감
  - Instance Types: [m5.large, m5.xlarge, r5.large]

Lambda:
  - 동시성: 1000
  - 메모리: 512MB-3GB
  - 타임아웃: 15분

Kinesis:
  - 샤드 Auto Scaling: 2-20 샤드
  - 처리량: 2000-20000 records/sec
```

### 8.2 캐싱 전략
```yaml
ElastiCache Redis:
  - 자주 조회되는 집계 데이터
  - 세션 데이터
  - API 응답 캐시

CloudFront:
  - 정적 대시보드 자산
  - API 응답 (5분 TTL)
```

## 9. 비용 최적화

### 9.1 리소스 최적화
```yaml
월간 예상 비용:
  - EC2 (Reserved): $120
  - S3: $35 (Lifecycle 적용)
  - Lambda: $15
  - Kinesis: $25
  - Athena: $20
  - 기타: $35
  총계: $250/월
```

### 9.2 비용 절감 전략
- Reserved Instance: 40% 절감
- Spot Instance: 70% 절감
- S3 Intelligent Tiering: 자동 최적화
- Lambda 실행 시간 최적화

## 10. 운영 및 유지보수

### 10.1 배포 전략
```yaml
CI/CD Pipeline:
  - CodeCommit → CodeBuild → CodeDeploy
  - CloudFormation: Infrastructure as Code
  - Blue/Green 배포
  - 자동 롤백
```

### 10.2 모니터링 및 알림
```yaml
핵심 메트릭:
  - 처리량: > 50 msg/sec
  - 지연시간: < 30초
  - 에러율: < 1%
  - 가용성: > 99.9%

알림 채널:
  - CloudWatch → SNS → Email
  - PagerDuty (Critical)
  - Slack (Warning)
```

## 11. 컴플라이언스 및 거버넌스

### 11.1 데이터 거버넌스
- **분류**: Public, Internal, Confidential
- **보관**: 3년 (법적 요구사항)
- **접근 제어**: RBAC + ABAC
- **감사**: CloudTrail + Config

### 11.2 규정 준수
- **SOC 2 Type II**: AWS 서비스 내장 컴플라이언스
- **GDPR**: 데이터 현지화 및 삭제 권리
- **ISO 27001**: 정보보안 관리 체계

이 아키텍처는 AWS Well-Architected Framework를 기반으로 설계되어 높은 가용성, 확장성, 보안성을 제공하며, 클라우드 네이티브 서비스를 활용하여 운영 복잡성을 최소화했습니다.
