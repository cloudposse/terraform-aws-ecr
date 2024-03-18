 locals {
  principals_readonly_access_non_empty = length(var.principals_readonly_access) > 0
  principals_push_access_non_empty     = length(var.principals_push_access) > 0
  principals_full_access_non_empty     = length(var.principals_full_access) > 0
  principals_lambda_non_empty          = length(var.principals_lambda) > 0
  ecr_need_policy                      = length(var.principals_full_access) + length(var.principals_readonly_access) + length(var.principals_push_access) + length(var.principals_lambda) > 0
}

locals {
  _name       = var.use_fullname ? module.this.id : module.this.name
  image_names = length(var.image_names) > 0 ? var.image_names : tomap(local._name)
  repository_creation_enabled = module.this.enabled && var.repository_creation_enabled
}

resource "aws_ecr_repository" "name" {
  for_each             = local.repository_creation_enabled ? local.image_names : {}
  name                 = each.key
  image_tag_mutability = var.image_tag_mutability
  force_delete         = each.value.force_delete_override

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
  untagged_image_rule = [{
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
  }]

  remove_old_image_rule = [{
    rulePriority = length(var.protected_tags) + 2
    description  = "Rotate images when reach ${var.max_image_count} images stored",
    selection = {
      tagStatus   = "any"
      countType   = "imageCountMoreThan"
      countNumber = var.max_image_count
    }
    action = {
      type = "expire"
    }
  }]

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

  archive_remove_all_rule = [{
    rulePriority = 2
    description  = "Remove all images for archived repos"
    selection = {
      tagStatus   = "any"
      countType   = "imageCountMoreThan"
      countNumber = 1
    }
    action = {
      type = "expire"
    }
  }]

  archive_protected_tag_rules = [
    
    {
      rulePriority = 1
      description  = "Protects archived repo release images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["*.*.*"]
        countType     = "imageCountMoreThan"
        countNumber   = 999999
      }
      action = {
        type = "expire"
      }
    }
  ]

  lifecycle_policy_default = jsonencode({
    rules = concat(local.protected_tag_rules, local.untagged_image_rule, local.remove_old_image_rule)
  })

  lifecycle_policy_archive = jsonencode({
    rules = concat(local.archive_protected_tag_rules, local.archive_remove_all_rule)
  })
}

resource "aws_ecr_lifecycle_policy" "name" {
  for_each   = local.repository_creation_enabled && var.enable_lifecycle_policy ? local.image_names : {}
  repository = aws_ecr_repository.name[each.key].name

  policy = each.value.archive_enabled ? local.lifecycle_policy_archive : local.lifecycle_policy_default
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

data "aws_iam_policy_document" "resource" {
  count                   = module.this.enabled ? 1 : 0
  source_policy_documents = local.principals_readonly_access_non_empty ? [data.aws_iam_policy_document.resource_readonly_access[0].json] : [data.aws_iam_policy_document.empty[0].json]
  override_policy_documents = distinct([
    local.principals_push_access_non_empty ? data.aws_iam_policy_document.resource_push_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_full_access_non_empty ? data.aws_iam_policy_document.resource_full_access[0].json : data.aws_iam_policy_document.empty[0].json,
    local.principals_lambda_non_empty ? data.aws_iam_policy_document.lambda_access[0].json : data.aws_iam_policy_document.empty[0].json,
  ])
}

resource "aws_ecr_repository_policy" "name" {
  for_each   = local.ecr_need_policy && module.this.enabled ? local.image_names : {}
  repository = each.key
  policy     = join("", data.aws_iam_policy_document.resource[*].json)
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_replication_configuration" "same_account_cross_region" {
  count = local.repository_creation_enabled && length(var.replication_regions) > 0 ? 1 : 0

  replication_configuration {
    dynamic "rule" {
      for_each = var.replication_regions
      content {
        destination {
          region      = rule.value
          registry_id = data.aws_caller_identity.current.account_id
        }
      }
    }
  }
}
