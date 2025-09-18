provider "aws" {
  region = var.region
}

module "ecr_with_exclusion_filter" {
  source = "../../"

  # Set repository to IMMUTABLE
  image_tag_mutability = "IMMUTABLE"

  # Configure exclusion filters to allow certain tags to remain mutable
  image_tag_mutability_exclusion_filter = [
    # Allow development tags to be mutable
    {
      filter      = "dev*"
      filter_type = "tagPrefixList"
    },
    # Allow test tags to be mutable
    {
      filter      = "test*"
      filter_type = "tagPrefixList"
    },
    # Allow staging tags to be mutable
    {
      filter      = "staging*"
      filter_type = "tagPrefixList"
    },
    # Allow untagged images to be mutable
    {
      filter      = "UNTAGGED"
      filter_type = "tagStatus"
    }
  ]

  context = module.this.context
}