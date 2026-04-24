module "ecr" {
  source = "../../"

  encryption_configuration = var.encryption_configuration

  image_tag_mutability                  = var.image_tag_mutability
  image_tag_mutability_exclusion_filter = var.image_tag_mutability_exclusion_filter

  custom_lifecycle_rules = [
    # Regression: issue #158 — tagged + tagPatternList + expire, no storageClass.
    # v1.0.1 rendered storageClass="standard" and targetStorageClass=null, which ECR rejected.
    {
      description = "Keep only last 10 images tagged 'latest'"
      selection = {
        tagStatus      = "tagged"
        tagPatternList = ["latest"]
        countType      = "imageCountMoreThan"
        countNumber    = 10
      }
      action = {
        type = "expire"
      }
    },
    # Regression: companion case with tagPrefixList.
    {
      description = "Keep only last 5 images with 'release-' prefix"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["release-"]
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    },
    # Feature (v1.0.1): transition old tagged images to the archive storage class.
    {
      description = "Archive tagged images older than 30 days"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "sinceImagePushed"
        countUnit     = "days"
        countNumber   = 30
      }
      action = {
        type               = "transition"
        targetStorageClass = "archive"
      }
    },
    # Feature (v1.0.1): expire from archive storage class. ECR only accepts
    # countType=sinceImageTransitioned when selection.storageClass=archive,
    # and enforces a 90-day minimum before archived images can be deleted.
    {
      description = "Expire images that have been archived for more than 90 days"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        storageClass  = "archive"
        countType     = "sinceImageTransitioned"
        countUnit     = "days"
        countNumber   = 90
      }
      action = {
        type = "expire"
      }
    },
  ]

  context = module.this.context
}
