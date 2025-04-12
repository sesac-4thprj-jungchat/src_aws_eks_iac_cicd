resource "aws_ecr_repository" "github_actions_ecr" {
  name                 = "github-action-test" # ECR 리포지토리 이름
  image_tag_mutability = "MUTABLE"    #<<이미지 테그를 변경 가능하다는 옵션
}
