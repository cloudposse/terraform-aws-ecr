locals {
  roles_read_count     = "${length(var.roles_readonly)}"
  roles_read_non_empty = "${signum(length(var.roles_readonly))}"
  roles_read_empty     = "${signum(length(var.roles_readonly)) == 0 ? 1 : 0}"

  roles_full_count     = "${length(var.roles)}"
  roles_full_non_empty = "${signum(length(var.roles))}"
  roles_full_empty     = "${signum(length(var.roles)) == 0 ? 1 : 0}"

  roles_count     = "${length(var.roles_readonly) + length(var.roles)}"
  roles_non_empty = "${signum(length(var.roles_readonly) + length(var.roles))}"
  roles_empty     = "${signum(length(var.roles_readonly) + length(var.roles)) == 0 ? 1 : 0}"
}

data "aws_iam_role" "read" {
  count = "${local.roles_read_non_empty ? local.roles_read_count: 0}"
  name  = "${element(var.roles_readonly, count.index)}"
}

data "aws_iam_role" "full" {
  count = "${local.roles_full_non_empty ? local.roles_full_count : 0}"
  name  = "${element(var.roles, count.index)}"
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
  count = "${local.roles_empty}"

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
  count              = "${local.roles_empty}"
  name               = "${module.label.id}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_instance_profile" "default" {
  count = "${local.roles_empty}"
  name  = "${module.label.id}"
  role  = "${aws_iam_role.default.name}"
}

## Grant access to default role
data "aws_iam_policy_document" "default_ecr" {
  count = "${local.roles_empty}"

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
  count      = "${local.roles_empty}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.default_ecr.json}"
}

## If any roles provided
## Grant access to them

data "aws_iam_policy_document" "resource_readonly" {
  count = "${local.roles_read_non_empty}"

  statement {
    sid    = "readonly"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${data.aws_iam_role.read.*.arn}",
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

resource "aws_ecr_repository_policy" "default_readonly" {
  count      = "${local.roles_read_non_empty}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.resource_readonly.json}"
}


data "aws_iam_policy_document" "resource" {
  count = "${local.roles_full_count}"

  statement {
    sid    = "full"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${data.aws_iam_role.full.*.arn}",
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
  count      = "${local.roles_full_non_empty}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.resource.json}"
}
