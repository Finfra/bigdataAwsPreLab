# 6. Hadoop/Spark 클러스터 구축

* 핵심 내용 : EC2 기반 분산 스토리지(저장소는 AWS S3 지정)/컴퓨팅 환경 구축
* 주요 산출물 : 클러스터 구축 스크립트, 모니터링

---


## 개요

이번 장에서는 Ansible Playbook을 구체화하여 s1, s2, s3 서버에 Hadoop과 Spark 클러스터를 완전하게 구축합니다. NameNode, DataNode, ResourceManager, NodeManager 등 각 데몬의 역할을 서버에 맞게 할당하고, 클러스터가 정상적으로 동작하는지 확인하는 과정을 실습합니다.

## 주요 작업

1. **Hadoop 클러스터 구성:**
    * `core-site.xml`, `hdfs-site.xml`, `mapred-site.xml`, `yarn-site.xml` 설정
    * NameNode(s1)와 DataNode(s2, s3) 역할 분리
    * HDFS 포맷 및 클러스터 실행
2. **Spark 클러스터 구성:**
    * `spark-env.sh`, `spark-defaults.conf` 설정
    * Spark Standalone 클러스터 또는 YARN 위에서 동작하도록 구성
    * Spark Master(s1)와 Worker(s2, s3) 설정
3. **클러스터 동작 확인:**
    * HDFS 및 YARN 웹 UI 접속
    * Spark 예제 애플리케이션 실행 (e.g., SparkPi)

## 1. Hadoop 클러스터 구성 (Ansible Playbook 상세)

`04-ansible-automation`에서 작성했던 Playbook을 더 구체화합니다. Ansible의 `template` 모듈을 사용하여 서버별로 다른 설정 파일을 동적으로 생성하고 배포합니다.

### 디렉토리 구조 예시

```
playbooks/
├── install_hadoop_spark.yml
├── templates/
│   ├── core-site.xml.j2
│   ├── hdfs-site.xml.j2
│   ├── mapred-site.xml.j2
│   └── yarn-site.xml.j2
└── vars/
    └── cluster_vars.yml
```

### `templates/core-site.xml.j2`

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://s1:9000</value>
    </property>
</configuration>
```

### `templates/hdfs-site.xml.j2`

```xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>2</value> <!-- DataNode가 2개이므로 -->
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///data/hadoop/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///data/hadoop/hdfs/datanode</value>
    </property>
</configuration>
```

### Playbook 수정 (`install_hadoop_spark.yml`)

```yaml
    # ... 이전 tasks ...

    - name: Create HDFS data directories
      file:
        path: "{{ item }}"
        state: directory
        owner: hadoop_user # hadoop을 실행할 사용자
        group: hadoop_user
      with_items:
        - /data/hadoop/hdfs/namenode
        - /data/hadoop/hdfs/datanode

    - name: Distribute Hadoop configuration files
      template:
        src: "templates/{{ item }}.j2"
        dest: "/usr/local/hadoop/etc/hadoop/{{ item }}"
      with_items:
        - core-site.xml
        - hdfs-site.xml
        - mapred-site.xml
        - yarn-site.xml

    # ... 이후 tasks ...
```

### HDFS 포맷 및 실행

Ansible Playbook 실행이 완료된 후, **s1 서버**에 접속하여 HDFS를 포맷하고 클러스터를 시작합니다.

```bash
# s1 서버에서 실행
/usr/local/hadoop/bin/hdfs namenode -format
/usr/local/hadoop/sbin/start-dfs.sh
/usr/local/hadoop/sbin/start-yarn.sh
```

## 2. Spark 클러스터 구성

Spark를 YARN 위에서 동작하도록 구성하는 것이 일반적입니다. `spark-env.sh`에 `HADOOP_CONF_DIR`을 설정하여 Hadoop 클러스터 정보를 참조하도록 합니다.

### `spark-env.sh` 설정

```bash
# /usr/local/spark/conf/spark-env.sh

export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
```

Ansible Playbook에 이 설정을 추가하는 Task를 구현합니다.

## 3. 클러스터 동작 확인

* **웹 UI 접속:**
    * 로컬 머신에서 콘솔 서버로 SSH 터널링을 설정하여 각 서비스의 웹 UI에 접속합니다.
    ```bash
    # 로컬 터미널에서 실행
    # NameNode UI (s1:9870)
    ssh -i your-key.pem -L 9870:s1_private_ip:9870 ec2-user@console_server_public_ip

    # ResourceManager UI (s1:8088)
    ssh -i your-key.pem -L 8088:s1_private_ip:8088 ec2-user@console_server_public_ip
    ```
    * 웹 브라우저에서 `http://localhost:9870` 또는 `http://localhost:8088`로 접속하여 대시보드를 확인합니다.

* **Spark 예제 실행:**
    * **s1 서버**에서 다음 명령어를 실행하여 Spark Pi 예제를 YARN 클러스터 모드로 제출합니다.
    ```bash
    /usr/local/spark/bin/spark-submit \
      --class org.apache.spark.examples.SparkPi \
      --master yarn \
      --deploy-mode cluster \
      /usr/local/spark/examples/jars/spark-examples_*.jar \
      10
    ```
    * YARN 웹 UI의 애플리케이션 목록에서 작업이 성공적으로 완료되었는지 확인합니다.

## 다음 챕터

다음 장에서는 실시간 데이터 스트리밍을 처리하기 위해 Kafka를 설치하고, Spark Streaming과 연동하여 간단한 스트리밍 파이프라인을 구축하는 방법을 실습합니다.
