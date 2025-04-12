data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}


################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.0"

#✅ 1. Terraform Registry에서 최신 버전 확인 (가장 정확한 방법)
# Terraform에서 terraform-aws-modules/eks/aws 모듈의 최신 버전은 Terraform Registry 공식 페이지에서 확인할 수 있습니다.
# 👉 EKS 모듈 최신 버전 확인
# 1️⃣ 위 링크를 클릭하여 접속
# 2️⃣ "Latest Version" 섹션에서 최신 버전 확인
# 3️⃣ version = "X.Y.Z" 값을 module "eks" 블록에 적용
# 예제 (최신 버전이 20.0.1이라면):  
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "20.0.1"  # 최신 버전 반영
# }

  enable_irsa = true   #<<true 넣어주는 거 중요
  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true #운영환경이면 vpn를 사용한다고 했을 때 vpn 내부에서만 접근할 수 있도록 false로 할 것. true여도 특정 ip에서만 접근가능하도록 할 수 있음

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true

      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id                   = module.vpc.vpc_id                #★terraform apply시 자동 생성됨
  subnet_ids               = module.vpc.private_subnets       #★terraform apply시 자동 생성됨
  control_plane_subnet_ids = module.vpc.intra_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {     #<<카펜터가 주로 사용
    karpenter = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      name            = "karpenter"
      use_name_prefix = false
      description     = "Karpenter - EKS managed node group"

      instance_types       = ["m7i.large", "m7i-flex.large"]
      force_update_version = true
      capacity_type        = "SPOT" #"SPOT" 사용 적극 권장(비용 줄일 수 있음)

      min_size     = 2   #기본으로 제공하는 매니지드 노드그룹은 클러스터 오토스케일링을 사용하지 않을 예정이라. 기본 2개로 하고, 추가로 확장이 필요한 경우엔 카펜터가 실행하는 추가노드풀에서 실행해서 확장
      max_size     = 2
      desired_size = 2

      ami_id = data.aws_ami.eks_default.image_id
      subnet_ids = module.vpc.private_subnets
      disk_size = 80 #기본20GB인데 늘림

      ebs_optimized           = true
      disable_api_termination = false
      enable_monitoring       = true

      # block_device_mappings = {
      #   xvda = {
      #     device_name = "/dev/xvda"
      #     ebs = {
      #       volume_size           = 75
      #       volume_type           = "gp3"
      #       iops                  = 3000
      #       throughput            = 150
      #       encrypted             = true
      #       kms_key_id            = module.ebs_kms_key.key_arn
      #       delete_on_termination = true
      #     }
      #   }
      # }

      create_iam_role          = true                         # IAM Role (EKS 클러스터용)(EKS 노드 그룹이 사용할 IAM 역할)
      iam_role_name            = "jdy-test-eks-managed-node-group"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS test managed node group"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {                             # EKS에서 컨테이너 이미지를 가져올 수 있도록 AmazonEC2ContainerRegistryReadOnly 정책을 추가, additional IAM 정책을 커스텀으로 정의
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        additional                         = aws_iam_policy.node_additional.arn
      }
      tags = { Name = "karpenter" }
    }
  }
  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"  #main.tf 코드에는 직접 output "cluster_endpoint"를 정의한 부분이 보이지 않습니다. 그러나 이 코드는 **module "eks"가 “terraform-aws-modules/eks/aws”**라는 원격 모듈을 사용하고 있기 때문에, “cluster_endpoint”라는 output은 원격 모듈 내부에 이미 정의되어 있음
  version = "~> 5.0"     # 최신 5.x 버전 자동 업데이트. Terraform에서 version을 설정할 때, Terraform Registry에서 최신 버전을 확인한 후 설정하는 것이 가장 정확합니다.현재 최신 버전이 5.x 이상이라면 ~> 5.0을 사용할 수도 있으며,특정 버전만 고정하려면 = 4.1.0 같은 형태로 지정하면 됩니다.              
 #version = "~> 4.0"은 Terraform에서 사용할 모듈의 버전을 지정하는 방식입니다. 이 값을 설정할 때는 해당 모듈의 최신 안정화 버전을 확인한 후, 적절한 버전을 지정해야 합니다.
 #Terraform에서 사용할 terraform-aws-modules/vpc/aws 모듈의 최신 버전은 Terraform Registry에서 확인할 수 있습니다.
