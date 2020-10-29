terraform {
  required_version = ">= 0.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.1"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 1.3"
    }
  }
}
