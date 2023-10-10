variable "scan_config" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration
  description = "Scan configuration for ECR"
  type = object({
    scan_type = string
    rules = list(object({
      scan_frequency = string
      repository_filter = list(object({
        filter      = string
        filter_type = optional(string, "WILDCARD")
      }))
    }))
  })
  validation {
    condition     = var.scan_config == null || contains(["ENHANCED", "BASIC"], var.scan_config.scan_type)
    error_message = "scan_type must be either ENHANCED or BASIC"
  }
  # validate scan_frequency is set to SCAN_ON_PUSH, MANUAL, or CONTINUOUS_SCAN
  validation {
    condition     = var.scan_config == null || alltrue([for rule in var.scan_config.rules : contains(["SCAN_ON_PUSH", "MANUAL", "CONTINUOUS_SCAN"], rule.scan_frequency)])
    error_message = "scan_frequency must be either SCAN_ON_PUSH, MANUAL, or CONTINUOUS_SCAN"
  }
  default = null
}
