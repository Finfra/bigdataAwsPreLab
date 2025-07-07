# 8. 데이터 품질 요건 정의

* 핵심 내용 : 데이터 구조 분석, 품질 규칙, 검증 로직
* 주요 산출물 : 품질 규칙 정의, 검증 스크립트

---


## 개요

이번 장에서는 신뢰할 수 있는 데이터 파이프라인을 구축하기 위해 데이터 품질(Data Quality)의 중요성을 이해하고, 우리 프로젝트에 맞는 데이터 품질 요구사항을 정의하는 방법을 실습합니다. "Garbage In, Garbage Out"이라는 말처럼, 데이터 품질 관리는 분석 결과의 신뢰도와 직결되는 핵심적인 과정입니다.

## 주요 실습 내용

* **데이터 품질의 주요 차원:**
    * **완전성 (Completeness):** 필수 데이터가 누락되지 않았는가?
    * **유일성 (Uniqueness):** 중복된 데이터는 없는가?
    * **정확성 (Accuracy):** 데이터가 실제 사실을 정확하게 반영하는가?
    * **일관성 (Consistency):** 서로 다른 시스템 간의 데이터가 일치하는가?
    * **유효성 (Validity):** 데이터가 정해진 형식과 범위에 맞는가? (e.g., 날짜 형식, 값의 범위)
    * **적시성 (Timeliness):** 데이터가 필요한 시점에 사용 가능한가?
* **데이터 프로파일링 (Data Profiling):**
    * 데이터의 통계적 특성(최소/최대값, 평균, 분포 등)을 파악하여 데이터의 상태를 이해하는 과정
* **데이터 품질 규칙 (Data Quality Rules) 정의:**
    * 위에서 정의한 품질 차원에 따라 구체적인 검증 규칙을 수립
* **데이터 정제 (Data Cleansing) 전략:**
    * 품질 규칙을 위반하는 데이터를 어떻게 처리할 것인지(삭제, 수정, 격리 등)에 대한 계획 수립

## 데이터 품질 규칙 정의 예시

우리가 처리할 웹 서버 로그 데이터를 예로 들어 데이터 품질 규칙을 정의해 보겠습니다.

| 데이터 필드       | 품질 차원 | 규칙 설명                                               | 처리 방안                                       |
| ----------------- | --------- | ------------------------------------------------------- | ----------------------------------------------- |
| `timestamp`       | 완전성    | `timestamp` 필드는 절대 비어있을 수 없다. (Not Null)      | 해당 로그 레코드 삭제 또는 별도 격리 후 원인 분석 |
| `timestamp`       | 유효성    | `yyyy-MM-dd HH:mm:ss` 형식을 따라야 한다.               | 형식 변환 시도, 실패 시 오류 로그로 처리          |
| `user_id`         | 유일성    | 특정 세션 내에서 `user_id`는 중복되어서는 안 된다.      | 중복 발생 시 첫 번째 값만 인정하고 나머지는 무시   |
| `ip_address`      | 정확성    | 유효한 IP 주소 형식(IPv4)이어야 한다.                   | 유효하지 않은 형식의 IP는 `invalid`로 마스킹 처리   |
| `http_status_code`| 유효성    | 100 ~ 599 사이의 정수 값이어야 한다.                    | 범위를 벗어나는 값은 `null`로 처리              |
| `bytes_sent`      | 일관성    | `bytes_sent`가 0보다 작은 음수일 수 없다.               | 0으로 변환                                      |

## 데이터 프로파일링 (Spark 활용)

Spark DataFrame의 내장 함수를 사용하여 데이터의 기본적인 프로파일링을 수행할 수 있습니다.

```python
# Spark 세션 생성 및 데이터 로드
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("DataProfiling").getOrCreate()
df = spark.read.format("parquet").load("/path/to/raw/data")

# 전체 스키마 및 데이터 샘플 확인
df.printSchema()
df.show(5)

# 주요 숫자 필드에 대한 통계 요약
df.describe(['bytes_sent', 'response_time']).show()

# 각 컬럼별 null 값 개수 확인
from pyspark.sql.functions import col, sum as _sum

df.select([_sum(col(c).isNull().cast("int")).alias(c) for c in df.columns]).show()

# http_status_code 별 분포 확인
df.groupBy("http_status_code").count().orderBy("count", ascending=False).show()
```

이러한 프로파일링 결과를 바탕으로 위에서 정의한 데이터 품질 규칙을 구체화하고, 데이터 처리 과정에 검증 로직을 추가할 수 있습니다.

## 다음 챕터

다음 장에서는 이번 장에서 정의한 데이터 품질 요구사항과 규칙을 바탕으로, Spark를 사용하여 원본 데이터를 정제하고 비즈니스 요구사항에 맞게 변환하는 구체적인 방법을 실습합니다.
