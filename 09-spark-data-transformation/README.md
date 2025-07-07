# 9. 데이터 변환 로직 구현

* 핵심 내용 : Spark SQL, DataFrame API, UDF
* 주요 산출물 : 데이터 변환 모듈, 품질 검증기

---


## 개요

이번 장에서는 HDFS에 저장된 원본 데이터를 Spark를 사용하여 비즈니스 요구사항에 맞게 가공하고 정제하는 방법을 학습합니다. 이전 장에서 정의한 데이터 품질 규칙을 적용하고, 다양한 데이터 변환 작업을 통해 분석에 용이한 형태로 데이터를 만듭니다.

## 주요 작업

1. **Spark 애플리케이션 개발 환경 설정 (로컬)**
2. **데이터 로딩 및 초기 탐색:**
    * HDFS에 저장된 데이터를 Spark DataFrame으로 로드
3. **데이터 정제 (Cleansing):**
    * Null 값 처리, 중복 데이터 제거
    * 데이터 형식 변환 (e.g., String to Timestamp)
4. **데이터 변환 (Transformation):**
    * 파생 변수 생성 (e.g., `request_url`에서 `domain` 추출)
    * 데이터 조인 (e.g., 사용자 정보 마스터 데이터와 조인)
    * 데이터 집계 (Aggregation)
5. **처리된 데이터 저장:**
    * 정제 및 변환이 완료된 데이터를 Parquet, ORC 등 분석에 최적화된 파일 형식으로 HDFS에 다시 저장

## Spark 데이터 변환 코드 예시 (PySpark)

다음은 웹 서버 로그를 정제하고 변환하는 PySpark 코드 예시입니다.

```python
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_timestamp, udf, split
from pyspark.sql.types import StringType

def get_domain(url):
    """URL에서 도메인을 추출하는 UDF"""
    try:
        return url.split('/')[-2]
    except IndexError:
        return None

if __name__ == "__main__":
    spark = SparkSession \
        .builder \
        .appName("LogTransformation") \
        .getOrCreate()

    # 1. 원본 데이터 로드
    raw_df = spark.read.format("text").load("/path/to/raw/logs")

    # 예시: CSV 형태의 로그라고 가정하고 파싱
    # 실제로는 정규식이나 JSON 파서를 사용할 수 있음
    parsed_df = raw_df.select(
        split(col("value"), ",")[0].alias("timestamp_str"),
        split(col("value"), ",")[1].alias("user_id"),
        split(col("value"), ",")[2].alias("request_url"),
        split(col("value"), ",")[3].cast("int").alias("http_status_code")
    )

    # 2. 데이터 정제
    # Null 값 처리 (user_id가 없는 로그는 제외)
    cleansed_df = parsed_df.filter(col("user_id").isNotNull())

    # 데이터 형식 변환
    cleansed_df = cleansed_df.withColumn(
        "event_timestamp",
        to_timestamp(col("timestamp_str"), "yyyy-MM-dd HH:mm:ss")
    )

    # 3. 데이터 변환
    # UDF 등록 및 파생 변수 생성
    get_domain_udf = udf(get_domain, StringType())
    transformed_df = cleansed_df.withColumn(
        "domain",
        get_domain_udf(col("request_url"))
    )

    # 필요한 컬럼만 선택
    final_df = transformed_df.select(
        "event_timestamp", "user_id", "domain", "http_status_code"
    )

    final_df.printSchema()
    final_df.show(10, truncate=False)

    # 4. 처리된 데이터 저장
    final_df.write \
        .mode("overwrite") \
        .partitionBy("domain") \
        .parquet("/path/to/processed/logs")

    spark.stop()

```

## Spark 애플리케이션 제출

작성된 Python 스크립트(`log_transformation.py`)를 클러스터에 제출하여 실행합니다.

```bash
# s1 서버에서 실행
/usr/local/spark/bin/spark-submit \
  --master yarn \
  --deploy-mode client \
  log_transformation.py
```

* **`--master yarn`**: Spark 애플리케이션을 YARN 클러스터 위에서 실행합니다.
* **`--deploy-mode client`**: 드라이버 프로그램이 `spark-submit`을 실행한 클라이언트(s1)에서 실행됩니다. 디버깅에 용이합니다. 대규모 작업에서는 `cluster` 모드를 사용하는 것이 좋습니다.

## 다음 과정

다음 장에서는 지금까지 구축한 데이터 수집(Kafka), 처리(Spark), 저장(HDFS) 파이프라인을 하나로 통합하고, 워크플로우 관리 도구를 사용하여 전체 과정을 자동화하는 방법을 학습합니다.

```
