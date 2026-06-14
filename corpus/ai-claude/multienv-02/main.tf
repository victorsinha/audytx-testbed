# ---------------------------------------------------------------------------
# Workspace-driven configuration.
# terraform.workspace is one of: dev | staging | prod.
# All sizing/posture is resolved from var.env_settings via this single lookup,
# so the exact same configuration deploys to every environment.
# ---------------------------------------------------------------------------
locals {
  env  = terraform.workspace
  cfg  = var.env_settings[local.env]
  name = "${var.project_name}-${local.env}"

  vpc_cidr = var.vpc_cidr_by_env[local.env]

  # Carve /20 subnets out of the /16: first az_count for public, next for private.
  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(local.vpc_cidr, 4, i)]
  private_subnets = [for i in range(var.az_count) : cidrsubnet(local.vpc_cidr, 4, i + var.az_count)]
}

data "aws_availability_zones" "available" {
  state = "available"
}
