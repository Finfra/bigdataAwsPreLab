# FMS BigData AWS Pre-Lab

AWS EC2 기반 빅데이터 실시간 처리 시스템 구축 실습 과정

## 🎯 프로젝트 개요

**FMS(Factory Management System) 빅데이터 파이프라인**을 AWS EC2 환경에서 Terraform과 Ansible을 이용해 구축하는 종합 실습 프로젝트입니다. *100*개 장비의 센서 데이터를 실시간으로 수집, 처리, 저장하고 모니터링하는 완전한 데이터 파이프라인을 구현합니다.


### 핵심 기술 스택

* **데이터 수집**: Python Collector + FMS API  
* **메시지 큐**: Apache Kafka (2노드 클러스터, EC2 기반)  
* **스트림 처리**: Apache Spark Streaming (EC2 기반)  
* **분산 저장**: Hadoop 저장소를 AWS S3로 지정 (EC2 기반)  
* **모니터링**: Grafana + Prometheus (EC2 기반)  
* **인프라 관리**: AWS EC2, Terraform, Ansible  

### 주요 성과 지표

* **처리량**: 47 msg/sec (목표 50 msg/sec 대비 94%)  
* **지연시간**: 25초 엔드투엔드 (목표 30초 이내)  
* **가용성**: 99.7% (목표 99% 이상)  
* **데이터 품질**: 96.2% (목표 95% 이상)  


## 📚 진행 목차

| 장  | 폴더명                         | 제목                       | 핵심 내용                                                     | 주요 산출물                       |
| --- | ------------------------------ | -------------------------- | ------------------------------------------------------------- | --------------------------------- |
| 1   | 01-pre-lab-introduction/       | Pre-Lab 소개               | 프로젝트 목표, AWS 실습 환경 개요, 계정 준비                  | 환경 체크리스트                   |
| 2   | 02-aws-account-setup/          | AWS 계정 및 권한 준비      | IAM, 키페어, S3 버킷, VPC 기본 설정                           | 계정/권한 체크리스트, S3 버킷     |
| 3   | 03-infra-provisioning/         | 인프라 자동화(IaC)         | Terraform으로 EC2, VPC, SG, S3 등 자동 생성                   | Terraform 코드, 인프라 다이어그램 |
| 4   | 04-ansible-automation/         | 서비스 자동화 배포         | Ansible로 Hadoop/Spark/Kafka 자동 설치                        | Ansible 플레이북, 배포 로그       |
| 5   | 05-architecture-design/        | 아키텍처 설계 및 검토      | AWS 기반 분산 아키텍처 설계, 리스크 분석                      | 아키텍처 다이어그램, 리스크 분석  |
| 6   | 06-hadoop-spark-cluster/       | Hadoop/Spark 클러스터 구축 | EC2 기반 분산 스토리지(저장소는 AWS S3 지정)/컴퓨팅 환경 구축 | 클러스터 구축 스크립트, 모니터링  |
| 7   | 07-kafka-streaming/            | Kafka 실시간 스트리밍      | EC2 기반 Kafka 클러스터, 데이터 수집기                        | Kafka 클러스터, 데이터 수집기     |
| 8   | 08-data-quality-requirements/  | 데이터 품질 요건 정의      | 데이터 구조 분석, 품질 규칙, 검증 로직                        | 품질 규칙 정의, 검증 스크립트     |
| 9   | 09-spark-data-transformation/  | 데이터 변환 로직 구현      | Spark SQL, DataFrame API, UDF                                 | 데이터 변환 모듈, 품질 검증기     |
| 10  | 10-integrated-pipeline/        | 통합 파이프라인 개발       | 엔드투엔드 연동, 에러 처리                                    | 통합 파이프라인, 에러 핸들러      |
| 11  | 11-visualization-monitoring/   | 시각화 및 모니터링         | Grafana, Prometheus, CloudWatch 연동                          | 대시보드, 모니터링 리포트         |
| 12  | 12-cost-optimization-security/ | 비용 최적화 및 보안        | 비용 모니터링, IAM 정책, S3 버킷 정책                         | 비용 리포트, 보안 체크리스트      |
| 13  | 13-advanced-aws-analytics/     | Glue/Athena/확장 실습      | Glue ETL, Athena 쿼리, S3 데이터 레이크                       | ETL 스크립트, Athena 쿼리 예제    |
| 14  | 14-project-documentation/      | 프로젝트 문서화            | 기술 문서, 운영 가이드, 개선 계획                             | 아키텍처 문서, 트러블슈팅 가이드  |
| 15  | 15-presentation-feedback/      | 성과 발표 및 피드백        | 프로젝트 발표, 데모, 평가                                     | 발표 자료, 데모 스크립트          |
## 🚀 빠른 시작

