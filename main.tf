locals {
  principals_readonly_access_non_empty     = length(var.principals_readonly_access) > 0
  principals_pull_through_access_non_empty = length(var.principals_pull_though_access) > 0
  principals_push_access_non_empty         = length(var.principals_push_access) > 0
  principals_full_access_non_empty         = length(var.principals_full_access) > 0
  principals_lambda_non_empty              = length(var.principals_lambda) > 0
  organizations_readonly_access_non_empty  = length(var.organizations_readonly_access) > 0
  organizations_full_access_non_empty      = length(var.organizations_full_access) > 0
  organizations_push_non_empty             = length(var.organizations_push_access) > 0

  ecr_need_policy = (
    length(var.principals_full_access)
    + length(var.principals_readonly_access)
    + length(var.principals_pull_though_access)
    + length(var.principals_push_access)
    + length(var.principals_lambda)
    + length(var.organizations_readonly_access)
    + length(var.organizations_full_access)
    + length(var.organizations_push_access) > 0
  )
}

resource "aws_ecr_repository" "this" {
  count = module.this.enabled ? 1 : 0

  name = var.repository_name

  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  dynamic "encryption_configuration" {
    for_each = var.encryption_configuration == null ? [] : [var.encryption_configuration]
    content {
      encryption_type = encryption_configuration.value.encryption_type
      kms_key         = encryption_configuration.value.kms_key
    }
  }

  image_scanning_configuration {
    scan_on_push = var.scan_images_on_push
  }

  tags = module.this.tags
}

# Lifecycle Policy ----------------------------------------------


data "aws_ecr_lifecycle_policy_document" "lifecycle_policy" {
  count = module.this.enabled && length(var.lifecycle_rules) > 0 ? 1 : 0
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      priority    = rule.value.priority
      description = rule.value.description
      dynamic "selection" {
        for_each = rule.value.selection
        content {
          tag_status       = selection.value.tag_status
          count_type       = selection.value.count_type
          count_number     = selection.value.count_number
          count_unit       = selection.value.count_unit
          tag_prefix_list  = selection.value.tag_prefix_list
          tag_pattern_list = selection.value.tag_pattern_list
        }
      }
      action {
        type = rule.value.action.type
      }
    }
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  count      = module.this.enabled && length(var.lifecycle_rules) > 0 ? 1 : 0
  repository = one(aws_ecr_repository.this[*].name)

  policy = one(data.aws_ecr_lifecycle_policy_document.lifecycle_policy[*].json)
}

# IAM Policy Document ---------------------------------------------

data "aws_iam_policy_document" "empty" {
  count = module.this.enabled ? 1 : 0
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "resource_readonly_access" {
  count = module.this.enabled ? 1 : 0

  statement {
    sid    = "ReadonlyAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.principals_readonly_access
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
    ]
  }
}

data "aws_iam_policy_document" "resource_pull_through_cache" {
  count = module.this.enabled ? 1 : 0

  statement {
    sid    = "PullThroughAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.principals_pull_though_access
    }

    actions = [
      "ecr:BatchImportUpstreamImage",
      "ecr:TagResource"
    ]
  }
}

data "aws_iam_policy_document" "resource_push_access" {
  count = module.this.enabled ? 1 : 0

  statement {
    sid    = "PushAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.principals_push_access
    }

    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
    ]
  }
}

data "aws_iam_policy_document" "resource_full_access" {
  count = module.this.enabled ? 1 : 0

  statement {
    sid    = "FullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.principals_full_access
    }

    actions = ["ecr:*"]
  }
}

data "aws_iam_policy_document" "lambda_access" {
  count = module.this.enabled && length(var.principals_lambda) > 0 ? 1 : 0

  statement {
    sid    = "LambdaECRImageCrossAccountRetrievalPolicy"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      values   = local.principals_lambda_non_empty ? formatlist("arn:%s:lambda:*:%s:function:*", data.aws_partition.current.partition, var.principals_lambda) : []
      variable = "aws:SourceArn"
    }
  }

  statement {
    sid    = "CrossAccountPermission"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    principals {
      type        = "AWS"
      identifiers = local.principals_lambda_non_empty ? formatlist("arn:%s:iam::%s:root", data.aws_partition.current.partition, var.principals_lambda) : []
    }
  }
}

data "aws_iam_policy_document" "organizations_readonly_access" {
  count = module.this.enabled && length(var.organizations_readonly_access) > 0 ? 1 : 0

  statement {
    sid    = "OrganizationsReadonlyAccess"
    effect = "Allow"

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringEquals"
      values   = var.organizations_readonly_access
      variable = "aws:PrincipalOrgID"
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
    ]
  }
}

data "aws_iam_policy_document" "organization_full_access" {
  count = module.this.enabled && length(var.organizations_full_access) > 0 ? 1 : 0

  statement {
    sid    = "OrganizationsFullAccess"
    effect = "Allow"

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringEquals"
      values   = var.organizations_full_access
      variable = "aws:PrincipalOrgID"
    }

    actions = [
      "ecr:*",
    ]
  }
}

data "aws_iam_policy_document" "organization_push_access" {
  count = module.this.enabled && length(var.organizations_push_access) > 0 ? 1 : 0

  statement {
    sid    = "OrganizationsPushAccess"
    effect = "Allow"

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringEquals"
      values   = var.organizations_push_access
      variable = "aws:PrincipalOrgID"
    }

    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
    ]
  }
}

data "aws_iam_policy_document" "resource" {
  count = local.ecr_need_policy && module.this.enabled ? 1 : 0
  source_policy_documents = local.principals_readonly_access_non_empty ? [
    data.aws_iam_policy_document.resource_readonly_access[0].json
  ] : [data.aws_iam_policy_document.empty[0].json]
  override_policy_documents = distinct([
    local.principals_pull_through_access_non_empty && contains(var.prefixes_pull_through_repositories, regex("^[a-z][a-z0-9\\-\\.\\_]+", var.repository_name)) ? data.aws_iam_policy_document.resource_pull_through_cache[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_push_access_non_empty ? data.aws_iam_policy_document.resource_push_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_full_access_non_empty ? data.aws_iam_policy_document.resource_full_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_lambda_non_empty ? data.aws_iam_policy_document.lambda_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.organizations_full_access_non_empty ? data.aws_iam_policy_document.organization_full_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.organizations_readonly_access_non_empty ? data.aws_iam_policy_document.organizations_readonly_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.organizations_push_non_empty ? data.aws_iam_policy_document.organization_push_access[0].json : data.aws_iam_policy_document.empty[0].json
  ])
}

resource "aws_ecr_repository_policy" "this" {
  count      = local.ecr_need_policy && module.this.enabled ? 1 : 0
  repository = one(aws_ecr_repository.this[*].name)
  policy     = one(data.aws_iam_policy_document.resource[*].json)
}

resource "aws_ecr_replication_configuration" "replication_configuration" {
  count = module.this.enabled && length(var.replication_configurations) > 0 ? 1 : 0
  dynamic "replication_configuration" {
    for_each = var.replication_configurations
    content {
      dynamic "rule" {
        for_each = replication_configuration.value.rules
        content {
          dynamic "destination" {
            for_each = rule.value.destinations
            content {
              region      = destination.value.region
              registry_id = destination.value.registry_id
            }
          }
          dynamic "repository_filter" {
            for_each = rule.value.repository_filters
            content {
              filter      = repository_filter.value.filter
              filter_type = repository_filter.value.filter_type
            }
          }
        }
      }
    }
  }
}
