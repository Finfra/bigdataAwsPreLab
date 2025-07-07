# 11. 시각화 및 모니터링

* 핵심 내용 : Grafana, Prometheus, CloudWatch 연동
* 주요 산출물 : 대시보드, 모니터링 리포트

---


## 개요

이번 장에서는 구축된 빅데이터 파이프라인과 클러스터의 상태를 효과적으로 모니터링하고, 처리된 데이터를 시각화하여 인사이트를 얻기 위한 시스템을 구축합니다. 오픈소스 모니터링 도구인 Prometheus와 Grafana를 사용하여 시스템 메트릭(CPU, Memory, Disk 등)과 서비스 메트릭(Hadoop, Spark, Kafka)을 수집하고 대시보드를 통해 시각화하는 방법을 학습합니다.

## 주요 작업

1. **Prometheus 및 Grafana 설치:**
    * 콘솔 서버 또는 별도의 모니터링 서버에 Prometheus와 Grafana 설치
2. **Exporter 설정:**
    * 각 서버(s1, s2, s3)의 시스템 메트릭을 수집하기 위해 `node_exporter` 설치 및 실행
    * Hadoop, Spark, Kafka의 JMX 메트릭을 수집하기 위해 `jmx_exporter` 설정
3. **Prometheus 설정:**
    * `prometheus.yml` 파일에 Exporter들의 주소를 등록하여 메트릭을 수집(Scrape)하도록 설정
4. **Grafana 대시보드 구성:**
    * Grafana에 Prometheus를 데이터 소스로 추가
    * 시스템 리소스, Hadoop 클러스터 상태, Kafka 토픽 현황 등을 모니터링하기 위한 대시보드 생성 또는 Import

## 모니터링 아키텍처

```
+----------------------------------------------------------------------------------------------------+
|                                         Monitoring Server (or Console Server)                        |
|                                                                                                    |
|  +-------------------------+      +--------------------------+      +-----------------------------+  |
|  |        Prometheus       |<-----|   Prometheus Targets     |<-----|      Cluster Nodes (s1,s2,s3) |  |
|  | (Metrics Scraper & TSDB)|      | (prometheus.yml)         |      |                               |  |
|  +-----------+-------------+      +--------------------------+      |  +--------------------------+ |  |
|              |                                                      |  |      node_exporter       | |  |
|              v                                                      |  | (System Metrics)         | |  |
|  +-------------------------+                                        |  +--------------------------+ |  |
|  |         Grafana         |                                        |                               |  |
|  | (Visualization Dashboard)|                                        |  +--------------------------+ |  |
|  +-------------------------+                                        |  |      jmx_exporter        | |  |
|                                                                     |  | (Hadoop, Spark, Kafka)   | |  |
|                                                                     |  +--------------------------+ |  |
|                                                                     +-----------------------------+  |
+----------------------------------------------------------------------------------------------------+
```

## 1. Prometheus & Grafana 설치 (Docker Compose 예시)

콘솔 서버에 Docker와 Docker Compose를 설치하면 Prometheus와 Grafana를 간편하게 실행할 수 있습니다.

### `docker-compose.yml`

```yaml
version: '3'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command: --config.file=/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
```

## 2. Exporter 설정

* **`node_exporter`:** 각 서버(s1, s2, s3)에 접속하여 `node_exporter`를 다운로드하고 실행합니다. (Ansible로 자동화 가능)
* **`jmx_exporter`:** Hadoop, Spark 등의 Java 기반 애플리케이션의 JVM 및 서비스 메트릭을 수집합니다. 각 서비스의 시작 스크립트에 `javaagent` 옵션으로 `jmx_exporter.jar`의 경로와 설정 파일(YAML)을 지정해 주어야 합니다.

## 3. Prometheus 설정 (`prometheus.yml`)

Prometheus가 메트릭을 수집할 대상(Target)을 정의합니다.

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['s1_private_ip:9100', 's2_private_ip:9100', 's3_private_ip:9100']

  - job_name: 'hadoop_namenode'
    static_configs:
      - targets: ['s1_private_ip:9870'] # JMX Exporter 포트

  # ... 기타 Hadoop, Spark, Kafka JMX Exporter 타겟 설정
```

## 4. Grafana 대시보드 구성

1. **SSH 터널링**으로 Grafana(`http://localhost:3000`)에 접속합니다. (초기 ID/PW: admin/admin)
2. **Configuration > Data Sources**에서 Prometheus를 추가합니다. URL은 `http://prometheus:9090`으로 설정합니다.
3. **Dashboards > Import**에서 `node_exporter`나 Hadoop, Kafka를 위한 공개된 대시보드 ID를 입력하여 손쉽게 대시보드를 추가할 수 있습니다.
    * 예: Node Exporter Full 대시보드 ID: `1860`
4. PromQL(Prometheus Query Language)을 사용하여 직접 패널을 만들고 커스텀 대시보드를 구성할 수도 있습니다.

## 다음 과정

다음 장에서는 클라우드 환경에서 운영 비용을 최적화하는 전략과, 인프라 및 데이터 보안을 강화하기 위한 기본적인 방법에 대해 학습합니다.
