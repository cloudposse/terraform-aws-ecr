output "registry_id" {
  value       = module.this.enabled ? aws_ecr_repository.this[0].registry_id : ""
  description = "Registry ID"
}

output "repository_name" {
  value       = module.this.enabled ? aws_ecr_repository.this[0].name : ""
  description = "Name of first repository created"
}

output "repository_url" {
  value       = module.this.enabled ? aws_ecr_repository.this[0].repository_url : ""
  description = "URL of first repository created"
}

output "repository_arn" {
  value       = module.this.enabled ? aws_ecr_repository.this[0].arn : ""
  description = "ARN of first repository created"
}
