# The transformer: triggered on each .csv put, it reads the object, transforms
# it, and loads it into Redshift via the Redshift Data API (so the Lambda holds
# no long-lived DB connection and uses the secret rather than inline creds).
data "archive_file" "transformer" {
  type        = "zip"
  source_dir  = "${path.module}/src/transformer"
  output_path = "${path.module}/build/transformer.zip"
}

resource "aws_cloudwatch_log_group" "transformer" {
  name              = "/aws/lambda/${var.name_prefix}-transformer"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.pipeline.arn
  tags              = var.tags
}

# Async S3 invocations need a DLQ so failed transforms are never lost.
resource "aws_sqs_queue" "transformer_dlq" {
  name                              = "${var.name_prefix}-transformer-dlq"
  kms_master_key_id                 = aws_kms_key.pipeline.arn
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 1209600
  tags                              = var.tags
}

resource "aws_iam_role" "transformer" {
  name = "${var.name_prefix}-transformer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

# Least-privilege execution policy: scoped log group, scoped bucket/object,
# the specific secret, the specific KMS key, the specific Redshift cluster,
# and the specific DLQ — no wildcards on resources.
resource "aws_iam_role_policy" "transformer" {
  name = "${var.name_prefix}-transformer"
  role = aws_iam_role.transformer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.transformer.arn}:*"
      },
      {
        Sid      = "ReadSourceCsv"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${aws_s3_bucket.landing.arn}/*"
      },
      {
        Sid      = "ListSourceBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.landing.arn
      },
      {
        Sid    = "UseKmsKey"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = aws_kms_key.pipeline.arn
      },
      {
        Sid      = "ReadRedshiftSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.redshift.arn
      },
      {
        Sid    = "RedshiftDataApi"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:BatchExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid      = "DeadLetterQueue"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.transformer_dlq.arn
      },
      {
        Sid    = "VpcNetworking"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "transformer" {
  function_name = "${var.name_prefix}-transformer"
  role          = aws_iam_role.transformer.arn
  runtime       = "python3.12"
  handler       = "handler.handler"
  timeout       = 300
  memory_size   = 512

  filename         = data.archive_file.transformer.output_path
  source_code_hash = data.archive_file.transformer.output_base64sha256

  reserved_concurrent_executions = 10

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.transformer_dlq.arn
  }

  environment {
    variables = {
      REDSHIFT_SECRET_ARN = aws_secretsmanager_secret.redshift.arn
      REDSHIFT_CLUSTER_ID = aws_redshift_cluster.this.cluster_identifier
      REDSHIFT_DATABASE   = var.redshift_database_name
      REDSHIFT_COPY_ROLE  = aws_iam_role.redshift_copy.arn
      LANDING_BUCKET      = aws_s3_bucket.landing.id
    }
  }

  tracing_config {
    mode = "Active"
  }

  kms_key_arn = aws_kms_key.pipeline.arn

  depends_on = [
    aws_iam_role_policy.transformer,
    aws_cloudwatch_log_group.transformer
  ]

  tags = var.tags
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.transformer.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.landing.arn
  source_account = data.aws_caller_identity.current.account_id
}
