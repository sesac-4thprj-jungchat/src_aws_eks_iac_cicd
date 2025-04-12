terraform {
  required_version = ">= 1.11"    #해당 Terraform 코드를 실행하는 실제 환경(로컬 PC나 CI/CD, 혹은 Terraform Cloud 등)에서 사용 중인 Terraform 버전과 호환되는지 확인할 때 쓰임. 
                                 #로컬에서 Terraform 명령어(예: terraform init, terraform plan, terraform apply) 를 직접 실행한다면, required_version 보다 낮은 버전을 쓰는 경우 오류가 나면서 실행이 중단됨.
                                 #예를 들어 required_version = ">= 1.4" 인데 실제로 로컬에 설치된 Terraform이 1.3 버전이라면, 실행 시 버전 호환 오류가 발생
                                 #Terraform Cloud나 CI/CD 파이프라인 등 원격 환경에서 Terraform이 실행된다면, 해당 원격 환경의 Terraform 버전이 required_version을 만족해야 합니다. 로컬 PC에 설치된 Terraform 버전이 달라도,
                                 #원격에서 실행하도록 설정해둔 경우는 상관이 없음
                                 #Terraform이 실행될 때, 사용 중인 Terraform 버전이 1.4 이상이어야 실행 가능.
                                 #만약 Terraform 1.3 이하가 설치된 환경에서 실행하면 버전 오류가 발생하고 실행이 중단됨.
                                 #AWS의 Terraform 버전과는 무관하며, Terraform CLI 자체(여기선 로컬)의 버전을 의미.
  backend "s3" {                 #Terraform의 상태 파일(state file) 을 어디에 저장할지 정의하는 블록
    bucket         = "jdy-test-tfstate"      #Terraform 상태 파일을 저장할 S3 버킷 이름을 지정(AWS 콘솔로 먼저 정해놔야 함(생성하던가))
    key            = "eks/jdy-dev.tfstate"   #S3 버킷 내에서 상태 파일을 저장할 경로(파일명 역할)를 지정, Terraform이 terraform apply를 실행할 때 eks/ 폴더가 자동으로 생성(사전 aws콘솔에서 내가 만들어놔야할 필요 X). eks/jdy-dev.tfstate처럼 프로젝트/환경별로 구분될 수 있게 폴더 구조를 넣으면 편리. 콘솔에서 만들어놓기 eks는 폴더명, jdy-dev.tfstate → Terraform 상태 파일 이름, S3에 저장될 최종 경로: s3://jdy-test-tfstate/eks/jdy-dev.tfstate
    region         = "ap-northeast-2"     #S3 버킷이 생성된 AWS 리전(ex)ap-northeast-2(서울))
    profile        = "jdy-test"       #Terraform이 AWS와 통신할 때 사용할 AWS CLI 프로필 이름 #★로컬 머신의 ~/.aws/credentials 또는 ~/.aws/config에서 설정한 프로필 이름을 사용. 로컬 머신의 ~/.aws/credentials 또는 ~/.aws/config에서 설정한 프로필 이름
    use_lockfile = true #dynamodb_table = "TerraformStateLock"에서 use_lockfile   = true로 변경 #Terraform에서 상태 파일의 동시 작업 충돌을 막기 위한 Lock 정보를 저장하는 DynamoDB 테이블 이름. 미리 DynamoDB에서 Lock 용도로 생성해둔 테이블 이름을 적어야 합니다(예: TerraformStateLock).(아래주석처리한 코드로 터미널에 입력해서 만들기(없다면)
                                           #만약 dynamodb_table 테이블이 없다면 DynamoDB 콘솔에서 “키: LockID (String)” 형태로 테이블을 새로 만듬. 이미 있다면 DynamoDB 콘솔이나 CLI로 확인하여 해당 이름을 넣습니다.
  }
}
#만약 dynamodb_table 테이블이 없다면 DynamoDB 콘솔에서 “키: LockID (String)” 형태로 테이블을 새로 만듬. 이미 있다면 DynamoDB 콘솔이나 CLI로 확인하여 해당 이름을 넣습니다.
#또는 cli로 생성해도 됨(아래 복사해서 리눅스 터미널에서 치기)
# aws dynamodb create-table \
#   --table-name TerraformStateLock \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region ap-northeast-2  \ #jdy-test 프로파일에 지역 있는데 인지 못함->지역 명시해줘야 함
# 또는  --profile jdy-test 추가


# aws dynamodb create-table \
#   --table-name TerraformStateLock \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region ap-northeast-2  \
#   --profile jdy-test

