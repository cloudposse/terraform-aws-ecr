
terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.8.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "ecr" {
  source = "../../"
  name = "test-lifecycle-policies"

  encryption_configuration = var.encryption_configuration

  image_tag_mutability                  = var.image_tag_mutability
  image_tag_mutability_exclusion_filter = var.image_tag_mutability_exclusion_filter
  custom_lifecycle_rules = [
    {
      description   = "Expire untagged images older than 30 days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 30
      }
      action = {
        type = "transition"
        targetStorageClass = "archive"
      }
    }
  ]
}
