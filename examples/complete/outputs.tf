output "repository_id" {
  value       = module.ecr.registry_id
  description = "Repository ID"
}

output "repository_url" {
  value       = module.ecr.repository_url
  description = "Repository URL"
}

output "repository_name" {
  value       = module.ecr.repository_name
  description = "Repository name"
}
