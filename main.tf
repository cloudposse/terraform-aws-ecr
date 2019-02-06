locals {
  principals_readonly_access_non_empty = "${signum(length(var.principals_readonly_access))}"
  principals_full_access_non_empty     = "${signum(length(var.principals_full_access))}"
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  enabled    = "${var.enabled}"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

resource "aws_ecr_repository" "default" {
  count = "${var.enabled == "true" ? 1 : 0}"
  name  = "${var.use_fullname == "true" ? module.label.id : module.label.name}"
}

resource "aws_ecr_lifecycle_policy" "default" {
  count      = "${var.enabled == "true" ? 1 : 0}"
  repository = "${aws_ecr_repository.default.name}"

  policy = <<EOF
{
  "rules": [{
    "rulePriority": 1,
    "description": "Rotate images when reach ${var.max_image_count} images stored",
    "selection": {
      "tagStatus": "tagged",
      "tagPrefixList": ["${var.stage}"],
      "countType": "imageCountMoreThan",
      "countNumber": ${var.max_image_count}
    },
    "action": {
      "type": "expire"
    }
  }]
}
EOF
}

data "aws_iam_policy_document" "resource" {
  statement {
    sid    = "ReadonlyAccess"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${var.principals_readonly_access}"
      ]
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]
  }

  statement {
    sid    = "FullAccess"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${var.principals_full_access}"
      ]
    }

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]
  }
  
}

resource "aws_ecr_repository_policy" "default" {
  count      = "${var.enabled == "true" ? 1 : 0}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.resource.json}"
}
