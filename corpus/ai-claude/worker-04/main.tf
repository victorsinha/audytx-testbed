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
data "aws_region" "current" {}

###############################################################################
# KMS key for at-rest encryption (shared by the queues and the Lambda env).
# Using a customer-managed key (not the AWS-managed aws/sqs key) so the key
# policy can be scoped and rotated.
###############################################################################

resource "aws_kms_key" "email_worker" {
  description             = "${var.name_prefix} email worker encryption key"
  deletion_window_in_days = 14
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "email_worker" {
  name          = "alias/${var.name_prefix}-email-worker"
  target_key_id = aws_kms_key.email_worker.key_id
}

# Allow SQS and the Lambda service to use the key. Scoped to this account.
resource "aws_kms_key_policy" "email_worker" {
  key_id = aws_kms_key.email_worker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowSQSUseOfKey"
        Effect    = "Allow"
        Principal = { Service = "sqs.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################################
# Dead-letter queue.
# This is the *real* DLQ: it is the terminal queue, so it does NOT get a
# redrive policy of its own (a DLQ pointing at a DLQ is the classic FP).
###############################################################################

resource "aws_sqs_queue" "email_dlq" {
  name = "${var.name_prefix}-email-dlq"

  # Retain failed messages long enough to investigate / manually redrive.
  message_retention_seconds = 1209600 # 14 days (max)

  kms_master_key_id                 = aws_kms_key.email_worker.id
  kms_data_key_reuse_period_seconds = 300

  tags = local.tags
}

# Only the email worker role may consume/redrive from the DLQ.
resource "aws_sqs_queue_policy" "email_dlq" {
  queue_url = aws_sqs_queue.email_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.email_dlq.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

###############################################################################
# Main work queue. Messages here trigger the Lambda. Failures (after
# maxReceiveCount attempts) spill into the DLQ above.
###############################################################################

resource "aws_sqs_queue" "email" {
  name = "${var.name_prefix}-email"

  # visibility_timeout must be >= the Lambda timeout (ideally 6x per AWS
  # guidance) so an in-flight message is not redelivered while still being
  # processed.
  visibility_timeout_seconds = var.lambda_timeout_seconds * 6
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # long polling

  kms_master_key_id                 = aws_kms_key.email_worker.id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = local.tags
}

resource "aws_sqs_queue_policy" "email" {
  queue_url = aws_sqs_queue.email.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.email.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# Let the DLQ accept redriven messages from the source queue only.
resource "aws_sqs_queue_redrive_allow_policy" "email_dlq" {
  queue_url = aws_sqs_queue.email_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.email.arn]
  })
}

###############################################################################
# Lambda packaging.
# Ships a tiny inline handler so `terraform apply` works out of the box;
# replace src/ with your real email-sending code.
###############################################################################

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/build/email_worker.zip"

  source {
    content  = <<-PY
    import json
    import logging

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    def handler(event, context):
        # event["Records"] is a batch of SQS messages.
        for record in event.get("Records", []):
            body = json.loads(record["body"])
            # TODO: send the email (SES, etc.) using `body`.
            logger.info("would send email to %s", body.get("to"))
        return {"batchItemFailures": []}
    PY
    filename = "handler.py"
  }
}

###############################################################################
# CloudWatch log group, created explicitly so retention + encryption are set
# (the implicit /aws/lambda/* group defaults to never-expire, unencrypted).
###############################################################################

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name_prefix}-email-worker"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.email_worker.arn

  tags = local.tags
}

###############################################################################
# The Lambda function.
###############################################################################

resource "aws_lambda_function" "email_worker" {
  function_name = "${var.name_prefix}-email-worker"
  role          = aws_iam_role.lambda.arn

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.12"
  architectures    = ["arm64"]

  timeout     = var.lambda_timeout_seconds
  memory_size = 256

  # Encrypt environment variables at rest with our CMK.
  kms_key_arn = aws_kms_key.email_worker.arn

  # Cap concurrency so a queue flood can't exhaust account-wide concurrency
  # or hammer the downstream email provider's send rate.
  reserved_concurrent_executions = var.reserved_concurrency

  # X-Ray tracing for the async invocation path.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      EMAIL_FROM_ADDRESS = var.email_from_address
      LOG_LEVEL          = "INFO"
    }
  }

  # Ensure the log group (with retention/encryption) exists before the
  # function auto-creates an unconfigured one.
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda,
  ]

  tags = local.tags
}

###############################################################################
# Event source mapping: SQS -> Lambda.
# partial-batch-response so one bad message in a batch doesn't redeliver the
# whole batch.
###############################################################################

resource "aws_lambda_event_source_mapping" "email" {
  event_source_arn = aws_sqs_queue.email.arn
  function_name    = aws_lambda_function.email_worker.arn

  batch_size                         = 10
  maximum_batching_window_in_seconds = 5

  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.reserved_concurrency
  }
}
