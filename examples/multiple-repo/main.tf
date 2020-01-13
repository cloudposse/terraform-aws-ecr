provider "aws" {
  region = var.region
}

module "ecr" {
  source    = "../../"
  namespace = "eg"
  stage     = "dev"
  name      = "app"
  use_fullname = false
  list_image = ["redis", "nginx"]
}
