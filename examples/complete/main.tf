provider "aws" {
  region = var.region
}

module "ecr" {
  source = "../../"

  encryption_configuration = var.encryption_configuration

  image_tag_mutability                  = var.image_tag_mutability
  image_tag_mutability_exclusion_filter = var.image_tag_mutability_exclusion_filter

  context = module.this.context
}

module "scan_config" {
  enabled = var.enable_scanning
  source  = "../../modules/scanning_configuration"
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
