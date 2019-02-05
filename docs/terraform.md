## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `policy` or `role`) | list | `<list>` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage`, etc. | string | `-` | no |
| enabled | Set to false to prevent the module from creating any resources | string | `true` | no |
| max_image_count | How many Docker Image versions AWS ECR will store | string | `7` | no |
| name | The Name of the application or solution  (e.g. `bastion` or `portal`) | string | - | yes |
| namespace | Namespace (e.g. `cp` or `cloudposse`) | string | - | yes |
| principals_full_access | Principal ARN to provide with full access to the ECR | list | `<list>` | no |
| principals_readonly_access | Principal ARN to provide with readonly access to the ECR | list | `<list>` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | - | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')`) | map | `<map>` | no |
| use_fullname | Set 'true' to use `namespace-stage-name` for ecr repository name, else `name` | string | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| registry_id | Registry ID |
| registry_url | Registry URL |
| repository_name | Registry name |

