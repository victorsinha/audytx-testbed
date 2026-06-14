# Customer-managed KMS key used to encrypt S3 objects, Redshift storage,
# CloudWatch Logs, and the Secrets Manager secret. One key, rotated, with a
# least-privilege policy scoped to the account root + the services that use it.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "pipeline" {
  description             = "${var.name_prefix} CMK for S3, Redshift, logs and secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
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

  tags = var.tags
}

resource "aws_kms_alias" "pipeline" {
  name          = "alias/${var.name_prefix}"
  target_key_id = aws_kms_key.pipeline.key_id
}
