output "registry_id" {
  value = "${aws_ecr_repository.default.registry_id}"
}

output "registry_url" {
  value = "${aws_ecr_repository.default.repository_url}"
}

output "role_name" {
  value = "${aws_iam_role.default.name}"
}
