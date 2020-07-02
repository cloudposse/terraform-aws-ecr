output "repository_id" {
  value       = module.ecr.repository_id
  description = "repository ID"
}

output "repository_url" {
  value       = module.ecr.repository_url
  description = "Repository URL"
}

output "repository_name" {
  value       = module.ecr.repository_name
  description = "repository name"
}
