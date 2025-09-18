provider "aws" {
  region = var.region
}

module "ecr" {
  source = "../../"

  encryption_configuration = var.encryption_configuration

  # Example of using image tag mutability exclusion filters
  # This allows 'latest' and 'dev-*' tags to be mutable while keeping others immutable
  image_tag_mutability = "IMMUTABLE"
  image_tag_mutability_exclusion_filter = [
    {
      filter      = "latest"
      filter_type = "WILDCARD"
    },
    {
      filter      = "dev-"
      filter_type = "WILDCARD"
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
