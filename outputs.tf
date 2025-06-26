output "registry_id" {
  value       = module.this.enabled ? aws_ecr_repository.name[local.image_names[0]].registry_id : ""
  description = "Registry ID"
}

output "repository_name" {
  value       = module.this.enabled ? aws_ecr_repository.name[local.image_names[0]].name : ""
  description = "Name of first repository created"
}

output "repository_url" {
  value       = module.this.enabled ? aws_ecr_repository.name[local.image_names[0]].repository_url : ""
  description = "URL of first repository created"
}

output "repository_arn" {
  value       = module.this.enabled ? aws_ecr_repository.name[local.image_names[0]].arn : ""
  description = "ARN of first repository created"
}

output "repository_url_map" {
  value = zipmap(
    values(aws_ecr_repository.name)[*].name,
    values(aws_ecr_repository.name)[*].repository_url
  )
  description = "Map of repository names to repository URLs"
}

output "repository_arn_map" {
  value = zipmap(
    values(aws_ecr_repository.name)[*].name,
    values(aws_ecr_repository.name)[*].arn
  )
  description = "Map of repository names to repository ARNs"
}

output "lifecycle_policy_debug" {
  value = {
    protected_tag_rules = local.protected_tag_rules
    untagged_rule       = local.final_untagged_image_rule
    remove_old          = local.remove_old_image_rule
    custom              = var.custom_lifecycle_rules
    all_rules           = local.all_lifecycle_rules
    normalized          = local.normalized_rules
    final_json = jsonencode({
      rules = [for rule in local.normalized_rules : rule]
    })
  }
}
