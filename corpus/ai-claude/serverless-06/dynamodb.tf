# DynamoDB table storing image metadata, keyed by image id.
resource "aws_dynamodb_table" "metadata" {
  name         = "${local.name_prefix}-image-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_id"

  attribute {
    name = "image_id"
    type = "S"
  }

  # Encrypt at rest with the customer-managed KMS key.
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  # Recover from accidental writes/deletes within the last 35 days.
  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  deletion_protection_enabled = true
}
