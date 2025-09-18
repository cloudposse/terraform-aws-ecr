provider "aws" {
  region = var.region
}

module "ecr" {
  source = "../../"

  encryption_configuration = var.encryption_configuration

  # Example configuration for image tag mutability exclusion filter
  # This allows certain tags to be mutable even when the repository is set to IMMUTABLE
  image_tag_mutability_exclusion_filter = [
    {
      filter      = "dev*"
      filter_type = "tagPrefixList"
    },
    {
      filter      = "test*"
      filter_type = "tagPrefixList"
    },
    {
      filter      = "UNTAGGED"
      filter_type = "tagStatus"
    }
  ]

  context = module.this.context
}

module "scan_config" {
  source = "../../modules/scanning_configuration"
  scan_config = {
    scan_type = "ENHANCED"
    rules = [{
      scan_frequency = "CONTINUOUS_SCAN"
      repository_filter = [{
        filter = "*"
      }]
    }]
  }

  context = module.this.context
}