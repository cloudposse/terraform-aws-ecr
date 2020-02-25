## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `policy` or `role`) | list(string) | `<list>` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage`, etc. | string | `-` | no |
| enabled | Set to false to prevent the module from creating any resources | bool | `true` | no |
| image_names | List of Docker local image names, used as repository names for AWS ECR | list(string) | `<list>` | no |
| image_tag_mutability | The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE` | string | `MUTABLE` | no |
| max_image_count | How many Docker Image versions AWS ECR will store | string | `500` | no |
| name | The Name of the application or solution  (e.g. `bastion` or `portal`) | string | - | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | string | `` | no |
| principals_full_access | Principal ARNs to provide with full access to the ECR | list(string) | `<list>` | no |
| principals_readonly_access | Principal ARNs to provide with readonly access to the ECR | list(string) | `<list>` | no |
| regex_replace_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | string | `/[^a-zA-Z0-9-]/` | no |
| scan_images_on_push | Indicates whether images are scanned after being pushed to the repository (true) or not (false) | bool | `false` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | `` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')`) | map(string) | `<map>` | no |
| use_fullname | Set 'true' to use `namespace-stage-name` for ecr repository name, else `name` | bool | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| registry_id | Registry ID |
| registry_url | Registry URL |
| repository_arn | Repository ARN |
| repository_arn_map | Map of repository names to repository ARNs |
| repository_id_map | Map of repository names to repository IDs |
| repository_name | Repository name |
| repository_url_map | Map of repository names to repository URLs |

