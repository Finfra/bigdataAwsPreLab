# 13. Glue/Athena/확장 실습

* 핵심 내용 : Glue ETL, Athena 쿼리, S3 데이터 레이크
* 주요 산출물 : ETL 스크립트, Athena 쿼리 예제

---


## AWS 네이티브 분석 서비스 활용
### 13.1 Amazon EMR 고급 활용
* **EMR Serverless**: 서버리스 Spark 워크로드 실행
* **EMR on EKS**: Kubernetes 기반 컨테이너 환경에서 Spark 실행
* **EMR Studio**: 웹 기반 통합 개발 환경 (Jupyter Notebook)
* **Instance Fleet**: 여러 인스턴스 타입 혼합으로 비용 최적화
* **Auto Scaling**: 동적 스케일링으로 리소스 효율성 극대화

### 13.2 Amazon Kinesis 실시간 스트리밍
* **Kinesis Data Streams**: 
  - FMS 센서 데이터 실시간 수집
  - 샤드 분할로 처리량 확장 (1000 records/sec per shard)
  - 7일 데이터 보관으로 재처리 지원
* **Kinesis Data Firehose**: 
  - S3, Redshift, OpenSearch 자동 배치 로딩
  - 데이터 변환 (JSON → Parquet) 및 압축
  - 버퍼링 (1MB 또는 60초) 최적화
* **Kinesis Analytics**: SQL 기반 실시간 스트림 분석

### 13.3 AWS Glue 데이터 카탈로그
* **Data Catalog**: 메타데이터 중앙 저장소
* **Crawlers**: S3, HDFS 데이터 자동 스키마 추론
* **ETL Jobs**: PySpark 기반 데이터 변환 작업
* **Data Quality**: 데이터 품질 룰 및 검증 자동화
* **Schema Evolution**: 스키마 변경 버전 관리

## Amazon QuickSight 고급 시각화
### 13.4 QuickSight 엔터프라이즈 기능
* **SPICE 인메모리 엔진**: 10배 빠른 쿼리 성능
* **ML Insights**: 
  - Anomaly Detection: 이상값 자동 탐지
  - Forecasting: 시계열 예측 분석
  - Auto-Narratives: AI 기반 인사이트 자동 생성
* **Embedded Analytics**: 웹 애플리케이션 내 대시보드 임베딩
* **Row-Level Security**: 사용자별 데이터 접근 제어

### 13.5 실시간 대시보드 구현
* **Direct Query**: 실시간 데이터 조회 (Athena, Redshift)
* **Incremental Refresh**: 변경 데이터만 업데이트
* **Custom Visuals**: D3.js 기반 커스텀 차트
* **Mobile Dashboard**: 반응형 모바일 최적화
* **Threshold Alerts**: 임계값 기반 자동 알림

## Amazon Athena 서버리스 분석
### 13.6 Athena 쿼리 최적화
* **Partition Projection**: 동적 파티션 추론으로 성능 향상
* **Columnar Storage**: Parquet + ORC 포맷으로 스캔 비용 80% 절감
* **Compression**: GZIP, Snappy, LZ4 압축 비교 분석
* **Query Result Caching**: 반복 쿼리 결과 캐싱
* **Workgroup**: 쿼리 비용 제한 및 리소스 격리

### 13.7 고급 SQL 분석
* **Window Functions**: ROW_NUMBER, RANK, LAG/LEAD
* **Time Series Analysis**: 
  - Moving Average (3일, 7일, 30일)
  - Seasonal Decomposition
  - Trend Analysis
* **Geospatial Analysis**: PostGIS 함수로 위치 기반 분석
* **Machine Learning**: Amazon SageMaker 모델과 SQL 연동

## Amazon OpenSearch 검색 및 로그 분석
### 13.8 OpenSearch 클러스터 설계
* **Multi-AZ 배포**: 고가용성 3개 마스터 노드
* **Hot-Warm-Cold 아키텍처**: 
  - Hot: 최근 7일 데이터 (SSD)
  - Warm: 30일 데이터 (HDD)
  - Cold: 장기 보관 (S3)
* **Index Lifecycle Management**: 자동 인덱스 롤오버
* **Security**: Fine-grained access control

### 13.9 로그 분석 및 검색
* **Fluent Bit**: 경량 로그 수집 에이전트
* **Logstash**: 로그 파싱 및 변환
* **Kibana Dashboard**: 
  - Application Logs 분석
  - Error Rate 모니터링
  - Performance Metrics 시각화
* **Alerting**: 임계값 기반 자동 알림

