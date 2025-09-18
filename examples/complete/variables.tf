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
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE`"
  default     = "MUTABLE"
}

variable "image_tag_mutability_exclusion_filter" {
  type = list(object({
    filter      = string
    filter_type = string
  }))
  default = []
}
