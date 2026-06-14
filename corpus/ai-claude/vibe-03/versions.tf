terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # MVP note: using local state. Migrate to an S3 backend with DynamoDB
  # lock table before adding a second engineer / running CI applies.
  # backend "s3" {
  #   bucket         = "REPLACE-tfstate-bucket"
  #   key            = "mvp/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "REPLACE-tfstate-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
