# Single-table store the Lambda functions read from and write to.
# PAY_PER_REQUEST avoids idle provisioned-capacity cost for a spiky API workload.
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

  # Recover from accidental deletes/writes within the retention window.
  point_in_time_recovery {
    enabled = true
  }
}
