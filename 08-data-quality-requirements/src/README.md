# This directory contains examples or definitions for data quality rules.

# Example: data_quality_rules.py (Python script for data validation)
# from pyspark.sql import SparkSession
# from pyspark.sql.functions import col

# def validate_timestamp(df):
#     return df.filter(col("timestamp").isNotNull())

# def validate_http_status_code(df):
#     return df.filter((col("http_status_code") >= 100) & (col("http_status_code") < 600))

# if __name__ == "__main__":
#     spark = SparkSession.builder.appName("DataQualityValidation").getOrCreate()
#     # Load your data
#     df = spark.read.parquet("/path/to/your/data")

#     # Apply validation rules
#     validated_df = validate_timestamp(df)
#     validated_df = validate_http_status_code(validated_df)

#     validated_df.show()
#     spark.stop()

# Example: data_quality_rules.md (Markdown for rule definitions)
# ## Data Quality Rules for FMS Sensor Data
#
# | Field       | Rule Type   | Description                                   | Action on Violation       |
# |-------------|-------------|-----------------------------------------------|---------------------------|
# | `timestamp` | Completeness| Must not be null.                             | Drop record               |
# | `DeviceId`  | Validity    | Must be an integer between 1 and 100.         | Flag and log              |
# | `sensor1`   | Range       | Must be between 0 and 200.                    | Nullify value             |
