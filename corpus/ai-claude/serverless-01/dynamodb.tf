resource "aws_dynamodb_table" "items" {
  name         = "${var.project_name}-${var.environment}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Encryption at rest with the customer-managed CMK.
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.this.arn
  }

  # Point-in-time recovery so a bad write/delete is recoverable.
  point_in_time_recovery {
    enabled = true
  }

  # Guards against `terraform destroy` wiping the table in prod.
  deletion_protection_enabled = var.environment == "prod"
}
