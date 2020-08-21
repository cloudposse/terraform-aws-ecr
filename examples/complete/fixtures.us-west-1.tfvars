region = "us-west-1"

namespace = "eg"

stage = "test"

name = "ecr-test"

encryption_configuration = {
  encryption_type = "AES256"
  kms_key         = null
}