provider "aws" {         #Terraform이 AWS 리소스를 생성/관리할 때 어떤 리전, 어떤 인증 정보를 사용하고, 어떤 태그를 자동으로 붙일지 정의
  region = local.region   #리소스를 생성할 AWS 리전. 여기서는 local.region 값을 가져와 사용
  # shared_config_files=["~/.aws/config"] # Or $HOME/.aws/config
  # shared_credentials_files = ["~/.aws/credentials"] # Or $HOME/.aws/credentials
  profile = "jdy-test"  #마찬가지로 AWS CLI 프로필 이름. jdy-test(위에서 설명한 ~/.aws/credentials 혹은 ~/.aws/config의 프로필).

  # 자동으로 공통 태그를 추가해주는 기능
  default_tags {       #Terraform 1.0 이후부터 지원되는 기능으로, 모든 AWS 리소스에 공통적으로 태그를 자동 추가
    tags = {           #회사/조직에서 원하는 공통 태그 (예: Organization, Team, Env, Terraformed, Resource 등)를 기입. 보통 리소스의 소유 부서, 환경(개발/스테이징/운영), 담당 팀/서비스명 등을 태그로 넣습니다
      Service      = "Sesac-Test"
      Organization = "tech"
      Team         = "tech/devops"
      Resource     = "eks"
      Env          = "test"
      Terraformed  = "true"
    }
  }
}




provider "kubernetes" {    #AWS EKS 클러스터에 연결해 Kubernetes 리소스(Deployment, Service, Namespace 등)를 Terraform으로 관리하고자 할 때 필요한 설정
  host                   = module.eks.cluster_endpoint   #EKS 엔드포인트 URL. EKS 모듈(module.eks)에서 해당 정보를 반환해주도록 설정되어 있어야 함.
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)    #cluster_ca_certificate: 클러스터 인증서(CA)를 Base64 디코딩하여 Kubernetes API 서버와의 보안 통신에 사용
# main.tf 코드에는 직접 output "cluster_endpoint"를 정의한 부분이 보이지 않습니다. 그러나 이 코드는 **module "eks"가 “terraform-aws-modules/eks/aws”**라는 원격 모듈을 사용하고 있기 때문에, “cluster_endpoint”라는 output은 원격 모듈 내부에 이미 정의되어 있음
# terraform-aws-modules/eks/aws 모듈(깃허브나 Terraform Registry에서 제공)은 EKS 클러스터를 만들고,
# 모듈 내부에서 EKS 클러스터의 엔드포인트(예: https://xxxxxxx.eks.amazonaws.com) 정보를 output "cluster_endpoint"라는 이름으로 내보냅니다.
# 따라서 원격 모듈의 outputs.tf 안에 정의된 output "cluster_endpoint"를 자동으로 상위(현재 main.tf)에서 사용할 수 있게 되는 것이죠.
# 그래서 module.eks.cluster_endpoint라고 참조만 하면, 그 원격 모듈에서 반환된 EKS 클러스터 엔드포인트 값을 쓸 수 있
  exec {   #exec 블록: AWS EKS 토큰 인증 방식을 사용하기 위해, 'aws eks get-token' 명령어를 실행하여 임시 인증 토큰을 받아옵
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

locals {      #Terraform 코드 곳곳에서 재사용되는 상수나 기본값들을 정리해 두는 공간
  name            = "jdy-dev"    #EKS 클러스터 혹은 리소스에 공통적으로 쓰일 네이밍 접두사(“개발용 EKS” 등)
  cluster_version = "1.31"  # EKS 업그레이드 시 1.28 to 1.29 변경   # EKS 버전 (1.28, 1.29 등). EKS를 업그레이드할 때 변경
  region          = "ap-northeast-2"   #리소스를 생성할 AWS 리전 (예: ap-northeast-2).

  vpc_cidr = "10.120.0.0/16"     #VPC 네트워크 CIDR 블록 (예: 10.120.0.0/16), 회사 내 IP 주소 정책이나 이미 쓰고 있는 IP 대역과 충돌하지 않도록 조정해야
  azs      = slice(data.aws_availability_zones.available.names, 0, 3) #EKS나 다른 리소스를 배포할 가용 영역(Availability Zones) 목록. slice(...) 함수를 사용해 최대 3개만 추려 사용
                                                                      #Terraform에서 data "aws_availability_zones" "available"는 해당 리전(ap-northeast-2)의 가능한 AZ를 모두 가져옵니다
                                                                      #slice(..., 0, 3)는 그 중 0번째부터 3번째 직전까지(총 3개)를 잘라 리스트로 반환
                                                                      #주로 EKS나 RDS, ELB 등을 멀티 AZ로 구성할 때 2~3개 AZ를 선택해서 쓰면 됩니다.
  tags = {   #팀/사용자 구분을 위한 태그 등
    User = "jdy"
  }
}
