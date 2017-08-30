# tf_ecr
The module creates a Docker Container registry using AWS ECR

## Usage

Note: You should setting the IAM role names for registry access as a module variable `roles`.

Include this repository as a module in your existing terraform code:
```
data "aws_iam_role" "ecr" {
  name = "ecr"
}

module "ecr" {
  source              = "git::https://github.com/cloudposse/tf_ecr.git?ref=tags/0.1.0"
  name                = "${var.name}"
  namespace           = "${var.namespace}"
  stage               = "${var.stage}"
  roles               = ["${data.aws_iam_role.ecr.name}"]
}
```

This will create a `registry`


## Variables

|  Name                        |  Default       |  Description                                                                                             | Required|
|:----------------------------:|:--------------:|:--------------------------------------------------------------------------------------------------------:|:-------:|
| `namespace`                  | `global`       | Namespace (e.g. `cp` or `cloudposse`) - required for `tf_label` module                                   | Yes     |
| `stage`                      | `default`      | Stage (e.g. `prod`, `dev`, `staging` - required for `tf_label` module                                    | Yes     |
| `name`                       | `admin`        | Name  (e.g. `bastion` or `db`) - required for `tf_label` module                                          | Yes     |
| `roles`                      | []             | List of IAM role names of principals allowed to use the container registry (users, groups, Roles)              | Yes     |

## Outputs

| Name                | Decription                                                                              |
|:-------------------:|:---------------------------------------------------------------------------------------:|
| `registry_id`       | ID of the new AWS Container Registry                                                    |
| `registry_url`      | URL to the new AWS Container Registry                                                   |
| `role_name`         | The name of IAM role that has access to the registry                                    |