### 1. 환경 요구사항

* AWS 계정 및 EC2 권한  
* Terraform, Ansible 설치된 콘솔 서버(Oracle Linux EC2)  
* 최소 8GB RAM, 50GB 디스크  

### 2. 콘솔 서버 설정

* Oracle Linux EC2 인스턴스에 Terraform과 Ansible 설치: https://github.com/Finfra/awsHadoop/tree/main/7.HadoopEco  

### 3. 프로젝트 클론 및 AWS 인프라 구축

* Ansible로 Hadoop spark설치 : https://github.com/Finfra/awsHadoop/tree/main/7.HadoopEco  
Terraform은 EC2 인스턴스(s1, s2, s3)를 자동 생성합니다.  

### 4. Ansible을 이용한 서비스 자동화 설치

Ansible을 이용해 Hadoop 및 Spark 자동 설치:

```bash
cd ../7.HadoopEco
ansible-playbook -i hadoopInstall/df/i1/ansible-hadoop/hosts hadoopInstall/df/i1/ansible-hadoop/hadoop_install.yml -e ansible_python_interpreter=/usr/bin/python3
ansible-playbook -i hadoopInstall/df/i1/ansible-spark/hosts hadoopInstall/df/i1/ansible-spark/spark_install.yml -e ansible_python_interpreter=/usr/bin/python3
```

### 5. 서비스 확인

EC2에서 구축된 서비스의 웹 UI 접속:

* Hadoop NameNode: `http://[s1-instance-ip]:9870`  
* YARN ResourceManager: `http://[s1-instance-ip]:8088`  
* Spark Master: `http://[s1-instance-ip]:8080`  
* Prometheus: `http://[s1-instance-ip]:9090`  

## 🏗️ 아키텍처 개요
### 시스템 아키텍처
```
    ┌──────────────────────────────────┐
    │ i1 : Ansible, Terraform, kafka   │
    └──────────────────────────────────┘
           │       │       │
           ▼       ▼       ▼
        ┌────┐  ┌────┐  ┌────┐
        │ s1 │  │ s2 │  │ s3 │
        └────┘  └────┘  └────┘
```

### 데이터 흐름
```
[FMS API] → [Collector] → [Kafka@EC2] → [Spark@EC2] → [HDFS@EC2]
```

### EC2 노드별 서비스 역할 및 주요 포트

| 노드               | 역할 및 서비스                                                | 주요 포트                                                                                     |
| ------------------ | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| i1 (콘솔 서버)     | Terraform, Ansible 관리 서버                                  | SSH(22)                                                                                       |
| s1 (마스터 노드)   | HDFS NameNode, YARN ResourceManager, Spark Master, Prometheus | SSH(22), NameNode UI(9870), ResourceManager UI(8088), Spark Master UI(8080), Prometheus(9090) |
| s2, s3 (워커 노드) | HDFS DataNode, YARN NodeManager, Spark Worker, Node Exporter  | SSH(22), DataNode UI(9864), NodeManager UI(8042), Spark Worker UI(8081), Node Exporter(9100)  |

## 📊 데이터 처리
### 데이터 소스
* 데이터는 FMS API를 통해 10초 간격으로 수집됩니다.
* 소스 주소 : `curl finfra.iptime.org:9872/1/` ~ `curl finfra.iptime.org:9872/100/` (장비 1~100)  
* 데이터 수집 예
```bash 
  ~ $ curl finfra.iptime.org:9872/1/
{"time": "2025-07-07T08:21:29Z", "DeviceId": 1, "sensor1": 85.69, "sensor2": 85.81, "sensor3": 82.15, "motor1": 1245.16, "motor2": 874.81, "motor3": 1119.36, "isFail": false}
  ~ $ curl finfra.iptime.org:9872/100/
{"time": "2025-07-07T08:21:32Z", "DeviceId": 100, "sensor1": 175.29, "sensor2": 84.14, "sensor3": 148.35, "motor1": 1847.49, "motor2": 146.12, "motor3": 2155.11, "isFail": false}
```


