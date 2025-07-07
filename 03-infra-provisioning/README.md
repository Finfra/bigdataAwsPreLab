#  인프라 자동화(IaC)

* 핵심 내용 : Terraform으로 EC2, VPC, SG, S3 등 자동 생성
* 주요 산출물 : Terraform 코드, 인프라 다이어그램

---


## 개요

이번 장에서는 IaC(Infrastructure as Code) 도구인 Terraform을 사용하여 AWS에 필요한 인프라를 자동으로 프로비저닝합니다. Terraform을 통해 콘솔 서버(Control Server)와 빅데이터 클러스터를 구성할 서버(s1, s2, s3)를 생성하고, 이들 간의 네트워크 통신을 설정합니다.


## 1. 콘솔 인스턴스 프로비저닝
* https://ap-northeast-2.console.aws.amazon.com/ec2/home?region=ap-northeast-2#LaunchInstances:
* Region        : ap-northeast-2(서울) 인지 확인만.
* Name          : i1
* AMI           :  ami-0a463f27534bdf246 Amazon Linux 2023 
* Ssecurity groups : Create security group ( Allow security group)
* Instance Type : t2-micro
* Key Pair      : key1 생성, pem확장자로 다운로드
* Storage(EBS)  : 40G

* 접속 : linux에서는 아래와 같고 windows에서는 putty로 접속 단, user는 ec2-user임.(ubuntu아님에 주의)
```
ssh -i key1.pem ec2-user@{아이피}
```
* 접속 후 기본 셋팅
```
sudo -i
hostname i자기번호
echo $(hostname) > /etc/hostname
dnf install -y git 
exit
```

## Ansible, Terraform설치
```
# cd
# git clone  https://github.com/Finfra/awsHadoop.git
cd awsHadoop/03-infra-provisioning
bash installOnEc2_awsLinux.sh
```

## 2. 테라폼 셋팅
* 아래와 같은 내용을 ~/.bashrc에 추가하고 실행해 줍니다.
```
echo '
export TF_VAR_AWS_ACCESS_KEY="xxxxxxxxxx"
export TF_VAR_AWS_SECRET_KEY="xxxxxxxxxxxxxxxxxxx"
export TF_VAR_AWS_REGION="ap-northeast-2"
'>> ~/.bashrc
. ~/.bashrc
```

## 2. OS key 생성 [있으면 생략]
```
ssh-keygen -f ~/.ssh/id_rsa -N ''
```
* cf) 설치 대상 host에 Public-key 배포
    ssh-copy-id root@10.0.2.10

## 3. Terrform 으로 host 셋팅
* Terraform으로 i1에서 s1,s2 s3 인스턴트 생성 : os는  Amazon Linux 2023 임.
```
# pwd
# → /home/ec2-user/awsHadoop/3.HadoopEco

terraform init
terraform apply -var "user_num=$(hostname | sed 's/^i//')" -auto-approve
```
## 4. Hosts파일 셋팅
```
aws configure
  # security setting
    AWS Access Key ID [None]: xxxxxxxxxx
    AWS Secret Access Key [None]: xxxxxxxxxxxxxxxxxxx
    Default region name [None]: ap-northeast-2
    Default output format [None]: text
cd awsHadoop/5.Terraform/
# rm -rf ~/.ssh/known_hosts
bash doSetHosts.sh
```

* cf) 아래와 같이 /etc/hosts파일을 직접 셋팅 해도 됨
```
52.213.183.141 vm01
54.75.118.15   vm02
54.75.118.154  vm03
```
# 부록: Terraform 기반 인프라 자동화 예시 및 개념

## 개요

이 부록에서는 IaC(Infrastructure as Code) 도구인 Terraform을 사용하여 AWS에 필요한 인프라를 자동으로 프로비저닝하는 방법을 설명합니다. Terraform을 통해 콘솔 서버(Control Server)와 빅데이터 클러스터를 구성할 서버(s1, s2, s3)를 생성하고, 이들 간의 네트워크 통신을 실습할 수 있습니다.

## 주요 작업

1. **Terraform 설치**
2. **Terraform 코드 작성:**
    * Provider 및 Backend 설정
    * VPC, Subnet, Internet Gateway, Route Table 등 네트워크 리소스 정의
    * Security Group 설정 (SSH 및 서버 간 통신 허용)
    * Oracle Linux 기반의 EC2 인스턴스(콘솔 서버, s1, s2, s3) 생성
    * EIP (Elastic IP)를 콘솔 서버에 할당
3. **Terraform 실행:**
    * `terraform init`
    * `terraform plan`
    * `terraform apply`

## Terraform 코드 예시

### `main.tf` (예시)

```terraform
# AWS Provider 설정
provider "aws" {
  region = var.aws_region
}

# VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prelab-vpc"
  }
}

# Subnet, Internet Gateway, Route Table 등 네트워크 리소스...

# Security Group (SSH 허용)
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 편의상 모든 IP를 허용 (실제 환경에서는 특정 IP만 허용)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Oracle Linux AMI 조회
data "aws_ami" "oracle_linux" {
  most_recent = true
  owners      = ["oracle"]

  filter {
    name   = "name"
    values = ["Oracle-Linux-9-*-x86_64-*"]
  }
}

# 콘솔 서버 EC2 인스턴스 생성
resource "aws_instance" "console_server" {
  ami           = data.aws_ami.oracle_linux.id
  instance_type = "t2.micro"
  # ... 기타 설정 (Key Pair, Subnet 등)
  tags = {
    Name = "console-server"
  }
}

# s1, s2, s3 서버 생성 (count 사용)
resource "aws_instance" "data_nodes" {
  count         = 3
  ami           = data.aws_ami.oracle_linux.id
  instance_type = "t2.medium"
  # ... 기타 설정
  tags = {
    Name = "s${count.index + 1}"
  }
}

# EIP 할당
resource "aws_eip" "console_eip" {
  instance = aws_instance.console_server.id
  vpc      = true
}
```

### `variables.tf`

```terraform
variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "ap-northeast-2"
}

# ... 기타 필요한 변수 선언
```

### `outputs.tf`

```terraform
output "console_server_public_ip" {
  value = aws_eip.console_eip.public_ip
}

output "data_node_private_ips" {
  value = aws_instance.data_nodes[*].private_ip
}
```

## 참고

- Terraform 공식 홈페이지: [https://www.terraform.io/downloads.html](https://www.terraform.io/downloads.html)
