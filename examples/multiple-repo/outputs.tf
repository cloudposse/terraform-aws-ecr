output "repository_id_map" {
  value       = module.ecr.repository_arn_map
  description = "Repository id map"
}

output "repository_url_map" {
  value       = module.ecr.repository_url_map
  description = "Repository url map"
}
