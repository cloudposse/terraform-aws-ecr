
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `policy` or `role`) | list | `<list>` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage`, etc. | string | `-` | no |
| max_image_count | How many Docker Image versions AWS ECR will store | string | `7` | no |
| name | The Name of the application or solution  (e.g. `bastion` or `portal`) | string | - | yes |
| namespace | Namespace (e.g. `cp` or `cloudposse`) | string | - | yes |
| roles | Principal IAM roles to provide with access to the ECR | list | `<list>` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | - | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')`) | map | `<map>` | no |
| use_fullname | Set 'true' to use `cp-prod-bastion_image` for ecr repository name, else `bastion_image` | string | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_login_arn | The IAM Policy ARN to be given access to login in ECR |
| policy_login_name | The IAM Policy name to be given access to login in ECR |
| policy_read_arn | The IAM Policy ARN to be given access to pull images from ECR |
| policy_read_name | The IAM Policy name to be given access to pull images from ECR |
| policy_write_arn | The IAM Policy ARN to be given access to push images to ECR |
| policy_write_name | The IAM Policy name to be given access to push images to ECR |
| registry_id | Registry ID |
| registry_url | Registry URL |
| repository_name | Registry name |
| role_arn | Assume Role ARN to get registry access |
| role_name | Assume Role name to get registry access |

