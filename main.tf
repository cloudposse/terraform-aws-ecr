data "aws_iam_role" "default" {
  count = "${signum(length(var.roles)) == 1 ? length(var.roles) : 0}"
  name  = "${element(var.roles, count.index)}"
}

data "aws_iam_policy_document" "assume_role" {
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

data "aws_iam_policy_document" "login" {
  statement {
    sid     = "ECRGetAuthorizationToken"
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "write" {
  statement {
    sid    = "ECRGetAuthorizationToken"
    effect = "Allow"

    actions = [
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]

    resources = ["${aws_ecr_repository.default.arn}"]
  }
}

data "aws_iam_policy_document" "read" {
  statement {
    sid    = "ECRGetAuthorizationToken"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
    ]

    resources = ["${aws_ecr_repository.default.arn}"]
  }
}

data "aws_iam_policy_document" "default_ecr" {
  count = "${signum(length(var.roles)) == 1 ? 0 : 1}"

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
      "ecr:GetAuthorizationToken",
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

data "aws_iam_policy_document" "resource" {
  count = "${signum(length(var.roles))}"

  statement {
    sid    = "ecr"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${data.aws_iam_role.default.*.arn}",
      ]
    }

    actions = [
      "ecr:GetAuthorizationToken",
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

resource "aws_ecr_repository_policy" "default" {
  count      = "${signum(length(var.roles))}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.resource.json}"
}

resource "aws_ecr_repository_policy" "default_ecr" {
  count      = "${signum(length(var.roles)) == 1 ? 0 : 1}"
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.default_ecr.json}"
}

resource "aws_iam_policy" "login" {
  name        = "${module.label.id}${var.delimiter}login"
  description = "Allow IAM Users to call ecr:GetAuthorizationToken"
  policy      = "${data.aws_iam_policy_document.login.json}"
}

resource "aws_iam_policy" "read" {
  name        = "${module.label.id}${var.delimiter}read"
  description = "Allow IAM Users to pull from ECR"
  policy      = "${data.aws_iam_policy_document.read.json}"
}

resource "aws_iam_policy" "write" {
  name        = "${module.label.id}${var.delimiter}write"
  description = "Allow IAM Users to push into ECR"
  policy      = "${data.aws_iam_policy_document.write.json}"
}

resource "aws_iam_role" "default" {
  count              = "${signum(length(var.roles)) == 1 ? 0 : 1}"
  name               = "${module.label.id}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "default_ecr" {
  count      = "${signum(length(var.roles)) == 1 ? 0 : 1}"
  role       = "${aws_iam_role.default.name}"
  policy_arn = "${aws_iam_policy.login.arn}"
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = "${signum(length(var.roles)) == 1 ? length(var.roles) : 0}"
  role       = "${element(var.roles, count.index)}"
  policy_arn = "${aws_iam_policy.login.arn}"
}

resource "aws_iam_instance_profile" "default" {
  count = "${signum(length(var.roles)) == 1 ? 0 : 1}"
  name  = "${module.label.id}"
  role  = "${aws_iam_role.default.name}"
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
