provider "aws" {
  region = var.region
}

module "ecr" {
  source                   = "../../"
  namespace                = var.namespace
  stage                    = var.stage
  name                     = var.name
  encryption_configuration = var.encryption_configuration
}
