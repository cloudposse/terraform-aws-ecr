variable "use_fullname" {
  type        = bool
  default     = true
  description = "Set 'true' to use `namespace-stage-name` for ecr repository name, else `name`"
}

variable "principals_full_access" {
  type        = list(string)
  description = "Principal ARNs to provide with full access to the ECR"
  default     = []
}

variable "principals_push_access" {
  type        = list(string)
  description = "Principal ARNs to provide with push access to the ECR"
  default     = []
}

variable "principals_readonly_access" {
  type        = list(string)
  description = "Principal ARNs to provide with readonly access to the ECR"
  default     = []
}

variable "principals_pull_though_access" {
  type        = list(string)
  description = "Principal ARNs to provide with pull though access to the ECR"
  default     = []
}

variable "principals_lambda" {
  type        = list(string)
  description = "Principal account IDs of Lambdas allowed to consume ECR"
  default     = []
}

variable "scan_images_on_push" {
  type        = bool
  description = "Indicates whether images are scanned after being pushed to the repository (true) or not (false)"
  default     = true
}

variable "max_image_count" {
  type        = number
  description = "How many Docker Image versions AWS ECR will store"
  default     = 500
}

variable "time_based_rotation" {
  type        = bool
  description = "Set to true to filter image based on the `sinceImagePushed` count type."
  default     = false
}

variable "image_names" {
  type        = list(string)
  default     = []
  description = "List of Docker local image names, used as repository names for AWS ECR "
}

variable "image_tag_mutability" {
  type        = string
  default     = "IMMUTABLE"
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE`"
}

variable "image_tag_mutability_exclusion_filter" {
  type = list(object({
    filter      = string
    filter_type = optional(string, "WILDCARD")
  }))
  default     = []
  description = "List of exclusion filters for image tag mutability. Each filter object must contain 'filter' and 'filter_type' attributes. Requires AWS provider >= 6.8.0"

  validation {
    condition = alltrue([
      for filter in var.image_tag_mutability_exclusion_filter :
      contains(["WILDCARD"], filter.filter_type)
    ])
    error_message = "filter_type must be `WILDCARD`"
  }

  validation {
    condition = alltrue([
      for filter in var.image_tag_mutability_exclusion_filter :
      length(trimspace(filter.filter)) > 0
    ])
    error_message = "filter value cannot be empty or contain only whitespace."
  }
}

variable "enable_lifecycle_policy" {
  type        = bool
  description = "Set to false to prevent the module from adding any lifecycle policies to any repositories"
  default     = true
}

variable "protected_tags" {
  type        = set(string)
  description = "List of image tags prefixes and wildcards that should not be destroyed. Useful if you tag images with prefixes like `dev`, `staging`, `prod` or wildcards like `*dev`, `*prod`,`*.*.*`"
  default     = []
}

variable "protected_tags_keep_count" {
  type        = number
  description = "Number of Image versions to keep for protected tags"
  default     = 999999
}

variable "encryption_configuration" {
  type = object({
    encryption_type = string
    kms_key         = any
  })
  description = "ECR encryption configuration"
  default     = null
}

variable "force_delete" {
  type        = bool
  description = "Whether to delete the repository even if it contains images"
  default     = false
}

variable "replication_configurations" {
  description = "Replication configuration for a registry. See [Replication Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_replication_configuration#replication-configuration)."
  type = list(object({
    rules = list(object({
      # Maximum 10
      destinations = list(object({
        # Maximum 25
        region      = string
        registry_id = string
      }))
      repository_filters = list(object({
        filter      = string
        filter_type = string
      }))
    }))
  }))
  default = []
}

variable "organizations_readonly_access" {
  type        = list(string)
  description = "Organization IDs to provide with readonly access to the ECR."
  default     = []
}

variable "organizations_full_access" {
  type        = list(string)
  description = "Organization IDs to provide with full access to the ECR."
  default     = []
}

variable "organizations_push_access" {
  type        = list(string)
  description = "Organization IDs to provide with push access to the ECR"
  default     = []
}

variable "prefixes_pull_through_repositories" {
  type        = list(string)
  description = "Organization IDs to provide with push access to the ECR"
  default     = []
}

variable "custom_lifecycle_rules" {
  description = "Custom lifecycle rules to override or complement the default ones"
  type = list(object({
    description = optional(string)
    selection = object({
      tagStatus      = string
      countType      = string
      countNumber    = number
      countUnit      = optional(string)
      tagPrefixList  = optional(list(string))
      tagPatternList = optional(list(string))
    })
    action = object({
      type = string
    })
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.custom_lifecycle_rules :
      rule.selection.tagStatus != "tagged" || (length(coalesce(rule.selection.tagPrefixList, [])) > 0 || length(coalesce(rule.selection.tagPatternList, [])) > 0)
    ])
    error_message = "if tagStatus is tagged - specify tagPrefixList or tagPatternList"
  }
  validation {
    condition = alltrue([
      for rule in var.custom_lifecycle_rules :
      rule.selection.countNumber > 0
    ])
    error_message = "Count number should be > 0"
  }

  validation {
    condition = alltrue([
      for rule in var.custom_lifecycle_rules :
      contains(["tagged", "untagged", "any"], rule.selection.tagStatus)
    ])
    error_message = "Valid values for tagStatus are: tagged, untagged, or any."
  }
  validation {
    condition = alltrue([
      for rule in var.custom_lifecycle_rules :
      contains(["imageCountMoreThan", "sinceImagePushed"], rule.selection.countType)
    ])
    error_message = "Valid values for countType are: imageCountMoreThan or sinceImagePushed."
  }

  validation {
    condition = alltrue([
      for rule in var.custom_lifecycle_rules :
      rule.selection.countType != "sinceImagePushed" || rule.selection.countUnit != null
    ])
    error_message = "For countType = 'sinceImagePushed', countUnit must be specified."
  }
}


variable "default_lifecycle_rules_settings" {
  description = "Default lifecycle rules settings"
  type = object({
    untagged_image_rule = optional(object({
      enabled = optional(bool, true)
      }), {
      enabled = true
    })
    remove_old_image_rule = optional(object({
      enabled = optional(bool, true)
      }), {
      enabled = true
    })
  })
  default = {
    untagged_image_rule = {
      enabled = true
    }
    remove_old_image_rule = {
      enabled = true
    }
  }
}
