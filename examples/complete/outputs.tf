output "registry_id" {
  value       = module.ecr.registry_id
  description = "Registry ID"
}

output "registry_url" {
  value       = module.ecr.repository_url
  description = "Repository URL"
}

output "repository_name" {
  value       = module.ecr.repository_name
  description = "Registry name"
}
