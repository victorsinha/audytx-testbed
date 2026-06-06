# Smoke test: intentionally misconfigured S3 bucket
# Purpose: validate that audytx posts a PR comment at all (webhook → comment path)

resource "aws_s3_bucket" "public_data" {
  bucket = "audytx-smoke-test-public"
}

resource "aws_s3_bucket_acl" "public_data" {
  bucket = aws_s3_bucket.public_data.id
  acl    = "public-read"
}

resource "aws_s3_bucket_public_access_block" "public_data" {
  bucket = aws_s3_bucket.public_data.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
