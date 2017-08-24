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

variable "principals" {
  type        = "list"
  description = "Principal ARNs to provide with access to the ECR"
  default     = []
}
