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

locals {
  _name       = var.use_fullname ? module.this.id : module.this.name
  image_names = length(var.image_names) > 0 ? var.image_names : [local._name]
}

resource "aws_ecr_repository" "name" {
  for_each             = toset(module.this.enabled ? local.image_names : [])
  name                 = each.value
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

locals {
  untagged_image_rule = [
    {
      rulePriority = length(var.protected_tags) + 1
      description  = "Remove untagged images"
      selection = {
        tagStatus   = "untagged"
        countType   = "imageCountMoreThan"
        countNumber = 1
      }
      action = {
        type = "expire"
      }
    }
  ]

  remove_old_image_rule = [
    {
      rulePriority = length(var.protected_tags) + 2
      description  = (
        var.time_based_rotation ?
          "Rotate images older than ${var.max_image_count} days" :
          "Rotate images when reach ${var.max_image_count} images stored"
        )
      selection = {
        tagStatus   = "any"
        countType   = (
          var.time_based_rotation ?
            "sinceImagePushed" :
            "imageCountMoreThan"
          )
        countUnit   = (
          var.time_based_rotation ?
            "days" :
            null
          )
        countNumber = var.max_image_count
      }
      action = {
        type = "expire"
      }
    }
  ]

  protected_tag_rules = [
    for index, tagPrefix in zipmap(range(length(var.protected_tags)), tolist(var.protected_tags)) :
    {
      rulePriority = tonumber(index) + 1
      description  = "Protects images tagged with ${tagPrefix}"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = [tagPrefix]
        countType     = "imageCountMoreThan"
        countNumber   = 999999
      }
      action = {
        type = "expire"
      }
    }
  ]
}

resource "aws_ecr_lifecycle_policy" "name" {
  for_each   = toset(module.this.enabled && var.enable_lifecycle_policy ? local.image_names : [])
  repository = aws_ecr_repository.name[each.value].name

  policy = jsonencode({
    rules = concat(local.protected_tag_rules, local.untagged_image_rule, local.remove_old_image_rule)
  })
}

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
  for_each = toset(local.ecr_need_policy && module.this.enabled ? local.image_names : [])
  source_policy_documents = local.principals_readonly_access_non_empty ? [
    data.aws_iam_policy_document.resource_readonly_access[0].json
  ] : [data.aws_iam_policy_document.empty[0].json]
  override_policy_documents = distinct([
    local.principals_pull_through_access_non_empty && contains(var.prefixes_pull_through_repositories, regex("^[a-z][a-z0-9\\-\\.\\_]+", each.value)) ? data.aws_iam_policy_document.resource_pull_through_cache[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_push_access_non_empty ? data.aws_iam_policy_document.resource_push_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_full_access_non_empty ? data.aws_iam_policy_document.resource_full_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_lambda_non_empty ? data.aws_iam_policy_document.lambda_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.organizations_full_access_non_empty ? data.aws_iam_policy_document.organization_full_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.organizations_readonly_access_non_empty ? data.aws_iam_policy_document.organizations_readonly_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.organizations_push_non_empty ? data.aws_iam_policy_document.organization_push_access[0].json : data.aws_iam_policy_document.empty[0].json
  ])
}

resource "aws_ecr_repository_policy" "name" {
  for_each   = toset(local.ecr_need_policy && module.this.enabled ? local.image_names : [])
  repository = aws_ecr_repository.name[each.value].name
  policy     = data.aws_iam_policy_document.resource[each.value].json
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
