locals {
  principal_read_count     = "${length(var.principal_readonly)}"
  principal_read_non_empty = "${signum(length(var.principal_readonly))}"
  principal_read_empty     = "${signum(length(var.principal_readonly)) == 0 ? 1 : 0}"

  principal_full_count     = "${length(var.principal)}"
  principal_full_non_empty = "${signum(length(var.principal))}"
  principal_full_empty     = "${signum(length(var.principal)) == 0 ? 1 : 0}"

  principal_count     = "${length(var.principal_readonly) + length(var.principal)}"
  principal_non_empty = "${signum(length(var.principal_readonly) + length(var.principal))}"
  principal_empty     = "${signum(length(var.principal_readonly) + length(var.principal)) == 0 ? 1 : 0}"
}

module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.3.1"
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
  count = "${local.principal_empty}"

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
  count              = "${local.principal_empty}"
  name               = "${module.label.id}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_instance_profile" "default" {
  count = "${local.principal_empty}"
  name  = "${module.label.id}"
  role  = "${aws_iam_role.default.name}"
}

## Grant access to default role
data "aws_iam_policy_document" "default_ecr" {
  count = "${local.principal_empty}"

  statement {
    sid    = "ecr"
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
  count      = "${local.principal_empty}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.default_ecr.json}"
}

## If any roles provided
## Grant access to them

data "aws_iam_policy_document" "empty" {}


data "aws_iam_policy_document" "resource_readonly" {
  statement {
    sid    = "readonly"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${var.principal_readonly}"
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

data "aws_iam_policy_document" "resource_full" {
  statement {
    sid    = "full"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${var.principal}"
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

  source_json = "${local.principal_read_non_empty ? data.aws_iam_policy_document.resource_readonly.json : data.aws_iam_policy_document.empty.json}"
  override_json = "${local.principal_full_non_empty ? data.aws_iam_policy_document.resource_full.json : data.aws_iam_policy_document.empty.json}"
}

resource "aws_ecr_repository_policy" "default" {
  count      = "${local.principal_non_empty}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.resource.json}"
}
