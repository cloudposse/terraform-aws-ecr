provider "aws" {
  region = var.region
}

module "ecr" {
  source = "../../"

  encryption_configuration = var.encryption_configuration

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