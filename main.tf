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

data "aws_iam_policy_document" "token" {
  statement {
    sid     = "ECRGetAuthorizationToken"
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]

    resources = ["${aws_ecr_repository.default.arn}"]
  }
}

data "aws_iam_policy_document" "resource" {
  statement {
    sid    = "nodes"
    effect = "Allow"

    principals = {
      type = "AWS"

      identifiers = [
        "${var.principals}",
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
      "ecr:DeleteRepository",
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

resource "aws_ecr_repository_policy" "default" {
  repository = "${aws_ecr_repository.default.name}"
  policy     = "${data.aws_iam_policy_document.resource.json}"
}

resource "aws_iam_policy" "default" {
  name        = "${module.label.id}"
  description = "Allow IAM Users have to access to call ecr:GetAuthorizationToken"
  policy      = "${data.aws_iam_policy_document.token.json}"
}

resource "aws_iam_role" "default" {
  name               = "${module.label.id}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = "${aws_iam_role.default.name}"
  policy_arn = "${aws_iam_policy.default.arn}"
}

resource "aws_iam_instance_profile" "default" {
  name = "${module.label.id}"
  role = "${aws_iam_role.default.name}"
}
