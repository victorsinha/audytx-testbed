locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Per-environment defaults. Values here win unless explicitly overridden
  # via the corresponding *.tfvars file.
  env_defaults = {
    dev = {
      instance_type      = "t3.small"
      instance_count     = 1
      multi_az           = false
      deletion_protected = false
    }
    prod = {
      instance_type      = "t3.large"
      instance_count     = 2
      multi_az           = true
      deletion_protected = true
    }
  }

  selected = local.env_defaults[var.environment]

  # AZ list scoped to multi-AZ for prod, single-AZ for dev.
  azs = slice(data.aws_availability_zones.available.names, 0, local.selected.multi_az ? 2 : 1)
}
