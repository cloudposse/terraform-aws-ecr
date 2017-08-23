data "aws_iam_policy_document" "ecr" {
  statement {
    sid    = "node"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "${var.node_arns}",
      ]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:DeleteRepository",
    ]
  }

  statement {
    sid    = "user"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "${var.user_arns}",
      ]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

module "label" {
  source    = "git::https://github.com/cloudposse/tf_label.git?ref=tags/0.1.0"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
  name      = "${var.name}"
}

resource "aws_ecr_repository" "default" {
  name = "${module.label.id}"
}

resource "aws_ecr_repository_policy" "policy" {
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.ecr.json}"
}
