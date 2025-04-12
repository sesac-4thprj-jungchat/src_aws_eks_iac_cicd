provider "aws" {
  region = local.region
  profile = "jdy-test"

  # 자동으로 공통 태그를 추가한다.
  default_tags {
    tags = {
      Service      = "SNS-Test"
      Organization = "tech"
      Team         = "tech/devops"
      Resource     = "ecr"
      Env          = "test"
      Terraformed  = "true"
    }
  }
}

terraform {
  required_version = ">= 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.57"
    }
  }

  backend "s3" {
    bucket         = "jdy-test-tfstate"
    key            = "ecr/jdy-dev.tfstate"
    region         = "ap-northeast-2"
    profile        = "jdy-test"
    use_lockfile   = true
  }
}

locals {
  region          = "ap-northeast-2"
}
