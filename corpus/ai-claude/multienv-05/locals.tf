locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Per-environment configuration. The `environment` variable selects which
  # block applies, so a single codebase produces a dev stack and a prod stack.
  env_config = {
    dev = {
      # CloudFront price class: cheapest for non-prod (North America + Europe).
      price_class = "PriceClass_100"
      # Short cache so iteration is fast in dev.
      default_ttl = 300
      max_ttl     = 3600
      min_ttl     = 0
      # Keep dev lean: no extra versioning cost, allow easy teardown.
      versioning_enabled    = false
      force_destroy         = true
      log_retention_enabled = false
      logging_enabled       = false
    }
    prod = {
      # All edge locations worldwide for production.
      price_class = "PriceClass_All"
      # Longer cache in prod.
      default_ttl = 86400
      max_ttl     = 31536000
      min_ttl     = 0
      # Protect prod data: versioning on, never auto-destroy a non-empty bucket.
      versioning_enabled    = true
      force_destroy         = false
      log_retention_enabled = true
      logging_enabled       = true
    }
  }

  cfg = local.env_config[var.environment]

  use_custom_domain = var.domain_name != ""
  aliases           = local.use_custom_domain ? [var.domain_name] : []
}
