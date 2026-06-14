# Customer-managed CMK for encrypting CloudWatch Logs, DynamoDB, and SQS.
# Avoids relying on AWS-managed keys so key policy + rotation are auditable.
resource "aws_kms_key" "this" {
  description             = "${var.project_name}-${var.environment} CMK for logs, DynamoDB, and SQS"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.this.key_id
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Key policy: account admin retains control; CloudWatch Logs service can use the
# key for the log groups in this account/region; the rest of the access is via
# IAM on the Lambda role (DynamoDB/SQS use the key transparently through the
# service-to-service grant the resource encryption config establishes).
resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountRootAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${data.aws_region.current.name}.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })
}
