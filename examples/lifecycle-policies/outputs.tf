output "repository_name" {
  value       = module.ecr.repository_name
  description = "Repository name"
}

output "lifecycle_policy_json" {
  value       = module.ecr.lifecycle_policy_json
  description = "JSON-encoded ECR lifecycle policy applied to the repository"
}
