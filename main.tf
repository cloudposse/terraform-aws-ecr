locals {
  principals_readonly_access_non_empty = length(var.principals_readonly_access) > 0 ? true : false
  principals_full_access_non_empty     = length(var.principals_full_access) > 0 ? true : false
  ecr_need_policy                      = length(var.principals_full_access) + length(var.principals_readonly_access) > 0 ? true : false
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.14.1"
  enabled    = var.enabled
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

resource "aws_ecr_repository" "default" {
  count = var.enabled ? 1 : 0
  name  = var.use_fullname ? module.label.id : module.label.name
  tags  = module.label.tags
}

resource "aws_ecr_lifecycle_policy" "default" {
  count      = var.enabled ? 1 : 0
  repository = join("", aws_ecr_repository.default.*.name)

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Remove untagged images",
      "selection": {
        "tagStatus": "untagged",
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Rotate images when reach ${var.max_image_count} images stored",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": ${var.max_image_count}
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "empty" {
  count = var.enabled ? 1 : 0
}

data "aws_iam_policy_document" "resource_readonly_access" {
  count = var.enabled ? 1 : 0

  statement {
    sid = "ReadonlyAccess"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = var.principals_readonly_access
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
}

data "aws_iam_policy_document" "resource_full_access" {
  count = var.enabled ? 1 : 0

  statement {
    sid = "FullAccess"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = var.principals_full_access
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

data "aws_iam_policy_document" "resource" {
  count = var.enabled ? 1 : 0
  source_json = local.principals_readonly_access_non_empty ? join("", data.aws_iam_policy_document.resource_readonly_access.*.json) : join("", data.aws_iam_policy_document.empty.*.json)
  override_json = local.principals_full_access_non_empty ? join("", data.aws_iam_policy_document.resource_full_access.*.json) : join("", data.aws_iam_policy_document.empty.*.json)
}

resource "aws_ecr_repository_policy" "default" {
  count = local.ecr_need_policy && var.enabled ? 1 : 0
  repository = join("", aws_ecr_repository.default.*.name)
  policy = join("", data.aws_iam_policy_document.resource.*.json)
}
