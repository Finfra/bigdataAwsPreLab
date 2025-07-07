# This directory contains examples for leveraging advanced AWS analytics services.

# Example: glue_etl_script.py (PySpark Glue ETL script)
# import sys
# from awsglue.transforms import *
# from awsglue.utils import getResolvedOptions
# from pyspark.context import SparkContext
# from awsglue.context import GlueContext
# from awsglue.job import Job

# args = getResolvedOptions(sys.argv, ['JOB_NAME'])
# sc = SparkContext()
# glueContext = GlueContext(sc)
# spark = glueContext.spark_session
# job = Job(glueContext)
# job.init(args['JOB_NAME'], args)

# # Read data from S3
# datasource0 = glueContext.create_dynamic_frame.from_options(
#     format_options={
#         "jsonPaths": [
#             "$.time",
#             "$.DeviceId",
#             "$.sensor1",
#             "$.sensor2",
#             "$.sensor3",
#             "$.motor1",
#             "$.motor2",
#             "$.motor3",
#             "$.isFail"
#         ]
#     },
#     connection_type="s3",
#     format="json",
#     connection_options={
#         "paths": ["s3://your-raw-data-bucket/"],
#         "recurse": True
#     },
#     transformation_ctx="datasource0"
# )

# # Apply transformations (example: convert timestamp, add partition keys)
# applymapping1 = ApplyMapping.apply(frame=datasource0, mappings=[
#     ("time", "string", "event_timestamp", "timestamp"),
#     ("DeviceId", "long", "device_id", "long"),
#     ("sensor1", "double", "sensor1", "double"),
#     ("isFail", "boolean", "is_fail", "boolean")
# ], transformation_ctx="applymapping1")

# # Write transformed data to S3 in Parquet format, partitioned
# datasink1 = glueContext.write_dynamic_frame.from_options(
#     frame=applymapping1,
#     connection_type="s3",
#     format="parquet",
#     connection_options={
#         "path": "s3://your-processed-data-bucket/",
#         "partitionKeys": ["device_id"]
#     },
#     transformation_ctx="datasink1"
# )

# job.commit()
