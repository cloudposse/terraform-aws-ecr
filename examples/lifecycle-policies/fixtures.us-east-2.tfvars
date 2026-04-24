enabled = true

region = "us-east-2"

namespace = "eg"

stage = "test"

name = "ecr-lifecycle"

encryption_configuration = {
  encryption_type = "AES256"
  kms_key         = null
}
