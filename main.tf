locals {
  principals_readonly_access_count     = "${length(var.principals_readonly_access)}"
  principal_readonly_access_non_empty = "${signum(length(var.principals_readonly_access))}"
  principals_readonly_access_empty     = "${signum(length(var.principals_readonly_access)) == 0 ? 1 : 0}"

  principals_full_access_count     = "${length(var.principals_full_access)}"
  principals_full_access_non_empty = "${signum(length(var.principals_full_access))}"
  principals_full_access_empty     = "${signum(length(var.principals_full_access)) == 0 ? 1 : 0}"

  principals_total_count     = "${length(var.principals_readonly_access) + length(var.principals_full_access)}"
  principals_total_non_empty = "${signum(length(var.principals_readonly_access) + length(var.principals_full_access))}"
  principals_total_empty     = "${signum(length(var.principals_readonly_access) + length(var.principals_full_access)) == 0 ? 1 : 0}"
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.3"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

resource "aws_ecr_repository" "default" {
  name = "${var.use_fullname == "true" ? module.label.id : module.label.name}"
}

resource "aws_ecr_lifecycle_policy" "default" {
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

## If roles are empty
## Create default role to provide full access.
## The role can be attached or assumed

data "aws_iam_policy_document" "assume_role" {
  count = "${local.principals_total_empty}"

  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals = {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  count              = "${local.principals_total_empty}"
  name               = "${module.label.id}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_instance_profile" "default" {
  count = "${local.principals_total_empty}"
  name  = "${module.label.id}"
  role  = "${aws_iam_role.default.name}"
}

## Grant access to default role
data "aws_iam_policy_document" "default_ecr" {
  count = "${local.principals_total_empty}"

  statement {
    sid    = "ECR"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${aws_iam_role.default.arn}",
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
    ]
  }
}

resource "aws_ecr_repository_policy" "default_ecr" {
  count      = "${local.principals_total_empty}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.default_ecr.json}"
}

## If any roles provided
## Grant access to them

data "aws_iam_policy_document" "empty" {}

data "aws_iam_policy_document" "resource_readonly_access" {
  statement {
    sid    = "ReadonlyAccess"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${var.principal_readonly_access}",
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
}

data "aws_iam_policy_document" "resource_full_access" {
  statement {
    sid    = "FullAccess"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${var.principals_full_access}",
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

data "aws_iam_policy_document" "resource" {
  count = "${local.principal_non_empty}"

  source_json   = "${local.principals_read_access_non_empty ? data.aws_iam_policy_document.resource_readonly_access.json : data.aws_iam_policy_document.empty.json}"
  override_json = "${local.principals_full_access_non_empty ? data.aws_iam_policy_document.resource_full_access.json : data.aws_iam_policy_document.empty.json}"
}

resource "aws_ecr_repository_policy" "default" {
  count      = "${local.principals_total_non_empty}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.resource.json}"
}
