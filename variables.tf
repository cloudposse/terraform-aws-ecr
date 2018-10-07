variable "name" {
  description = "The Name of the application or solution  (e.g. `bastion` or `portal`)"
}

variable "namespace" {
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "stage" {
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "use_fullname" {
  type        = "string"
  default     = "true"
  description = "Set 'true' to use `namespace-stage-name` for ecr repository name, else `name`"
}

variable "roles" {
  type        = "list"
  description = "Principal IAM roles to provide with access to the ECR"
  default     = []
}

variable "delimiter" {
  type        = "string"
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = "list"
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`)"
}

variable "max_image_count" {
  type        = "string"
  description = "How many Docker Image versions AWS ECR will store"
  default     = "7"
}
