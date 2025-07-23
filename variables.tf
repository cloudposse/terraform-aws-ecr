variable "repository_name" {
  type        = string
  description = "Name of the ECR repository to create"
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

variable "image_tag_mutability" {
  type        = string
  default     = "IMMUTABLE"
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE`"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Valid values for image_tag_mutability are: MUTABLE or IMMUTABLE."
  }
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

variable "lifecycle_rules" {
  description = "Custom lifecycle rules to override or complement the default ones"
  type = list(object({
    priority    = number
    description = optional(string)
    selection = list(object({
      tag_status       = string
      count_type       = string
      count_number     = number
      count_unit       = optional(string)
      tag_pattern_list = optional(list(string))
      tag_prefix_list  = optional(list(string))
    }))
    action = object({
      type = string
    })
  }))
  default = []

  validation {
    condition = alltrue(flatten([
      for rule in var.lifecycle_rules :
      [for selection in rule.selection :
      contains(["tagged", "untagged", "any"], selection.tag_status)]
    ]))
    error_message = "Valid values for tag_status are: tagged, untagged, or any."
  }
  validation {
    condition = alltrue(flatten([
      for rule in var.lifecycle_rules :
      [for selection in rule.selection :
      contains(["imageCountMoreThan", "sinceImagePushed"], selection.count_type)]
    ]))
    error_message = "Valid values for count_type are: imageCountMoreThan or sinceImagePushed."
  }
  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules :
      contains(["expire"], rule.action.type)
    ])
    error_message = "Valid values for action.type are: expire."
  }
}
