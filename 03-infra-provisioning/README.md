# 3. 인프라 자동화(IaC)

* 핵심 내용 : Terraform으로 EC2, VPC, SG, S3 등 자동 생성
* 주요 산출물 : Terraform 코드, 인프라 다이어그램

---


## 개요

이번 장에서는 IaC(Infrastructure as Code) 도구인 Terraform을 사용하여 AWS에 필요한 인프라를 자동으로 프로비저닝합니다. Terraform을 통해 콘솔 서버(Control Server)와 빅데이터 클러스터를 구성할 서버(s1, s2, s3)를 생성하고, 이들 간의 네트워크 통신을 설정합니다.

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

## 1. Terraform 설치

먼저 로컬 환경에 Terraform을 설치합니다. 아래 공식 홈페이지에서 본인의 OS에 맞는 바이너리를 다운로드하고 PATH에 추가합니다.

* **Terraform 다운로드:** [https://www.terraform.io/downloads.html](https://www.terraform.io/downloads.html)

설치 후 `terraform version` 명령어로 설치를 확인합니다.

## 2. Terraform 코드 작성

`03-infra-provisioning/src` 디렉토리 아래에 다음과 같은 구조로 Terraform 코드를 작성합니다.

```
src/
├── main.tf       # 주 설정 파일 (리소스 정의)
├── variables.tf  # 변수 선언
├── outputs.tf    # 결과 값 출력
└── terraform.tfvars # 변수 값 할당 (Git에 포함하지 않도록 주의)
```

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

## 3. Terraform 실행

Terraform 코드 작성이 완료되면, `src` 디렉토리에서 다음 명령어를 순서대로 실행하여 인프라를 생성합니다.

1. **`terraform init`**: Terraform 백엔드와 프로바이더 플러그인을 초기화합니다.
2. **`terraform plan`**: 생성될 리소스의 실행 계획을 미리 확인합니다.
3. **`terraform apply`**: 실행 계획에 따라 AWS에 리소스를 실제로 생성합니다. (중간에 `yes`를 입력해야 합니다.)

`apply`가 완료되면 `outputs.tf`에 정의한 콘솔 서버의 Public IP와 데이터 노드들의 Private IP가 출력됩니다. 이 정보는 다음 장에서 Ansible을 설정할 때 사용됩니다.

## 다음 과정

다음 장에서는 프로비저닝된 콘솔 서버에 접속하여 Ansible을 설치하고, 생성된 s1, s2, s3 서버에 Hadoop과 Spark를 자동으로 설치 및 구성하는 방법을 학습합니다.
