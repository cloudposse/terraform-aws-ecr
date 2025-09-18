output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr_with_exclusion_filter.repository_arn
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr_with_exclusion_filter.repository_url
}

output "registry_id" {
  description = "Registry ID of the ECR repository"
  value       = module.ecr_with_exclusion_filter.registry_id
}