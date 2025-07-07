# 10. 통합 파이프라인 개발

* 핵심 내용 : 엔드투엔드 연동, 에러 처리
* 주요 산출물 : 통합 파이프라인, 에러 핸들러

---


## 개요

이번 장에서는 지금까지 개별적으로 구축했던 컴포넌트들(Kafka, HDFS, Spark)을 하나로 연결하여 완전한 형태의 데이터 파이프라인을 구축합니다. 또한, Apache Airflow와 같은 워크플로우 관리 도구를 도입하여 여러 단계의 작업을 순차적 또는 병렬적으로 자동화하고, 실패 시 재처리하는 등 안정적인 운영 방안을 실습합니다.

## 주요 작업

1. **전체 데이터 흐름 정의:**
    * 데이터 발생부터 최종 저장까지의 전체 흐름을 다시 한번 명확히 정의
2. **워크플로우 관리 도구(Airflow) 설치 및 구성:**
    * 콘솔 서버에 Airflow 설치
    * Airflow DAG(Directed Acyclic Graph) 작성
3. **파이프라인 자동화:**
    * 스케줄에 따라 주기적으로 Spark Job을 실행하여 데이터를 처리하는 DAG 구현
4. **파이프라인 실행 및 모니터링:**
    * Airflow 웹 UI를 통해 DAG를 실행하고, 각 Task의 성공/실패 여부를 모니터링

## 통합 파이프라인 아키텍처

```
+----------------+      +----------------+      +----------------------+      +--------------------+
|  Data Source   |----->|     Kafka      |----->|   Spark Streaming    |----->|  Raw Data (HDFS)   |
+----------------+      +----------------+      | (Micro-batching)     |      +--------------------+
                                                +----------------------+                 |
                                                                                         |
                                                                                         v
+----------------+      +----------------------+      +------------------------+      +--------------------+
| Airflow (on    |----->|   Spark Batch Job    |----->| Processed Data (HDFS)  |----->|   BI Dashboard /   |
| Console Server)|      | (Daily Aggregation)  |      | (Parquet, Partitioned) |      | Analytics Tool     |
+----------------+      +----------------------+      +------------------------+      +--------------------+
```

## 1. Airflow 설치 및 구성

콘솔 서버에 Python 환경을 구성하고 Airflow를 설치합니다.

```bash
# 콘솔 서버에서 실행

# Python 가상환경 생성 및 활성화
python3 -m venv ~/airflow_venv
source ~/airflow_venv/bin/activate

# Airflow 설치
pip install apache-airflow

# Airflow DB 초기화 및 사용자 생성
airflow db init
airflow users create --username admin --password admin --firstname Anonymous --lastname User --role Admin --email admin@example.com

# Airflow Webserver 및 Scheduler 실행
airflow webserver --port 8080 -D
airflow scheduler -D
```

## 2. Airflow DAG 작성

Airflow는 파이프라인의 작업 단위를 `Task`로, 작업의 흐름과 의존성을 `DAG`로 정의합니다. Python 코드로 DAG를 작성하며, `~/airflow/dags` 디렉토리에 저장합니다.

### `log_pipeline_dag.py` 예시

```python
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 7, 7),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'log_processing_pipeline',
    default_args=default_args,
    description='A simple log processing pipeline',
    schedule_interval=timedelta(days=1), # 매일 1회 실행
    catchup=False,
)

# Spark Job을 실행하는 Task 정의
spark_task = SparkSubmitOperator(
    task_id='spark_log_transformation',
    application='/path/to/your/log_transformation.py', # 9장에서 작성한 Spark 스크립트 경로
    conn_id='spark_default', # Airflow UI에서 Spark Connection 설정 필요
    dag=dag,
)

# Task 순서 정의 (이 예제에서는 Task가 하나)
spark_task
```

**참고:** `SparkSubmitOperator`를 사용하려면 Airflow UI의 `Admin -> Connections`에서 `spark_default`라는 이름의 Spark 연결을 생성하고, Master URL (`yarn`)과 Deploy Mode (`client` 또는 `cluster`) 등을 설정해야 합니다.

## 3. 파이프라인 실행 및 모니터링

1. **SSH 터널링**을 사용하여 로컬 브라우저에서 Airflow 웹 UI(`http://localhost:8080`)에 접속합니다.
   ```bash
   ssh -i your-key.pem -L 8080:localhost:8080 ec2-user@console_server_public_ip
   ```
2. 로그인 후, `log_processing_pipeline` DAG가 목록에 나타나는지 확인하고, 수동으로 실행(`Trigger DAG`)하거나 스케줄에 따라 실행되기를 기다립니다.
3. **Graph View**나 **Gantt View**를 통해 DAG의 실행 상태와 각 Task의 진행 상황을 시각적으로 모니터링할 수 있습니다.

## 다음 챕터

다음 장에서는 구축된 파이프라인과 인프라를 안정적으로 운영하기 위해 시각화 도구를 이용한 모니터링 시스템을 구축하는 방법을 실습합니다.
