locals {
  # Resolve the configuration block for the selected environment.
  config = var.env_config[var.environment]

  name_prefix = "${var.project}-${var.environment}"
}
