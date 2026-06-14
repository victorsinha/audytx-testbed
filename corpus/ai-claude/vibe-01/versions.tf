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

  # Configure remote state for team use. Replace bucket/table with your own,
  # or remove this block to use local state.
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "app-backend/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "my-tf-state-locks"
  #   encrypt        = true
  # }
}
