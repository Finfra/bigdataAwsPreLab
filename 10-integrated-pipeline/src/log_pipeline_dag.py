# This directory contains example Airflow DAGs for integrating the data pipeline.

# Example: log_pipeline_dag.py
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
    schedule_interval=timedelta(days=1), # Run daily
    catchup=False,
)

# Task to run the Spark transformation job
spark_transform_task = SparkSubmitOperator(
    task_id='spark_log_transformation',
    application='/path/to/your/log_transformation.py', # Path to the Spark script from 09-spark-data-transformation
    conn_id='spark_default', # Airflow connection ID for Spark
    conf={
        "spark.yarn.queue": "default",
        "spark.executor.memory": "2g",
        "spark.driver.memory": "1g"
    },
    dag=dag,
)

# Define task dependencies (if any, for now just one task)
# spark_transform_task
