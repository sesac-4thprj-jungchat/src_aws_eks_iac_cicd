# # 최초 설치 시 포함하지 않는 것을 권고합니다.
# # 아래 TF 변수(ex var.cluster_name, var.secret_hosted_zone_id)를 각자 설정으로 대체합니다.

# # 혹은 아래와 같이 TF 변수를 설정합니다. 
# # export TF_VAR_secret_hosted_zone_id="xxxx"
# # export TF_VAR_secret_aws_account_id="xxxx"
# # export TF_VAR_cluster_name="xxxx"

module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "load-balancer-controller-jdy-dev"    # 변수로 사용방법:  role_name                              = "load-balancer-controller-${var.cluster_name}"
  attach_load_balancer_controller_policy = true

  # ✅ 추가할 IAM 정책-aws-load-balancer-controller pod가 CrashLoopBackoff가 떠서 로그 애러보니 정책문제일 가능성(이거 추가하고서도 바로 파드 running안 뜸)
  role_policy_arns = {
    AmazonVPCFullAccess     = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
    AmazonEC2FullAccess     = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    AmazonEKSServicePolicy  = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    AmazonEKSClusterPolicy  = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  }




  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]  ##네임스페이스: kube-system, service_accounts: aws-load-balancer-controller
    }
  }

  tags = local.tags
}





module "external_dns_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = "external-dns-jdy-dev"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/Z02570151ASF6KZOF4G2D"]   #Z02570151ASF6KZOF4G2D 대신 ${var.secret_hosted_zone_id}: 이런식으로 변수처리를 해서 넣어도 되지만 그냥 넣음.

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]   #네임스페이스: kube-system, service_accounts: external-dns
    }
  }

  tags = local.tags
}
###############################################################################################
# module "ebs_csi_irsa_role" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name             = "ebs-csi-${var.cluster_name}"
#   attach_ebs_csi_policy = true

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }

#   tags = local.tags
# }

module "ebs_csi_irsa_role" {                                                           
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"   #★★ terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks 모듈은 IRSA (IAM Role for Service Accounts)를 구성하는 것이고, 특정 서비스 어카운트가 EKS 내에서 해당 IAM Role을 Assume 할 수 있도록 설정해주는 역할을 합니다.

  role_name             = "ebs-csi-jdy-dev"    #<<단 eks-addon.tf의 service_account_role_arn 이름과 맞춰야함!
  attach_ebs_csi_policy = true

  oidc_providers = {                             
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]      #["kube-system:ebs-csi-controller-sa"]: 네임스페이스와 서비스 어카운트 
    }
  }

  tags = local.tags
}


