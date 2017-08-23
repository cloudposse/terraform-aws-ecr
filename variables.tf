variable "name" {
  description = "Name of the repository"
  default     = ""
}

variable "namespace" {
  default = ""
}

variable "stage" {
  default = ""
}

variable "node_arns" {
  type = "list"
  description = "Principal ARN of EC2 node to provide with access to the ECR"
  default     = []
}

variable "user_arns" {
  type = "list"
  description = "Principal ARN of users to provide with access to the ECR"
  default     = []
}

