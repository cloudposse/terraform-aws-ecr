provider "aws" {
  region = "us-east-2"
}

module "ecr" {
  source       = "../../"
  namespace    = "eg"
  stage        = "dev"
  name         = "app"
  use_fullname = false
  image_names  = ["redis", "nginx"]
}
