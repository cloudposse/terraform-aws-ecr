enabled = true

region = "us-east-2"

namespace = "eg"

stage = "test"

name = "ecr-test"

encryption_configuration = {
  encryption_type = "AES256"
  kms_key         = null
}

image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"
image_tag_mutability_exclusion_filter = [
  {
    filter = "latest"
  },
  {
    filter      = "dev-"
    filter_type = "WILDCARD"
  }
]
