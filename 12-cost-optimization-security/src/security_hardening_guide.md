# AWS 보안 강화 가이드

## 네트워크 보안
### VPC 설계
```yaml
VPC:
  CIDR: 10.0.0.0/16
  
Subnets:
  Public:
    - 10.0.1.0/24 (AZ-1a)
    - 10.0.2.0/24 (AZ-1c)
  Private:
    - 10.0.11.0/24 (AZ-1a)
    - 10.0.12.0/24 (AZ-1c)
  Database:
    - 10.0.21.0/24 (AZ-1a)
    - 10.0.22.0/24 (AZ-1c)
```

### Security Group 규칙
```yaml
BastionSG:
  Inbound:
    - Port: 22, Source: MyIP/32
  Outbound:
    - Port: 22, Destination: PrivateSubnet

HadoopSG:
  Inbound:
    - Port: 22, Source: BastionSG
    - Port: 9000, Source: HadoopSG
    - Port: 9870, Source: HadoopSG
  Outbound:
    - Port: All, Destination: 0.0.0.0/0

KafkaSG:
  Inbound:
    - Port: 9092, Source: SparkSG
    - Port: 2181, Source: KafkaSG
  Outbound:
    - Port: All, Destination: 0.0.0.0/0
```

## IAM 역할 및 정책
### EC2 Role
```json
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
      "Resource": "arn:aws:s3:::bigdata-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### Data Pipeline Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "emr:*",
        "kinesis:*",
        "lambda:InvokeFunction"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-northeast-2"
        }
      }
    }
  ]
}
```

## 데이터 암호화
### EBS 암호화
```bash
aws ec2 create-volume \
  --size 100 \
  --volume-type gp3 \
  --encrypted \
  --kms-key-id alias/ebs-key \
  --availability-zone ap-northeast-2a
```

### S3 암호화
```yaml
S3Bucket:
  Properties:
    BucketEncryption:
      ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            SSEAlgorithm: AES256
    PublicAccessBlockConfiguration:
      BlockPublicAcls: true
      BlockPublicPolicy: true
      IgnorePublicAcls: true
      RestrictPublicBuckets: true
```

### RDS 암호화
```yaml
RDSCluster:
  Properties:
    StorageEncrypted: true
    KmsKeyId: !Ref RDSKey
    DeletionProtection: true
    BackupRetentionPeriod: 30
```

## 모니터링 설정
### CloudTrail 구성
```yaml
CloudTrail:
  Properties:
    IsLogging: true
    S3BucketName: !Ref CloudTrailBucket
    IncludeGlobalServiceEvents: true
    IsMultiRegionTrail: true
    EnableLogFileValidation: true
    EventSelectors:
      - ReadWriteType: All
        IncludeManagementEvents: true
        DataResources:
          - Type: "AWS::S3::Object"
            Values: ["arn:aws:s3:::bigdata-bucket/*"]
```

### GuardDuty 활성화
```bash
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES
```

## 백업 및 복구
### EBS 스냅샷 정책
```json
{
  "ResourceType": "VOLUME",
  "TargetTags": [
    {
      "Key": "Environment",
      "Value": "Production"
    }
  ],
  "Schedules": [
    {
      "Name": "DailySnapshot",
      "CopyTags": true,
      "CreateRule": {
        "Interval": 24,
        "IntervalUnit": "HOURS",
        "Times": ["03:00"]
      },
      "RetainRule": {
        "Count": 7
      }
    }
  ]
}
```

### S3 Cross-Region Replication
```yaml
ReplicationConfiguration:
  Role: !GetAtt ReplicationRole.Arn
  Rules:
    - Id: ReplicateToTokyo
      Status: Enabled
      Prefix: data/
      Destination:
        Bucket: !Sub 'arn:aws:s3:::${BackupBucket}'
        StorageClass: STANDARD_IA
```

## 컴플라이언스 체크리스트
- [ ] IAM 최소 권한 원칙 적용
- [ ] MFA 활성화 (루트 계정 필수)
- [ ] 암호화 설정 (EBS, S3, RDS)
- [ ] VPC Flow Logs 활성화
- [ ] CloudTrail 로깅 활성화
- [ ] Config Rules 설정
- [ ] GuardDuty 위협 탐지 활성화
- [ ] Security Hub 중앙 관리
- [ ] Secrets Manager 사용
- [ ] 정기 보안 검토 수행
