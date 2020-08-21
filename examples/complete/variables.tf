variable "region" {
  type = string
}

variable "namespace" {
  type = string
}

variable "name" {
  type = string
}

variable "stage" {
  type = string
}

variable "encryption_configuration" {
  type = object({
    encryption_type = string
    kms_key         = any
  })
  description = "ECR encryption configuration"
  default     = null
}
