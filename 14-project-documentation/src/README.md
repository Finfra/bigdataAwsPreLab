# This directory contains example documentation files for the project.

# Example: aws_architecture_document.md
# # AWS BigData Pre-Lab Architecture Document
#
# ## 1. Introduction
# This document details the architecture of the FMS BigData pipeline deployed on AWS.
#
# ## 2. High-Level Architecture
# (Diagram or description of the overall system)
#
# ## 3. Component Details
# ### 3.1. Data Ingestion
# *   **FMS API**: Source of data.
# *   **Python Collector**: Custom script for data collection.
# *   **Kafka Cluster**: Messaging queue for real-time data.
#
# ### 3.2. Data Processing
# *   **Spark Streaming**: Real-time data transformation.
# *   **Spark Batch**: Daily aggregations.
#
# ### 3.3. Data Storage
# *   **HDFS on EC2**: Primary storage for raw and processed data.
# *   **AWS S3**: Used as underlying storage for HDFS, and for long-term archives.
#
# ## 4. Network Design
# (VPC, Subnets, Security Groups, NACLs)
#
# ## 5. Security Considerations
# (IAM roles, encryption, access control)
#
# ## 6. Cost Optimization
# (Instance types, S3 storage classes, etc.)

# Example: aws_troubleshooting_guide.md
# # AWS BigData Pre-Lab Troubleshooting Guide
#
# ## 1. Common Issues
# ### 1.1. EC2 Instance Connectivity
# *   **Problem**: Cannot SSH to EC2 instance.
# *   **Solution**: Check Security Group rules (port 22), Network ACLs, Key Pair permissions.
#
# ### 1.2. Hadoop Service Startup Failure
# *   **Problem**: NameNode or DataNode fails to start.
# *   **Solution**: Check logs (`/opt/hadoop/logs`), ensure HDFS is formatted, verify configuration files (`core-site.xml`, `hdfs-site.xml`).
#
# ## 2. Performance Issues
# ### 2.1. Slow Spark Jobs
# *   **Problem**: Spark jobs are taking too long.
# *   **Solution**: Increase executor memory/cores, optimize Spark configurations, check data skew.
#
# ## 3. Cost Overruns
# ### 3.1. Unexpected AWS Charges
# *   **Problem**: AWS bill is higher than expected.
# *   **Solution**: Review Cost Explorer, check for unstopped instances, unattached EBS volumes, or excessive data transfer.
