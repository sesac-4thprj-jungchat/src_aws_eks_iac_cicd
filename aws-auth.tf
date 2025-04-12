# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = jsonencode([
#       {
#         rolearn  = "arn:aws:iam::637423586845:role/jdy-test-eks-managed-node-group"
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = ["system:nodes"]
#       }
#     ])

#     mapUsers = jsonencode([
#       {
#         userarn  = "arn:aws:iam::637423586845:user/liqejdy"
#         username = "liqejdy"
#         groups   = ["system:masters"]
#       }
#     ])
#   }
# }