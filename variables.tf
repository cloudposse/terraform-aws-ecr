variable "name" {}

variable "namespace" {}

variable "stage" {}

variable "roles" {
  type        = "list"
  description = "Principal IAM roles to provide with access to the ECR"
  default     = []
}

variable "delimiter" {
  type    = "string"
  default = "-"
}

variable "attributes" {
  type    = "list"
  default = []
}

variable "tags" {
  type    = "map"
  default = {}
}

variable "max_tagged_image_count" {
  type        = "string"
  description = "How many tagged Docker Image versions AWS ECR will store"
  default     = "0"
}

variable "max_untagged_image_days" {
  type        = "string"
  description = "Number of days that ECR will store untagged Docker Image versions"
  default     = "0"
}

var
