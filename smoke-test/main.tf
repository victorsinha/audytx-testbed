# FIXTURE — NOT PRODUCTION CODE.
#
# Minimal smoke test. One public S3 bucket with no
# aws_s3_bucket_public_access_block declared anywhere. We expect
# audytx to flag this on the PR comment.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# A bucket intended to be public but with no companion PAB resource —
# the classic AWS_S3_* trigger. The bucket itself has no ACL declared
# (uses the AWS default), but the absence of a public_access_block
# resource is the engine's signal.
resource "aws_s3_bucket" "smoke_test_public" {
  bucket = "audytx-testbed-smoke-public"

  tags = {
    Name        = "smoke-test-public"
    Environment = "test"
    Owner       = "audytx-testbed"
  }
}
