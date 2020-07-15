## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.0, < 0.14.0 |
| aws | ~> 2.34 |
| local | ~> 1.2 |
| template | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.34 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| attributes | Additional attributes (e.g. `policy` or `role`) | `list(string)` | `[]` | no |
| delimiter | Delimiter to be used between `name`, `namespace`, `stage`, etc. | `string` | `"-"` | no |
| enable\_lifecycle\_policy | Set to false to prevent the module from adding any lifecycle policies to any repositories | `bool` | `true` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | `string` | `""` | no |
| image\_names | List of Docker local image names, used as repository names for AWS ECR | `list(string)` | `[]` | no |
| image\_tag\_mutability | The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE` | `string` | `"MUTABLE"` | no |
| max\_image\_count | How many Docker Image versions AWS ECR will store | `number` | `500` | no |
| name | The Name of the application or solution  (e.g. `bastion` or `portal`) | `string` | n/a | yes |
| namespace | Namespace (e.g. `eg` or `cp`) | `string` | `""` | no |
| principals\_full\_access | Principal ARNs to provide with full access to the ECR | `list(string)` | `[]` | no |
| principals\_readonly\_access | Principal ARNs to provide with readonly access to the ECR | `list(string)` | `[]` | no |
| protected\_tags | Name of image tags prefixes that should not be destroyed. Useful if you tag images with names like `dev`, `staging`, and `prod` | `set(string)` | `[]` | no |
| regex\_replace\_chars | Regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only letters, digits, dash, slash, and underscore are allowed, all other chars are removed | `string` | `"/[^a-z/A-Z_0-9-]/"` | no |
| scan\_images\_on\_push | Indicates whether images are scanned after being pushed to the repository (true) or not (false) | `bool` | `false` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | `string` | `""` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')`) | `map(string)` | `{}` | no |
| use\_fullname | Set 'true' to use `namespace-stage-name` for ecr repository name, else `name` | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| registry\_id | Registry ID |
| repository\_arn | ARN of first repository created |
| repository\_arn\_map | Map of repository names to repository ARNs |
| repository\_name | Name of first repository created |
| repository\_url | URL of first repository created |
| repository\_url\_map | Map of repository names to repository URLs |

