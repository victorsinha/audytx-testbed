data "aws_caller_identity" "current" {}

# Package the Lambda source from disk at apply time.
data "archive_file" "transform" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/build/transform.zip"
}

# ---- Execution role ----
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-transform-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Least-privilege inline policy: read raw objects, write its own logs,
# and use the single KMS key. No wildcards on resources.
data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "ReadRawObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["${aws_s3_bucket.raw.arn}/*"]
  }

  statement {
    sid       = "ListRawBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.raw.arn]
  }

  statement {
    sid    = "UseEtlKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.etl.arn]
  }

  statement {
    sid    = "WriteOwnLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.project_name}-transform-lambda"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

# Explicit log group so retention is managed (not the implicit never-expire one).
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-transform"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.etl.arn
}

# Dead-letter queue for failed async (S3-triggered) invocations.
resource "aws_sqs_queue" "lambda_dlq" {
  name                              = "${var.project_name}-transform-dlq"
  kms_master_key_id                 = aws_kms_key.etl.id
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 1209600
}

resource "aws_lambda_function" "transform" {
  function_name = "${var.project_name}-transform"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  filename         = data.archive_file.transform.output_path
  source_code_hash = data.archive_file.transform.output_base64sha256

  reserved_concurrent_executions = 50

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  kms_key_arn = aws_kms_key.etl.arn

  environment {
    variables = {
      RAW_BUCKET    = aws_s3_bucket.raw.id
      REDSHIFT_DB   = var.redshift_database_name
      REDSHIFT_HOST = aws_redshift_cluster.analytics.dns_name
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_cloudwatch_log_group.lambda,
  ]
}

# Allow the Lambda to send to its DLQ.
data "aws_iam_policy_document" "lambda_dlq" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.lambda_dlq.arn]
  }
}

resource "aws_iam_role_policy" "lambda_dlq" {
  name   = "${var.project_name}-transform-dlq"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_dlq.json
}

# Scope the S3 invoke permission to this specific bucket + account.
resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.transform.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.raw.arn
  source_account = data.aws_caller_identity.current.account_id
}
