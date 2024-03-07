provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}

module "ecr" {
  source       = "../../"
  namespace    = "eg"
  stage        = "dev"
  name         = "app"
  use_fullname = false
  image_names  = ["redis"]

  replication_configurations = [
    {
      rules = [
        {
          destinations = [
            {
              region      = "us-east-1"
              registry_id = data.aws_caller_identity.current.account_id
            },
            {
              region      = "eu-west-1"
              registry_id = data.aws_caller_identity.current.account_id
            }
          ]
          repository_filters = [
            {
              filter      = "redis"
              filter_type = "PREFIX_MATCH"
            }
          ]
        }
      ]
    }
  ]
}