### 실시간 처리 파이프라인

1. **데이터 수집**: Python Collector가 FMS API에서 10초 간격으로 센서 데이터 수집  
2. **메시지 큐잉**: Kafka가 수집된 데이터를 안정적으로 버퍼링 (2개 브로커)  
3. **스트림 처리**: Spark Streaming이 실시간으로 데이터 변환 및 품질 검증  
4. **분산 저장**: HDFS에 파티션 기반으로 데이터 저장 (장비별, 시간별)  
5. **모니터링**: Grafana, Prometheus, CloudWatch에서 실시간 시각화 및 알림  

## 🔍 트러블슈팅

### 일반적인 문제

```bash
# EC2 인스턴스 상태 확인
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Ansible 플레이북 실행 문제
ansible-playbook --syntax-check [playbook.yml]

# 서비스 로그 확인
ssh ec2-user@[instance-ip] 'sudo journalctl -u [service-name]'

# 서비스 재시작
ssh ec2-user@[instance-ip] 'sudo systemctl restart [service-name]'
```

### 성능 및 비용 이슈

- **메모리 부족**: EC2 인스턴스 타입 업그레이드  
- **디스크 공간**: 오래된 로그 및 데이터 정리  
- **비용 초과**: AWS 비용 모니터링 및 알림 설정  

## 옵션 제공 
* 프로젝트 진행시 아래 기술을 대신 사용해도 무방합니다. 

| 오픈소스 기술 | AWS 관리형 서비스 대체재                                                            |
| ------------- | ----------------------------------------------------------------------------------- |
| Apache Spark  | Amazon EMR, AWS Glue                                                                |
| Apache Kafka  | Amazon Kinesis Data Streams |
| Prometheus    | Amazon CloudWatch                                                                   |


## 🚀 향후 발전 방향

### Phase 1 - 안정성 강화

- Auto Scaling 그룹 도입  
- 장애 복구 자동화  
- IAM 권한 세분화  

### Phase 2 - 성능 최적화

- 처리량 3배 향상 (150 msg/sec)  
- 캐싱 레이어 추가  
- GPU 가속 연산 도입  

### Phase 3 - 기능 확장

- AWS Glue ETL 도입  
- Athena 쿼리 및 데이터 레이크 구축  
- CloudWatch 기반 모니터링 및 알림 강화  

## 📁 프로젝트 구조

```
bigdataAwsPreLab/
├── 01-pre-lab-introduction/     
├── 02-aws-account-setup/        
├── 03-infra-provisioning/       
├── 04-ansible-automation/       
├── 05-architecture-design/      
├── 06-hadoop-spark-cluster/     
├── 07-kafka-streaming/          
├── 08-data-quality-requirements/
├── 09-spark-data-transformation/
├── 10-integrated-pipeline/      
├── 11-visualization-monitoring/ 
├── 12-cost-optimization-security/
├── 13-advanced-aws-analytics/   
├── 14-project-documentation/    
├── 15-presentation-feedback/    
└── README.md                    
```

각 폴더는 `README.md`(이론/설명) + `src/`(실습코드/스크립트)로 구성됩니다.

## 🤝 기여 방법

1. 프로젝트 포크  
2. 기능 브랜치 생성 (`git checkout -b feature/AmazingFeature`)  
3. 변경사항 커밋 (`git commit -m 'Add some AmazingFeature'`)  
4. 브랜치에 푸시 (`git push origin feature/AmazingFeature`)  
5. Pull Request 생성  

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 문의 및 지원

- **이슈 트래킹**: GitHub Issues 활용  
- **기술 문의**: 각 장별 README.md의 상세 가이드 참조  
- **긴급 지원**: 강의 노트의 강사 연락처 확인  

---

> **🎯 학습 목표**: 이론과 실습을 통해 AWS 기반 빅데이터 실시간 처리 시스템의 완전한 구축 경험을 제공하며, 현업에서 바로 활용할 수 있는 실무 역량을 기릅니다.

**Happy Learning! 🚀**
