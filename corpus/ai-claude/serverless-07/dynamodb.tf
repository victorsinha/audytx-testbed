# DynamoDB table backing the CRUD API.
# - On-demand billing avoids capacity guessing for a new API.
# - SSE with a customer-managed KMS key (least-trust over the AWS-owned default).
# - Point-in-time recovery so a bad write/delete is recoverable.
# - deletion_protection prevents accidental `terraform destroy` data loss.
resource "aws_dynamodb_table" "items" {
  name         = "${local.name_prefix}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  deletion_protection_enabled = true
}

resource "aws_kms_key" "dynamodb" {
  description             = "CMK for ${local.name_prefix} DynamoDB table encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${local.name_prefix}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}
