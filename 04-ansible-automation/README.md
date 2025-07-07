# 4. 서비스 자동화 배포 (Ansible Automation)

* 핵심 내용 : Ansible로 Hadoop/Spark 자동 설치
* 주요 산출물 : Ansible 플레이북, 배포 로그

---


## 개요

이번 장에서는 Terraform으로 프로비저닝한 콘솔 서버에 Ansible을 설치하고, 이를 이용해 s1, s2, s3 서버에 Hadoop, Spark 등 빅데이터 에코시스템을 자동으로 설치하고 구성합니다. Ansible을 통해 반복적인 작업을 자동화하고, 여러 서버의 구성을 일관되게 관리하는 방법을 실습합니다.

### 주요 작업 (console server에서 작업)

1. **콘솔 서버 접속 및 Ansible 설치 확인**
2. **SSH Key 설정 및 서버 간 연결 확인**
3. **Ansible Inventory 파일 설정**
4. **Hadoop/Spark 자동 설치 실행**

## 1. 콘솔 서버 접속 및 Ansible 설치 확인

설치 된 `ansible --version` 명령어로 설치를 확인합니다.


## 2. Ansible Inventory 파일 확인
```
cat ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/ansible-hadoop/hosts 
```



## 3. Hadoop Cluster Install
* 주의 : 하둡파일(https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz)이 ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/에 있어야 작동함.
* aws ec2에서 주의 : s1~s3서버들 private ip사용해야 함.
```
[ ! -f ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/hadoop-3.3.6.tar.gz ] &&      \
wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz \
-O ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/hadoop-3.3.6.tar.gz

ansible-playbook --flush-cache                                                      \
  -u ec2-user -b --become --become-user=root                                        \
  -i ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/ansible-hadoop/hosts               \
     ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/ansible-hadoop/hadoop_install.yml  \
  -e  ansible_python_interpreter=/usr/bin/python3.9
```

## 4. Spark Cluster Install 
* 주의1 : 하둡파일(https://dlcdn.apache.org/spark/spark-3.4.4/spark-3.4.4-bin-hadoop3.tgz)이 ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/에 있어야 작동함.
* 주의2 : docker 전용 스크립트임. hadoop스크립트와 llm활용하여 Debug하시오. 
```
[ ! -f ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/spark-3.4.4-bin-hadoop3.tgz ] && \
wget https://dlcdn.apache.org/spark/spark-3.4.4/spark-3.4.4-bin-hadoop3.tgz      \
-O ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/spark-3.4.4-bin-hadoop3.tgz
ansible-playbook --flush-cache                                                   \
  -u ec2-user -b --become --become-user=root                                     \
  -i ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/ansible-hadoop/hosts            \
     ~/awsHadoop/3.HadoopEco/hadoopInstall/df/i1/ansible-spark/spark_install.yml \
  -e  ansible_python_interpreter=/usr/bin/python3.9
```


### 5. Terraform 상태 파일 관리 및 백업
* 
```
terraform show 
ls 명령으로 terraform.tfstate 생성 확인 
```


## 다음 챕터

다음 장에서는 구축된 빅데이터 클러스터의 아키텍처를 시각적으로 설계하고, 각 컴포넌트의 역할과 데이터 흐름을 정의하는 방법을 실습합니다.


# Admin
## Shutdown All Instance
```
for i in $(seq 3); do ssh -i ~/.ssh/your-key.pem ec2-user@s$i sudo sh -c 'shutdown -h now'; done
```
## Startup all Instance
```
ids=$(aws ec2 describe-instances  --filters "Name=tag-value,Values=s*" --query "Reservations[].Instances[].InstanceId" --output text)
for i in $ids; do     aws ec2 start-instances --instance-ids $i ;done
```

## vm destroy
```
terraform destroy --auto-approve
```
