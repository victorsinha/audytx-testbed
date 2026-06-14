terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = var.region
}

# CloudFront default certificate and many CloudFront-fronted ACM certs must live
# in us-east-1. Aliased provider kept available for future custom-domain wiring.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
