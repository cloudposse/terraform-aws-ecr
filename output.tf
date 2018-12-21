output "registry_id" {
  value       = "${aws_ecr_repository.default.registry_id}"
  description = "Registry ID"
}

output "registry_url" {
  value       = "${aws_ecr_repository.default.repository_url}"
  description = "Registry URL"
}

output "repository_name" {
  value       = "${aws_ecr_repository.default.name}"
  description = "Registry name"
}

output "role_name" {
  value       = "${join("", aws_iam_role.default.*.name)}"
  description = "Assume Role name to get registry access"
}

output "role_arn" {
  value       = "${join("", aws_iam_role.default.*.arn)}"
  description = "Assume Role ARN to get registry access"
}
