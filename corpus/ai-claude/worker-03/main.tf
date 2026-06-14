terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

#######################################
# KMS key for encryption at rest
#######################################

resource "aws_kms_key" "this" {
  description             = "${var.name}-cmk"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

#######################################
# SQS: work queue + dead-letter queue
#######################################

# Dead-letter queue for messages the worker repeatedly fails to process.
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  message_retention_seconds = 1209600 # 14 days (max) — keep failures for investigation

  # Server-side encryption with the customer-managed KMS key.
  kms_master_key_id                 = aws_kms_key.this.id
  kms_data_key_reuse_period_seconds = 300

  tags = var.tags
}

# Primary work queue feeding the Lambda worker.
resource "aws_sqs_queue" "this" {
  name = "${var.name}"

  # visibility_timeout must be >= the Lambda function timeout (recommended 6x).
  visibility_timeout_seconds = var.lambda_timeout * 6
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # long polling — fewer empty receives, lower cost

  # Server-side encryption with the customer-managed KMS key.
  kms_master_key_id                 = aws_kms_key.this.id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = var.tags
}

# Restrict who can pull from the DLQ to the queue owner / redrive source.
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}

#######################################
# IAM for the Lambda worker
#######################################

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
  name               = "${var.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = var.tags
}

# Least-privilege: only the SQS actions the event source mapping needs,
# scoped to this specific queue, plus KMS decrypt for the queue's CMK.
data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid    = "ConsumeFromQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.this.arn]
  }

  statement {
    sid    = "DecryptQueueMessages"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name}-permissions"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# Scoped CloudWatch Logs permissions for this function's log group only
# (avoids the over-broad AWSLambdaBasicExecutionRole managed policy).
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  name   = "${var.name}-logging"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_logging.json
}

#######################################
# Lambda worker
#######################################

# Placeholder deployment package so the stack applies out of the box.
# Replace with your real build artifact (filename / s3_bucket+s3_key / image_uri).
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/build/placeholder.zip"

  source {
    content  = "def handler(event, context):\n    for record in event.get('Records', []):\n        print(record['body'])\n    return {'batchItemFailures': []}\n"
    filename = "index.py"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.this.arn

  tags = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = aws_iam_role.lambda.arn

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  handler = "index.handler"
  runtime = var.lambda_runtime
  timeout = var.lambda_timeout

  reserved_concurrent_executions = var.reserved_concurrency

  # X-Ray active tracing for end-to-end observability.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.this.id
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logging,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = var.tags
}

#######################################
# Event source mapping: SQS -> Lambda
#######################################

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn        = aws_sqs_queue.this.arn
  function_name           = aws_lambda_function.this.arn
  batch_size              = var.batch_size
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.max_concurrency
  }
}
