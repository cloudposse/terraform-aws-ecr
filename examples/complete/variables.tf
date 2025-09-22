variable "region" {
  type        = string
  description = "AWS region"
}

variable "encryption_configuration" {
  type = object({
    encryption_type = string
    kms_key         = any
  })
  description = "ECR encryption configuration"
  default     = null
}

variable "image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE`, `IMMUTABLE`, `IMMUTABLE_WITH_EXCLUSION`, or `MUTABLE_WITH_EXCLUSION`. Defaults to `IMMUTABLE`"
  default     = "IMMUTABLE"
}

variable "image_tag_mutability_exclusion_filter" {
  description = "List of exclusion filters for image tag mutability. Each filter object must contain 'filter' and 'filter_type' attributes. Requires AWS provider >= 6.8.0"
  type = list(object({
    filter      = string
    filter_type = optional(string, "WILDCARD")
  }))
  default = []
}

variable "enable_scanning" {
  type        = bool
  description = "Set to true to enable scanning for the repository"
  default     = false
}
