# 12. 비용 최적화 및 보안

* 핵심 내용 : 비용 모니터링, IAM 정책, S3 버킷 정책
* 주요 산출물 : 비용 리포트, 보안 체크리스트

---


## AWS 비용 최적화 전략
### 12.1 EC2 인스턴스 최적화
* **Right Sizing**: Oracle Linux EC2 인스턴스 사용률 분석 및 적정 크기 조정
* **Reserved Instance**: 1년 예약 인스턴스로 최대 75% 비용 절감
* **Spot Instance**: 비프로덕션 환경의 Hadoop 워커 노드에 스팟 인스턴스 활용
* **Auto Scaling**: 트래픽 패턴에 따른 동적 스케일링으로 비용 효율성 극대화
* **인스턴스 스케줄링**: 개발/테스트 환경 자동 시작/종료 스케줄링

### 12.2 스토리지 비용 최적화
* **EBS 볼륨 타입**: gp3 사용으로 gp2 대비 20% 비용 절감
* **S3 Storage Class**: 
  - Standard → IA (30일 후)
  - IA → Glacier (90일 후) 
  - Glacier → Deep Archive (365일 후)
* **HDFS vs S3**: 장기 보관 데이터는 S3로 이전하여 EBS 비용 절감
* **데이터 압축**: Parquet + Snappy 압축으로 저장 공간 70% 절약

### 12.3 네트워크 비용 최적화
* **VPC Endpoint**: S3, DynamoDB 접근 시 NAT Gateway 비용 제거
* **CloudFront**: 정적 대시보드 콘텐츠 CDN 캐싱으로 데이터 전송 비용 절감
* **AZ간 트래픽**: 같은 AZ 내 배치로 크로스 AZ 데이터 전송 비용 최소화
* **Dedicated Tenancy**: 멀티테넌시로 하드웨어 공유 비용 절감

## AWS 보안 강화
### 12.4 네트워크 보안
* **VPC 설계**: 
  - Public Subnet: Bastion Host, NAT Gateway
  - Private Subnet: Hadoop 클러스터, Kafka, Spark
  - Database Subnet: 격리된 데이터베이스 전용 서브넷
* **Security Group**: 
  - SSH (22): Bastion Host에서만 접근
  - Hadoop (9000, 9870): 클러스터 내부만 허용
  - Kafka (9092): Spark에서만 접근 허용
* **NACL**: 서브넷 레벨 추가 방화벽 규칙
* **WAF**: 웹 애플리케이션 방화벽으로 대시보드 보호

### 12.5 액세스 제어
* **IAM 역할**: 
  - EC2Role: S3 읽기/쓰기, CloudWatch 메트릭 전송
  - DataPipelineRole: EMR, Kinesis, Lambda 접근 권한
  - DeveloperRole: 개발자 최소 권한 부여
* **MFA**: 루트 계정 및 관리자 계정 다중 인증 필수
* **Key Rotation**: EC2 키페어 정기 교체 (90일 주기)
* **Secrets Manager**: 데이터베이스 패스워드, API 키 암호화 저장

### 12.6 데이터 암호화
* **저장 데이터 암호화**: 
  - EBS: 기본 KMS 키로 암호화
  - S3: Server-Side Encryption (SSE-S3)
  - RDS: TDE (Transparent Data Encryption)
* **전송 데이터 암호화**: 
  - HTTPS/TLS: 모든 API 통신
  - Kafka SSL: 클러스터 간 통신 암호화
  - VPN: 온프레미스 연결 시 암호화 터널

## AWS 모니터링 및 거버넌스
### 12.7 비용 모니터링
* **Cost Explorer**: 월별 비용 트렌드 분석 및 예측
* **Budget Alerts**: 월 $500 초과 시 알림 설정
* **Billing Anomaly Detection**: AI 기반 이상 지출 패턴 감지
* **Resource Tagging**: 환경별, 프로젝트별 비용 추적
* **Cost Allocation Report**: 상세 비용 분석 리포트

### 12.8 보안 모니터링
* **CloudTrail**: 모든 API 호출 로깅 및 감사
* **GuardDuty**: 머신러닝 기반 위협 탐지
* **Config**: 리소스 구성 변경 추적 및 컴플라이언스 점검
* **Security Hub**: 통합 보안 대시보드
* **Inspector**: EC2 인스턴스 취약점 스캔

### 12.9 백업 및 복구
* **EBS Snapshot**: 일일 자동 스냅샷 (7일 보관)
* **S3 Cross-Region Replication**: 재해 복구용 다른 리전 복제
* **RTO/RPO 목표**: 
  - RTO (Recovery Time Objective): 4시간
  - RPO (Recovery Point Objective): 1시간
* **Disaster Recovery**: 다른 AZ/리전 자동 failover

## 컴플라이언스 및 거버넌스
### 12.10 조직 정책
* **Organizations**: 멀티 계정 중앙 관리
* **Service Control Policy**: 계정별 서비스 사용 제한
* **CloudFormation**: Infrastructure as Code로 일관된 배포
* **System Manager**: 패치 관리 및 구성 표준화

### 12.11 데이터 거버넌스
* **Data Classification**: 민감도별 데이터 분류 (Public, Internal, Confidential)
* **Data Retention**: 정책에 따른 데이터 라이프사이클 관리
* **Access Logging**: 데이터 접근 로그 및 감사 추적
* **GDPR Compliance**: 개인정보 처리 방침 준수

## 실습 과제
### 12.12 비용 최적화 실습
* **과제 1**: EC2 인스턴스 Right Sizing 분석
* **과제 2**: S3 Lifecycle 정책 설정
* **과제 3**: Reserved Instance 구매 계획 수립
* **과제 4**: 월별 비용 예산 및 알림 설정

### 12.13 보안 강화 실습
* **과제 1**: Security Group 최소 권한 설정
* **과제 2**: IAM 역할 기반 접근 제어 구현
* **과제 3**: EBS/S3 암호화 설정
* **과제 4**: CloudTrail 로그 분석

## 예상 비용 분석
### 12.14 월간 운영 비용 추정
| 서비스            | 사양               | 월간 비용 |
| ----------------- | ------------------ | --------- |
| EC2 (3 x m5.large) | Oracle Linux       | $180      |
| EBS (600GB)       | gp3 타입           | $60       |
| S3 (1TB)          | Standard + IA      | $25       |
| NAT Gateway       | 2개 (HA)           | $90       |
| CloudWatch        | 로그 + 메트릭      | $20       |
| **총 월간 비용**  |                    | **$375**  |

### 12.15 최적화 후 절감 효과
* **Right Sizing**: 30% 절감 ($54)
* **Reserved Instance**: 40% 절감 ($72)
* **S3 Lifecycle**: 50% 절감 ($12.5)
* **VPC Endpoint**: NAT Gateway 50% 절감 ($45)
* **총 절감액**: $183.5 (49% 절감)
* **최적화 후 비용**: $191.5/월

## 주요 산출물
* AWS 비용 최적화 전략 가이드
* 보안 아키텍처 설계 문서
* 컴플라이언스 체크리스트
* 월간 비용 모니터링 대시보드