## Amazon SageMaker 머신러닝 통합
### 13.10 예측 분석 모델
* **시계열 예측**: 
  - DeepAR: RNN 기반 다변량 시계열 예측
  - Prophet: Facebook 오픈소스 시계열 모델
  - ARIMA: 전통적 통계 모델
* **이상탐지**: 
  - Random Cut Forest: 비지도 학습 이상탐지
  - Isolation Forest: 아웃라이어 탐지
  - One-Class SVM: 정상 패턴 학습
* **분류 모델**: XGBoost, Random Forest로 장비 상태 분류

### 13.11 모델 배포 및 추론
* **SageMaker Endpoint**: 실시간 추론 API
* **Batch Transform**: 대량 배치 추론
* **Multi-Model Endpoint**: 여러 모델 하나의 엔드포인트
* **Auto Scaling**: 트래픽에 따른 동적 스케일링
* **A/B Testing**: 모델 성능 비교 테스트

## AWS Lambda 서버리스 처리
### 13.12 이벤트 기반 아키텍처
* **S3 Event Trigger**: 새 파일 업로드 시 자동 처리
* **Kinesis Trigger**: 스트림 데이터 실시간 처리
* **CloudWatch Event**: 스케줄 기반 배치 작업
* **SQS Integration**: 비동기 메시지 처리
* **Step Functions**: 복잡한 워크플로우 오케스트레이션

### 13.13 서버리스 데이터 파이프라인
* **Data Validation**: Lambda로 실시간 데이터 품질 검증
* **Data Enrichment**: 외부 API 호출하여 데이터 보강
* **Notification Service**: SNS/SES 통한 알림 발송
* **Cost Optimization**: 사용한 만큼만 과금되는 서버리스 모델

## 고급 분석 시나리오
### 13.14 실시간 이상탐지 시스템
* **Architecture Flow**: 
  1. Kinesis Data Streams → Kinesis Analytics
  2. SQL 기반 실시간 이상값 탐지
  3. Lambda 함수로 알림 발송
  4. QuickSight 실시간 대시보드 업데이트
* **탐지 알고리즘**: 
  - Statistical Methods: Z-Score, IQR
  - Machine Learning: Isolation Forest
  - Time Series: ARIMA Residuals

### 13.15 예측적 유지보수 분석
* **Feature Engineering**: 
  - Rolling Statistics (Mean, Std, Min, Max)
  - Lag Features (1h, 6h, 24h ago)
  - Frequency Domain (FFT, Spectral Density)
* **Model Training**: 
  - SageMaker Built-in Algorithm: XGBoost
  - Custom Model: LSTM for Time Series
  - AutoML: SageMaker Autopilot
* **Prediction Pipeline**: 
  - Real-time: SageMaker Endpoint
  - Batch: SageMaker Transform Job

## 성능 벤치마크
### 13.16 서비스별 성능 비교
| 서비스           | 처리량        | 지연시간    | 비용/GB   |
| ---------------- | ------------- | ----------- | --------- |
| Kinesis Streams  | 1000 rec/sec  | < 1초       | $0.014    |
| Kinesis Firehose | 5000 rec/sec  | 60초 버퍼   | $0.029    |
| EMR Spark        | 10GB/min      | 배치        | $0.10     |
| Athena           | 1TB/min       | 초단위      | $5.00/TB  |
| Glue ETL         | 100 DPU       | 분단위      | $0.44/DPU |

### 13.17 비용 효율성 분석
* **자체 구축 vs AWS 서비스**: 
  - 초기 투자: 80% 절감
  - 운영 비용: 60% 절감
  - 확장성: 무제한 스케일링
  - 관리 복잡성: 90% 감소

## 실습 과제
### 13.18 고급 분석 실습
* **과제 1**: Kinesis → EMR → QuickSight 실시간 파이프라인
* **과제 2**: Athena 쿼리 최적화 (파티셔닝, 압축)
* **과제 3**: SageMaker 이상탐지 모델 구축
* **과제 4**: Lambda 서버리스 데이터 처리

### 13.19 성능 최적화 실습
* **과제 1**: EMR 클러스터 Auto Scaling 설정
* **과제 2**: Kinesis 샤드 최적화
* **과제 3**: QuickSight SPICE 성능 튜닝
* **과제 4**: OpenSearch 인덱스 최적화

## 주요 산출물
* AWS 네이티브 분석 아키텍처 설계서
* 실시간 이상탐지 시스템 구현
* 예측적 유지보수 ML 모델
* 고급 분석 대시보드 (QuickSight)
* 성능 벤치마크 및 비용 분석 리포트
