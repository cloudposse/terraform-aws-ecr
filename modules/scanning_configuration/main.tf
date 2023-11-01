
resource "aws_ecr_registry_scanning_configuration" "default" {
  count     = module.this.enabled && var.scan_config != null ? 1 : 0
  scan_type = var.scan_config.scan_type

  dynamic "rule" {
    for_each = var.scan_config.rules
    content {
      scan_frequency = rule.value.scan_frequency
      dynamic "repository_filter" {
        for_each = rule.value.repository_filter
        content {
          filter      = repository_filter.value.filter
          filter_type = repository_filter.value.filter_type
        }
      }
    }
  }
}
