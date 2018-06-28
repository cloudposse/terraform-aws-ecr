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
  description = "Assume Role name to get access registry"
}

output "role_arn" {
  value       = "${join("", aws_iam_role.default.*.arn)}"
  description = "Assume Role ARN to get access registry"
}

output "policy_login_name" {
  value       = "${aws_iam_policy.login.name}"
  description = "IAM Policy name allow to login in ECR"
}

output "policy_login_arn" {
  value       = "${aws_iam_policy.login.arn}"
  description = "IAM Policy ARN allow to login in ECR"
}

output "policy_read_name" {
  value       = "${aws_iam_policy.read.name}"
  description = "IAM Policy name allow to pull images from ECR"
}

output "policy_read_arn" {
  value       = "${aws_iam_policy.read.arn}"
  description = "IAM Policy ARN allow to pull images from ECR"
}

output "policy_write_name" {
  value       = "${aws_iam_policy.write.name}"
  description = "IAM Policy name allow to push images to ECR"
}

output "policy_write_arn" {
  value       = "${aws_iam_policy.write.arn}"
  description = "IAM Policy ARN allow to push images to ECR"
}
