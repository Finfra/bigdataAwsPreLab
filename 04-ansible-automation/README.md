# 4. 서비스 자동화 배포 (Ansible Automation)

* 핵심 내용 : Ansible로 Hadoop/Spark/Kafka 자동 설치
* 주요 산출물 : Ansible 플레이북, 배포 로그

---


## 개요

이번 장에서는 Terraform으로 프로비저닝한 콘솔 서버에 Ansible을 설치하고, 이를 이용해 s1, s2, s3 서버에 Hadoop, Spark 등 빅데이터 에코시스템을 자동으로 설치하고 구성합니다. Ansible을 통해 반복적인 작업을 자동화하고, 여러 서버의 구성을 일관되게 관리하는 방법을 학습합니다.

## 주요 작업

1. **콘솔 서버 접속 및 Ansible 설치**
2. **Ansible Inventory 파일 작성**
3. **Ansible Playbook 작성:**
    * 공통 설정 (사용자 생성, 패키지 설치 등)
    * Hadoop 설치 및 구성
    * Spark 설치 및 구성
4. **Ansible Playbook 실행**

## 1. 콘솔 서버 접속 및 Ansible 설치

이전 장에서 `terraform apply` 실행 후 출력된 `console_server_public_ip`를 사용하여 콘솔 서버에 SSH로 접속합니다. Oracle Linux의 기본 사용자는 `ec2-user`이며, Terraform에서 지정한 Key Pair를 사용해야 합니다.

```bash
ssh -i /path/to/your-key.pem ec2-user@<CONSOLE_SERVER_PUBLIC_IP>
```

콘솔 서버에 접속한 후, Ansible을 설치합니다.

```bash
# Oracle Linux 8, 9 기준
sudo dnf install -y oracle-epel-release-el9
sudo dnf install -y ansible-core
```

설치 후 `ansible --version` 명령어로 설치를 확인합니다.

## 2. Ansible Inventory 파일 작성

Ansible이 관리할 서버 목록을 정의하는 Inventory 파일을 작성합니다. `~/inventory.ini` 파일을 생성하고 다음과 같이 s1, s2, s3 서버의 Private IP를 등록합니다. (Private IP는 `terraform output` 명령어로 다시 확인할 수 있습니다.)

```ini
# ~/inventory.ini

[hadoop_cluster]
s1 ansible_host=10.0.1.11
s2 ansible_host=10.0.1.12
s3 ansible_host=10.0.1.13

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=/home/ec2-user/.ssh/your-key.pem
ansible_python_interpreter=/usr/bin/python3
```

**중요:** 로컬에 있는 EC2 Key Pair(`your-key.pem`)를 콘솔 서버의 `~/.ssh/` 디렉토리로 미리 복사해두어야 합니다. `scp` 명령어를 사용하거나, `ssh-agent`를 활용할 수 있습니다.

`ansible -i ~/inventory.ini all -m ping` 명령어로 모든 서버에 정상적으로 접속되는지 확인합니다.

## 3. Ansible Playbook 작성

`~/playbooks` 디렉토리를 생성하고, 그 안에 Hadoop과 Spark를 설치하기 위한 Playbook을 작성합니다. Playbook은 YAML 형식으로 작성되며, 서버에서 실행할 작업(Task)들을 순서대로 정의합니다.

### `~/playbooks/install_hadoop_spark.yml` (예시)

```yaml
---
- name: Install Hadoop and Spark Cluster
  hosts: hadoop_cluster
  become: yes
  tasks:
    - name: Update all packages
      dnf:
        name: '*'
        state: latest

    - name: Install Java
      dnf:
        name: java-1.8.0-openjdk-devel
        state: present

    # --- Hadoop 설치 및 설정 Tasks ---
    - name: Download and unarchive Hadoop
      unarchive:
        src: https://archive.apache.org/dist/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz
        dest: /usr/local/
        remote_src: yes
        creates: /usr/local/hadoop-3.3.1

    - name: Create symlink for Hadoop
      file:
        src: /usr/local/hadoop-3.3.1
        dest: /usr/local/hadoop
        state: link

    # ... (Hadoop 환경변수 설정, core-site.xml, hdfs-site.xml 등 구성 파일 템플릿 복사)

    # --- Spark 설치 및 설정 Tasks ---
    - name: Download and unarchive Spark
      unarchive:
        src: https://archive.apache.org/dist/spark/spark-3.2.1/spark-3.2.1-bin-hadoop3.2.tgz
        dest: /usr/local/
        remote_src: yes
        creates: /usr/local/spark-3.2.1-bin-hadoop3.2

    - name: Create symlink for Spark
      file:
        src: /usr/local/spark-3.2.1-bin-hadoop3.2
        dest: /usr/local/spark
        state: link

    # ... (Spark 환경변수 설정, spark-defaults.conf 등 구성 파일 템플릿 복사)
```

## # 4. 서비스 자동화 배포

Playbook 작성이 완료되면, 다음 명령어를 실행하여 `hadoop_cluster` 그룹에 속한 모든 서버에 Hadoop과 Spark 설치를 진행합니다.

```bash
ansible-playbook -i ~/inventory.ini ~/playbooks/install_hadoop_spark.yml
```

Playbook 실행이 완료되면 각 서버에 접속하여 Hadoop과 Spark가 정상적으로 설치되었는지 확인합니다.

## 다음 과정

다음 장에서는 구축된 빅데이터 클러스터의 아키텍처를 시각적으로 설계하고, 각 컴포넌트의 역할과 데이터 흐름을 정의하는 방법을 학습합니다.
