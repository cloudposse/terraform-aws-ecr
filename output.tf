output "arn" {
  value = "${aws_ecr_repository.default.arn}"
}

output "name" {
  value = "${aws_ecr_repository.default.name}"
}

output "registry_id" {
  value = "${aws_ecr_repository.default.registry_id}"
}

output "repository_url" {
  value = "${aws_ecr_repository.default.repository_url}"
}

output "policy.registry_id" {
  value = "${aws_ecr_repository_policy.policy.registry_id}"
}
