terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront ACM certificates must live in us-east-1, regardless of where the
# rest of the infrastructure is deployed.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

locals {
  # Use the custom domain as the bucket-name seed when provided, otherwise the
  # project name. A random suffix guarantees global S3 uniqueness.
  bucket_seed = var.domain_name != "" ? var.domain_name : var.project_name

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
