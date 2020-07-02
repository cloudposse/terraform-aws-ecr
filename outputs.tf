# Changing output names can lead to downstream module issues
output "registry_id" {
  value       = var.enabled ? aws_ecr_registry.name[local.image_names[0]].registry_id : ""
  description = "Registry ID"
}

output "registry_name" {
  value       = var.enabled ? aws_ecr_registry.name[local.image_names[0]].name : ""
  description = "Name of first registry created"
}

output "registry_url" {
  value       = var.enabled ? aws_ecr_registry.name[local.image_names[0]].registry_url : ""
  description = "URL of first registry created"
}

output "registry_arn" {
  value       = var.enabled ? aws_ecr_registry.name[local.image_names[0]].arn : ""
  description = "ARN of first registry created"
}

output "registry_url_map" {
  value = zipmap(
    values(aws_ecr_registry.name)[*].name,
    values(aws_ecr_registry.name)[*].registry_url
  )
  description = "Map of registry names to registry URLs"
}

output "registry_arn_map" {
  value = zipmap(
    values(aws_ecr_registry.name)[*].name,
    values(aws_ecr_registry.name)[*].arn
  )
  description = "Map of registry names to registry ARNs"
}
