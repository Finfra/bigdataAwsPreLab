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

## 2. IAM 사용자 생성

보안을 위해 Root 계정을 직접 사용하는 대신, 실습에 필요한 권한만 가진 IAM 사용자를 생성하여 사용하는 것이 좋습니다.

1. AWS Management Console에 로그인 후 **IAM** 서비스로 이동합니다.
2. 왼쪽 메뉴에서 **사용자**를 선택하고 **사용자 추가** 버튼을 클릭합니다.
3. **사용자 이름**을 입력합니다. (예: `prelab-admin`)
4. **액세스 유형**에서 **프로그래밍 방식 액세스**와 **AWS Management Console 액세스**를 모두 선택합니다.
5. **다음: 권한**으로 이동하여 **기존 정책 직접 연결**을 선택하고 `AdministratorAccess` 정책을 연결합니다. (실습의 편의를 위해 관리자 권한을 부여하지만, 실제 운영 환경에서는 최소 권한 원칙을 따라야 합니다.)
6. 태그 추가는 건너뛰고 **다음: 검토** 및 **사용자 만들기**를 클릭하여 사용자를 생성합니다.

## 3. Access Key 발급

사용자 생성이 완료되면 **액세스 키 ID**와 **비밀 액세스 키**가 표시됩니다. 이 정보는 Terraform, AWS CLI 등에서 AWS API를 호출할 때 사용되므로, **반드시 `.csv` 파일을 다운로드**하거나 안전한 곳에 복사하여 보관해야 합니다. **이 화면을 벗어나면 비밀 액세스 키를 다시 확인할 수 없습니다.**

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

## 다음 과정

다음 장에서는 Terraform을 사용하여 실습에 필요한 기본 인프라(VPC, Subnet, EC2 인스턴스 등)를 코드로 정의하고 프로비저닝하는 방법을 학습합니다.

```bash
$ aws sts get-caller-identity
{
    "UserId": "...",
    "Account": "...",
    "Arn": "arn:aws:iam::...:user/prelab-admin"
}
```

## 다음 과정

다음 장에서는 Terraform을 사용하여 실습에 필요한 기본 인프라(VPC, Subnet, EC2 인스턴스 등)를 코드로 정의하고 프로비저닝하는 방법을 학습합니다.
