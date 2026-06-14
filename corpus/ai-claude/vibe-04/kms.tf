# Customer-managed KMS key used to encrypt all data at rest
# (DynamoDB, S3, SQS, CloudWatch Logs, SNS). Rotation enabled.
resource "aws_kms_key" "main" {
  description             = "${local.name_prefix} backend data-at-rest encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # Allow the account root full administrative control, and grant the
  # AWS managed services that hold our data permission to use the key.
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
        Sid    = "AllowServiceUseOfTheKey"
        Effect = "Allow"
        Principal = {
          Service = [
            "logs.${data.aws_region.current.name}.amazonaws.com",
            "sns.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-backend"
  target_key_id = aws_kms_key.main.key_id
}
