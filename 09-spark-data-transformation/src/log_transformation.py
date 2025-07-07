# This directory contains example Spark data transformation scripts.

# Example: log_transformation.py (PySpark script)
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, to_timestamp, udf, split
from pyspark.sql.types import StringType

def get_domain(url):
    """UDF to extract domain from URL"""
    try:
        return url.split('/')[2]
    except IndexError:
        return None

if __name__ == "__main__":
    spark = SparkSession \
        .builder \
        .appName("LogTransformation") \
        .getOrCreate()

    # Load raw data (assuming text format, e.g., from Kafka or HDFS)
    raw_df = spark.read.text("/path/to/raw/logs")

    # Parse the raw log lines (example for CSV-like logs)
    parsed_df = raw_df.select(
        split(col("value"), ",")[0].alias("timestamp_str"),
        split(col("value"), ",")[1].alias("user_id"),
        split(col("value"), ",")[2].alias("request_url"),
        split(col("value"), ",")[3].cast("int").alias("http_status_code")
    )

    # Data Cleansing: Filter out records with null user_id
    cleansed_df = parsed_df.filter(col("user_id").isNotNull())

    # Data Transformation: Convert timestamp string to timestamp type
    cleansed_df = cleansed_df.withColumn(
        "event_timestamp",
        to_timestamp(col("timestamp_str"), "yyyy-MM-dd HH:mm:ss")
    )

    # Register UDF and create derived column 'domain'
    get_domain_udf = udf(get_domain, StringType())
    transformed_df = cleansed_df.withColumn(
        "domain",
        get_domain_udf(col("request_url"))
    )

    # Select final columns
    final_df = transformed_df.select(
        "event_timestamp", "user_id", "domain", "http_status_code"
    )

    # Write processed data to HDFS in Parquet format, partitioned by domain
    final_df.write \
        .mode("overwrite") \
        .partitionBy("domain") \
        .parquet("/path/to/processed/logs")

    spark.stop()
