# # 최초 설치 시 포함하지 않는 것을 권고합니다.

# resource "aws_eks_addon" "aws_ebs_csi_driver" {
#   cluster_name             = module.eks.cluster_name
#   addon_name               = "aws-ebs-csi-driver"
#   service_account_role_arn = "arn:aws:iam::${var.secret_aws_account_id}:role/ebs-csi-${var.cluster_name}"
#   addon_version            = "v1.26.1-eksbuild.1" 
# }
#aws_snapshot_controller는 설치 안 했음(영상에서)
# resource "aws_eks_addon" "aws_snapshot_controller" {
#   cluster_name             = module.eks.cluster_name
#   addon_name               = "snapshot-controller"
#   # addon_version            = "v1.26.1-eksbuild.1" # 지정하지 않으면 자동으로 default 버전을 설치합니다.
# }

#####################################################################################################
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = "arn:aws:iam::637423586845:role/ebs-csi-jdy-dev"    #<<<irsa-role.tf파일의 module "ebs_csi_irsa_role"의 role_name고 일치시켜야 함!secret_aws_account_id, cluster_name 찾아서 넣기(var변수로 하지 말고)
  addon_version            = "v1.41.0-eksbuild.1"   #https://github.com/kubernetes-sigs/aws-ebs-csi-driver에서 우측 같은데서 최신 버전 확인 1.41.0가 최신(현시점 기준)
}



#aws_snapshot_controller는 설치 안 했음(영상에서)
# resource "aws_eks_addon" "aws_snapshot_controller" {
#   cluster_name             = module.eks.cluster_name
#   addon_name               = "snapshot-controller"
#   addon_version            = "v8.2.0-eksbuild.1" # 지정하지 않으면 자동으로 default 버전을 설치합니다.
# }

