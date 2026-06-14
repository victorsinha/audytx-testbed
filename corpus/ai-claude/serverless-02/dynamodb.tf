# DynamoDB table backing the todo store.
# PAY_PER_REQUEST avoids capacity planning for a spiky API workload.
resource "aws_dynamodb_table" "todos" {
  name         = "${var.project_name}-${var.environment}-todos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "todo_id"

  attribute {
    name = "todo_id"
    type = "S"
  }

  # Encrypt at rest with an AWS-managed KMS key.
  server_side_encryption {
    enabled = true
  }

  # Point-in-time recovery for accidental writes/deletes.
  point_in_time_recovery {
    enabled = true
  }
}
