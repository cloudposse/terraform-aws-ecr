output "registry_id" {
  value       = local.repository_creation_enabled ? aws_ecr_repository.name[keys(local.image_names)[0]].registry_id : ""
  description = "Registry ID"
}

output "repository_name" {
  value       = local.repository_creation_enabled ? aws_ecr_repository.name[keys(local.image_names)[0]].name : ""
  description = "Name of first repository created"
}

output "repository_url" {
  value       = local.repository_creation_enabled ? aws_ecr_repository.name[keys(local.image_names)[0]].repository_url : ""
  description = "URL of first repository created"
}

output "repository_arn" {
  value       = local.repository_creation_enabled ? aws_ecr_repository.name[keys(local.image_names)[0]].arn : ""
  description = "ARN of first repository created"
}

output "repository_url_map" {
  value = local.repository_creation_enabled ? zipmap(
    values(aws_ecr_repository.name)[*].name,
    values(aws_ecr_repository.name)[*].repository_url
  ) : {}
  description = "Map of repository names to repository URLs"
}

output "repository_arn_map" {
  value = local.repository_creation_enabled ? zipmap(
    values(aws_ecr_repository.name)[*].name,
    values(aws_ecr_repository.name)[*].arn
  ) : {}
  description = "Map of repository names to repository ARNs"
}
