terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Configure the backend out-of-band (e.g. backend.hcl via -backend-config).
  # The same state bucket is shared; Terraform workspaces keep dev/staging/prod
  # state isolated under env:/<workspace>/ key prefixes.
  backend "s3" {
    key          = "app/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