#  📌Terraform Registry에서 VPC 모듈 최신 버전 확인 방법
# 1️⃣ 공식 Terraform Registry 페이지 방문:
# 👉 https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
# 2️⃣ 최신 버전 확인 (예: 5.0.0 또는 4.x.x)
# 3️⃣ Terraform 코드에서 최신 버전을 반영하여 설정
# terraform-aws-modules/eks/aws 모듈(깃허브나 Terraform Registry에서 제공)은 EKS 클러스터를 만들고,
# 모듈 내부에서 EKS 클러스터의 엔드포인트(예: https://xxxxxxx.eks.amazonaws.com) 정보를 output "cluster_endpoint"라는 이름으로 내보냅니다.
# 따라서 원격 모듈의 outputs.tf 안에 정의된 output "cluster_endpoint"를 자동으로 상위(현재 main.tf)에서 사용할 수 있게 되는 것이죠.
# 그래서 module.eks.cluster_endpoint라고 참조만 하면, 그 원격 모듈에서 반환된 EKS 클러스터 엔드포인트 값을 쓸 수 있


  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]  #Private Subnet/20(4096) IP 할당
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)] #Public Subnet/24(256) IP 할당
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway     = true                 #각 AZ 마다 NAT G/W 하나씩 생성(->추가 별도 비용을 지불하지 않기 위해)
  create_egress_only_igw = true

  single_nat_gateway     = true 
  one_nat_gateway_per_az = false

  public_subnet_tags = {                        #subnet에 추가 annotation 설정이 필요, elb와 통신이 필요해서(그 때 통신을 위해 필요한 테그)(안 하면 나중에 elb만들고 나서 통신이 안 되는데 일일히 찾아서 해야 됨)
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {                    #역시 elb와 통신을 위해 필요
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  tags = local.tags
}





module "vpc_cni_irsa" {                               
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  # Policy
  key_administrators = [
    data.aws_caller_identity.current.arn
  ]

  key_service_roles_for_autoscaling = [
    # required for the ASG to manage encrypted volumes for nodes
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    # required for the cluster / persistentvolume-controller to create encrypted PVCs
    module.eks.cluster_iam_role_arn,
  ]

  # Aliases
  aliases = ["eks/${local.name}/ebs"]

  tags = local.tags
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = local.name
  create_private_key = true

  tags = local.tags
}



resource "aws_iam_policy" "node_additional" {   
  name        = "${local.name}-additional"   
  description = "Example usage of node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
}


#####################################################################################################################################################################
########################################### EKS 접근을 위해 iam pricipal ARN 설정해주는 코드!!!########################################################################
########################################### 맨 아래에 주석으로 처리되어 있는 iam화면에서 설정해주는 것과 동일한 코드랑 다른 거임(여긴 eks에서 설정해주는 격)#############################################
#################################### eks에서 하는 게 IAM에서 하는 것보다 우선되는 정책임(iam에서하는 건 aws 전체적인 서비스에서 통용되는 일반적인 권한 느낌)##########################
#################################################### 여기서 적용할 수 있는 정책 보려면 aws eks list-access-policies 검색  ######################################################
# EKS 클러스터에 IAM 사용자 액세스 항목 추가
# EKS 클러스터에 IAM 사용자 액세스 항목 추가
resource "aws_eks_access_entry" "liqejdy_access" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = "arn:aws:iam::637423586845:user/liqejdy"
  type              = "STANDARD"
  
  depends_on = [
    module.eks
  ]
}

# EKS 클러스터 액세스 항목에 AmazonEKSClusterAdminPolicy 연결
resource "aws_eks_access_policy_association" "liqejdy_cluster_admin_policy" {
  cluster_name     = module.eks.cluster_name
  principal_arn    = "arn:aws:iam::637423586845:user/liqejdy"
  policy_arn       = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  
  access_scope {
    type = "cluster"
  }
  
  depends_on = [
    aws_eks_access_entry.liqejdy_access
  ]
}

# AmazonEKSNetworkingClusterPolicy 연결
resource "aws_eks_access_policy_association" "liqejdy_networking_cluster_policy" {
  cluster_name     = module.eks.cluster_name
  principal_arn    = "arn:aws:iam::637423586845:user/liqejdy"
  policy_arn       = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSNetworkingClusterPolicy"
  
  access_scope {
    type = "cluster"
  }
  
  depends_on = [
    aws_eks_access_entry.liqejdy_access
  ]
}

# AmazonEKSAdminPolicy 연결 - 가장 폭넓은 관리자 권한
resource "aws_eks_access_policy_association" "liqejdy_admin_policy" {
  cluster_name     = module.eks.cluster_name
  principal_arn    = "arn:aws:iam::637423586845:user/liqejdy"
  policy_arn       = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  
  access_scope {
    type = "cluster"
  }
  
  depends_on = [
    aws_eks_access_entry.liqejdy_access
  ]
}
###################################################################################################################
# liqejdy 사용자에게 EKS 관련 정책 연결-이건 eks창이 아니라 iam 창에서 연결하는 거랑 똑같은 거임!!(지금 필요한 건 아님)
#(클러스터 접근 권한 문제로 추가한 코드)

# resource "aws_iam_user_policy_attachment" "liqejdy_eks_admin" {      #AmazonEKSClusterPolicy 이 정책만 있어도 kubectl이 돌아가기 시작함..(iam 쪽 안 건드리고 eks 쪽 access만 건드리면 됐음(기존 코드 또는 콘솔에서부터 달라진 점))
#   user       = "liqejdy"
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_user_policy_attachment" "liqejdy_eks_cluster_admin" {
#   user       = "liqejdy"
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterAdminPolicy"
# }

# resource "aws_iam_user_policy_attachment" "liqejdy_eks_networking_cluster" {
#   user       = "liqejdy"
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingClusterPolicy"
# }

# resource "aws_iam_user_policy_attachment" "liqejdy_eks_networking" {
#   user       = "liqejdy"
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
# }
###################################################################################################################