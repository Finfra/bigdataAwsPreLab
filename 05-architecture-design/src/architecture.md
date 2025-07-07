# FMS BigData AWS Pre-Lab Architecture Design

## 1. Overview

This document outlines the architecture for the FMS BigData AWS Pre-Lab, focusing on building a real-time data processing pipeline on AWS EC2 instances using open-source technologies like Hadoop, Spark, and Kafka, managed by Terraform and Ansible.

## 2. High-Level Architecture Diagram

```mermaid
graph TD
    A[FMS API] --> B(Python Collector)
    B --> C[Kafka Cluster (s1, s2, s3)]
    C --> D[Spark Streaming Application]
    D --> E[HDFS on EC2 (s1, s2, s3)]
    E --> F[Grafana/Prometheus Monitoring]
    subgraph AWS Cloud
        subgraph VPC
            subgraph Public Subnet
                G[Console Server (i1)]
            end
            subgraph Private Subnet
                C
                D
                E
            end
        end
    end
    G -- Manages --> C
    G -- Manages --> D
    G -- Manages --> E
    G -- Monitors --> F

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#bbf,stroke:#333,stroke-width:2px
    style D fill:#bbf,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
    style F fill:#bbf,stroke:#333,stroke-width:2px
    style G fill:#bbf,stroke:#333,stroke-width:2px

```

## 3. Component Breakdown

### 3.1. Data Ingestion
*   **FMS API**: Source of sensor data from 100 devices.
*   **Python Collector**: Custom Python script to pull data from FMS API and push to Kafka.

### 3.2. Messaging & Streaming
*   **Apache Kafka Cluster**: Deployed on EC2 instances (s1, s2, s3) for reliable, high-throughput data ingestion and buffering.
*   **Apache Spark Streaming**: Processes real-time data streams from Kafka, performs transformations, and quality checks.

### 3.3. Storage
*   **HDFS on EC2**: Distributed file system for storing raw and processed data. Configured to use AWS S3 as the underlying storage for durability and scalability.

### 3.4. Management & Automation
*   **Console Server (i1)**: A dedicated EC2 instance acting as a bastion host and control node.
    *   **Terraform**: Used for Infrastructure as Code (IaC) to provision all AWS resources (VPC, EC2 instances, Security Groups, etc.).
    *   **Ansible**: Used for configuration management and software deployment (Hadoop, Spark, Kafka, Prometheus, Grafana) on the EC2 instances.

### 3.5. Monitoring & Visualization
*   **Prometheus**: Collects metrics from EC2 instances (via `node_exporter`) and big data services (via `jmx_exporter`).
*   **Grafana**: Visualizes the collected metrics through dashboards, providing real-time insights into system health and data pipeline performance.

## 4. Data Flow

1.  **FMS API** generates sensor data every 10 seconds.
2.  **Python Collector** pulls data from FMS API.
3.  Collector pushes data to **Kafka Topic**.
4.  **Spark Streaming Application** consumes data from Kafka.
5.  Spark performs real-time data transformation and quality validation.
6.  Processed data is stored in **HDFS on EC2** (which leverages AWS S3).
7.  **Prometheus** scrapes metrics from all EC2 instances and big data services.
8.  **Grafana** visualizes these metrics, providing operational insights.

## 5. EC2 Node Roles and Ports

| Node               | Role & Services                                               | Key Ports                                                                                     |
| ------------------ | ------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| i1 (Console Server)| Terraform, Ansible Control Node, Bastion Host                 | SSH(22)                                                                                       |
| s1 (Master Node)   | HDFS NameNode, YARN ResourceManager, Spark Master, Kafka Broker, Prometheus | SSH(22), NameNode UI(9870), ResourceManager UI(8088), Spark Master UI(8080), Kafka(9092), Prometheus(9090) |
| s2, s3 (Worker Node)| HDFS DataNode, YARN NodeManager, Spark Worker, Kafka Broker, Node Exporter | SSH(22), DataNode UI(9864), NodeManager UI(8042), Spark Worker UI(8081), Kafka(9092), Node Exporter(9100) |

## 6. Security Considerations

*   **VPC Design**: Public Subnet for Console Server, Private Subnet for Hadoop/Spark/Kafka cluster (for enhanced security, though currently all in public for simplicity).
*   **Security Groups**: Strictly control inbound/outbound traffic for each instance.
*   **IAM Roles**: Assign least privilege IAM roles to EC2 instances.
*   **SSH Key Management**: Securely manage SSH key pairs.

## 7. Cost Optimization Considerations

*   **Instance Sizing**: Choose appropriate EC2 instance types (e.g., `t2.medium` for data nodes).
*   **S3 for HDFS**: Leverage S3's cost-effectiveness for long-term data storage.
*   **Monitoring**: Use Grafana/Prometheus to identify underutilized resources.

