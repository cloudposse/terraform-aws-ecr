output "arn" {
  value = "${aws_ecr_repository.default.arn}"
}

//
//output "name" {
//  value = "${aws_ecr_repository.default.name}"
//}
//
output "registry_id" {
  value = "${aws_ecr_repository.default.registry_id}"
}

output "repository_url" {
  value = "${aws_ecr_repository.default.repository_url}"
}

output "role_arn" {
  value = "${aws_iam_role.role.arn}"
}

output "role_name" {
  value = "${aws_iam_role.role.name}"
}
