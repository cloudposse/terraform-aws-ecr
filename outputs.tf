output "registry_id" {
  value       = join("", aws_ecr_repository.default.*.registry_id)
  description = "Registry ID"
}

output "registry_url" {
  value       = join("", aws_ecr_repository.default.*.repository_url)
  description = "Registry URL"
}

output "repository_name" {
  value       = join("", aws_ecr_repository.default.*.name)
  description = "Repository name"
}

output "repository_arn" {
  value       = join("", aws_ecr_repository.default.*.arn)
  description = "Repository ARN"
}


output "repository_id_map" {
  value       = zipmap(
        aws_ecr_repository.default[*].name
        ,aws_ecr_repository.default[*].registry_id
    )
  description = "Repository id map"
}
output "repository_url_map" {
  value       = zipmap(
        aws_ecr_repository.default[*].name
        ,aws_ecr_repository.default[*].repository_url
    )
  description = "Repository url map"
}