# 2. AWS 계정 및 권한 준비

* 핵심 내용 : IAM, 키페어, S3 버킷, VPC 기본 설정
* 주요 산출물 : 계정/권한 체크리스트, S3 버킷

---


## 개요

이번 장에서는 AWS 클라우드 환경에서 실습을 진행하기 위해 필요한 초기 계정 설정 및 보안 구성을 진행합니다. AWS Free Tier를 활용하여 비용 부담을 최소화하면서 실습을 진행할 수 있도록 안내합니다.

## 주요 작업

1. **AWS 계정 생성 (신규 사용자의 경우)**
2. **IAM (Identity and Access Management) 사용자 생성**
3. **프로그래밍 방식 액세스를 위한 Access Key 발급**
4. **AWS CLI (Command Line Interface) 설치 및 구성**

## 1. AWS 계정 생성

AWS 계정이 없는 경우, 아래 공식 가이드를 따라 계정을 생성합니다. 가입 시 해외 결제가 가능한 신용카드 또는 체크카드가 필요하며, Free Tier 사용량을 초과하지 않는 한 비용이 청구되지 않습니다.

* **공식 가이드:** [새 AWS 계정 생성 및 활성화](https://docs.aws.amazon.com/ko_kr/accounts/latest/reference/create-account.html)

## 2. Terraform 실습용 IAM 사용자 생성 및 권한 부여

Terraform 실습을 위해 별도의 IAM 사용자를 생성하고, 필요한 권한을 부여합니다. (개인 계정 사용자만 해당)

1. [IAM 서비스](https://us-east-1.console.aws.amazon.com/iamv2)에 접속합니다.
2. 좌측 메뉴에서 **Users**를 선택하고, [Users 페이지](https://us-east-1.console.aws.amazon.com/iamv2/home#/users)로 이동합니다.
3. 우측 상단의 **Create user** 버튼을 클릭합니다.
4. **User name**에 `terraform` 등 원하는 이름을 입력하고 **다음**을 클릭합니다. (유저명은 자유롭게 지정 가능)
5. **프로그래밍 방식 액세스**와 **AWS Management Console 액세스**를 모두 선택합니다.
6. **Attach policies directly**를 선택한 뒤, `AdministratorAccess`와 `PowerUserAccess` 권한을 모두 추가합니다.
7. **다음**을 눌러 사용자 생성을 완료합니다.
8. 생성된 사용자를 선택하여 **Summary** 화면으로 이동한 뒤, **Security credentials** 탭을 클릭합니다.
   - AWS 자격 증명 유형 선택에서 "액세스 키 (0)" 선택

> 실습 편의를 위해 관리자 권한을 부여하지만, 실제 운영 환경에서는 최소 권한 원칙을 반드시 준수해야 합니다.

## 3. Access Key 발급 및 AWS CLI 설정

1. **Security credentials** 탭에서 **Create access key**를 클릭합니다.
2. "Access key best practices & alternatives" 화면에서 **Command Line Interface (CLI)**를 선택하고, 확인 체크박스를 모두 클릭한 뒤 진행합니다.
3. **Create access key** 버튼을 클릭하여 **Access Key ID**와 **Secret Access Key**를 발급받습니다.
4. **Download .csv file**을 클릭하여 키 정보를 안전하게 저장합니다. (Secret Access Key는 이 화면을 벗어나면 다시 확인할 수 없으니 반드시 저장)
5. [AWS CLI 설치 가이드](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-chap-install.html)를 참고하여 AWS CLI를 설치합니다.
6. 터미널에서 아래 명령어로 AWS CLI를 설정합니다.

```bash
python3 -m pip install awscli
complete -C aws_completer aws

aws configure
# security setting
AWS Access Key ID [None]: (발급받은 Access Key ID)
AWS Secret Access Key [None]: (발급받은 Secret Access Key)
Default region name [None]: ap-northeast-2
Default output format [None]: text
```

7. 정상적으로 설정되었는지 아래 명령어로 확인합니다.

```bash
aws ec2 describe-instances
```
(실행 결과가 정상적으로 출력되면 설정 완료)

> 참고: AWS CLI가 설치되어 있지 않은 경우, 아래와 같이 설치할 수 있습니다.  
> (Ubuntu 예시)
> 
> ```bash
> sudo -i
> apt update
> apt install -y python3-pip
> python3 -m pip install --break-system-packages awscli
> complete -C aws_completer aws
> ```


## 4. S3 버킷 생성

실습에 사용할 S3 버킷을 생성합니다. S3 버킷은 데이터 저장, 로그 보관, Terraform 상태 관리 등에 활용됩니다.

* **S3 버킷 생성 명령어 예시:**
```bash
aws s3 mb s3://[고유한-버킷-이름] --region ap-northeast-2
```
- 버킷 이름은 전 세계에서 유일해야 하므로, 팀명 또는 학번 등으로 구분하여 지정하세요.
- 생성된 S3 버킷은 이후 Terraform backend, 데이터 업로드, 로그 저장 등에 사용합니다.

* **S3 버킷 확인:**
```bash
aws s3 ls
```

## 5. AWS CLI 설치 및 구성

로컬 환경에서 AWS 리소스를 관리하기 위해 AWS CLI를 설치하고 방금 발급받은 Access Key를 사용하여 구성합니다.

* **AWS CLI 설치:**
    * [AWS CLI 설치 가이드](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-chap-install.html)를 참고하여 본인 OS에 맞게 설치를 진행합니다.

* **AWS CLI 구성:**
    * 터미널을 열고 `aws configure` 명령을 실행합니다.
    * 위에서 발급받은 **액세스 키 ID**와 **비밀 액세스 키**를 순서대로 입력합니다.
    * **Default region name**에는 실습을 진행할 리전(예: `ap-northeast-2`)을 입력합니다.
    * **Default output format**은 `json`으로 설정합니다.

```bash
$ aws configure
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: ap-northeast-2
Default output format [None]: json
```

이제 `aws sts get-caller-identity` 명령을 실행하여 IAM 사용자 정보가 정상적으로 출력되는지 확인합니다.

## 다음 챕터

다음 장에서는 Terraform을 사용하여 실습에 필요한 기본 인프라(VPC, Subnet, EC2 인스턴스 등)를 코드로 정의하고 프로비저닝하는 방법을 실습합니다.

```bash
$ aws sts get-caller-identity
{
    "UserId": "...",
    "Account": "...",
    "Arn": "arn:aws:iam::...:user/prelab-admin"
}
```

## 다음 챕터

다음 장에서는 Terraform을 사용하여 실습에 필요한 기본 인프라(VPC, Subnet, EC2 인스턴스 등)를 코드로 정의하고 프로비저닝하는 방법을 실습합니다.
