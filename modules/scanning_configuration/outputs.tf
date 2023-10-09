output "configuration" {
  description = "The ECR registry scanning configuration"
  value       = aws_ecr_registry_scanning_configuration.default[*]
}