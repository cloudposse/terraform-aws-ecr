provider "aws" {
  region = var.region
}

module "ecr" {
  source    = "../../"
  namespace = var.namespace
  stage     = var.stage
  name      = var.name
}
