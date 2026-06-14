resource "aws_dynamodb_table" "items" {
  name         = "${var.project_name}-${var.environment}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Encryption at rest with an AWS-managed KMS key.
  server_side_encryption {
    enabled = true
  }

  # Point-in-time recovery for accidental-delete / corruption protection.
  point_in_time_recovery {
    enabled = true
  }

  # Guard against accidental table destruction in real environments.
  deletion_protection_enabled = var.environment == "prod"
}
