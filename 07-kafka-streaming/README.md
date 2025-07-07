# 7. Kafka 실시간 스트리밍

* 핵심 내용 : EC2 기반 Kafka 클러스터, 데이터 수집기
* 주요 산출물 : Kafka 클러스터, 데이터 수집기

---


## 개요

이번 장에서는 실시간으로 발생하는 데이터를 처리하기 위한 메시징 시스템인 Apache Kafka를 설치하고 구성합니다. Kafka를 통해 데이터를 안정적으로 수집하고, 이를 Spark Streaming에서 소비하여 실시간으로 처리하는 파이프라인의 기초를 실습합니다.

## 주요 작업

1. **ZooKeeper 및 Kafka 설치:**
    * Ansible을 사용하여 클러스터(s1, s2, s3)에 ZooKeeper와 Kafka 설치
2. **Kafka Topic 생성:**
    * 데이터 스트림을 위한 Topic 생성
3. **Kafka Producer 및 Consumer 테스트:**
    * 콘솔에서 Producer를 이용해 메시지를 보내고, Consumer를 이용해 메시지를 수신하는지 확인
4. **Spark Streaming과 연동:**
    * 간단한 Spark Streaming 애플리케이션을 작성하여 Kafka Topic의 데이터를 실시간으로 읽어 처리

## 1. ZooKeeper 및 Kafka 설치 (Ansible)

Kafka는 클러스터의 메타데이터 관리를 위해 ZooKeeper를 사용합니다. Ansible Playbook에 ZooKeeper와 Kafka를 설치하는 Task를 추가합니다.

### Playbook 추가 (`install_kafka.yml` 예시)

```yaml
---
- name: Install Kafka Cluster
  hosts: hadoop_cluster
  become: yes
  tasks:
    # --- ZooKeeper 설치 ---
    - name: Download and unarchive ZooKeeper
      unarchive:
        src: https://archive.apache.org/dist/zookeeper/zookeeper-3.7.0/apache-zookeeper-3.7.0-bin.tar.gz
        dest: /usr/local/
        remote_src: yes
        creates: /usr/local/apache-zookeeper-3.7.0-bin

    - name: Create symlink for ZooKeeper
      file:
        src: /usr/local/apache-zookeeper-3.7.0-bin
        dest: /usr/local/zookeeper
        state: link

    # ... (ZooKeeper 설정: zoo.cfg 파일 생성, myid 설정 등)

    # --- Kafka 설치 ---
    - name: Download and unarchive Kafka
      unarchive:
        src: https://archive.apache.org/dist/kafka/2.8.1/kafka_2.13-2.8.1.tgz
        dest: /usr/local/
        remote_src: yes
        creates: /usr/local/kafka_2.13-2.8.1

    - name: Create symlink for Kafka
      file:
        src: /usr/local/kafka_2.13-2.8.1
        dest: /usr/local/kafka
        state: link

    # ... (Kafka 설정: server.properties 파일 생성, broker.id, zookeeper.connect 등 설정)
```

Playbook 실행 후, 각 서버에서 ZooKeeper와 Kafka 서버를 순서대로 실행합니다.

```bash
# 모든 서버에서 ZooKeeper 실행
/usr/local/zookeeper/bin/zkServer.sh start

# 모든 서버에서 Kafka 실행
/usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties
```

## 2. Kafka Topic 생성

**s1 서버**에서 실습에 사용할 `logs`라는 이름의 Topic을 생성합니다. 파티션은 3개, 복제 계수는 2로 설정하여 데이터의 분산 저장과 안정성을 확보합니다.

```bash
/usr/local/kafka/bin/kafka-topics.sh --create \
  --bootstrap-server s1:9092,s2:9092,s3:9092 \
  --replication-factor 2 \
  --partitions 3 \
  --topic logs
```

## 3. Kafka Producer 및 Consumer 테스트

* **콘솔 Producer 실행 (s1 서버):**
    * 터미널을 열고 아래 명령어를 실행한 뒤, 몇 줄의 메시지를 입력하고 Enter를 칩니다.
    ```bash
    /usr/local/kafka/bin/kafka-console-producer.sh --broker-list s1:9092,s2:9092,s3:9092 --topic logs
    > This is a test log message.
    > Another log message.
    ```

* **콘솔 Consumer 실행 (s2 서버):**
    * 다른 터미널을 열고 s2 서버에 접속하여 아래 명령어를 실행합니다. s1에서 입력한 메시지가 출력되는 것을 확인할 수 있습니다.
    ```bash
    /usr/local/kafka/bin/kafka-console-consumer.sh --bootstrap-server s1:9092,s2:9092,s3:9092 --topic logs --from-beginning
    This is a test log message.
    Another log message.
    ```

## 4. Spark Streaming과 연동

Kafka로부터 실시간으로 로그를 읽어 단어 수를 세는 간단한 Spark Streaming 애플리케이션을 작성합니다. (Python 예시)

### `kafka_wordcount.py`

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import explode, split

if __name__ == "__main__":
    spark = SparkSession \
        .builder \
        .appName("KafkaWordCount") \
        .getOrCreate()

    # Kafka 소스로부터 스트리밍 DataFrame 생성
    lines = spark \
        .readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", "s1:9092,s2:9092,s3:9092") \
        .option("subscribe", "logs") \
        .load() \
        .selectExpr("CAST(value AS STRING)")

    # 단어 분리
    words = lines.select(
        explode(
            split(lines.value, ' ')
        ).alias('word')
    )

    # 단어 수 계산
    wordCounts = words.groupBy('word').count()

    # 콘솔에 결과 출력
    query = wordCounts \
        .writeStream \
        .outputMode('complete') \
        .format('console') \
        .start()

    query.awaitTermination()
```

### 애플리케이션 제출

Spark과 Kafka를 연동하기 위한 라이브러리와 함께 `spark-submit`을 실행합니다.

```bash
/usr/local/spark/bin/spark-submit \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.2.1 \
  kafka_wordcount.py
```

이제 Kafka Producer 콘솔에서 새로운 메시지를 입력하면, `spark-submit`을 실행한 콘솔에 실시간으로 단어 수가 집계되어 출력되는 것을 확인할 수 있습니다.

## 다음 챕터

다음 장에서는 데이터 파이프라인에서 데이터 품질을 보장하기 위한 요구사항을 정의하고, 데이터 검증 및 정제 전략에 대해 실습합니다.
