# Access-log bucket for CloudFront. Created only when logging is enabled for the
# selected environment (prod by default).
resource "aws_s3_bucket" "logs" {
  count = local.cfg.logging_enabled ? 1 : 0

  bucket        = "${local.name_prefix}-logs-${random_id.bucket_suffix.hex}"
  force_destroy = local.cfg.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = local.cfg.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  # CloudFront standard logging writes via ACLs, so ownership must permit them.
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count  = local.cfg.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = local.cfg.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  count  = local.cfg.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Expire logs so the bucket does not grow unbounded.
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = local.cfg.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}
