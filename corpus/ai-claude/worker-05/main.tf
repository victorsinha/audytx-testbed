# SQS-backed job system with Lambda consumers.
#
# Architecture:
#   producer -> SQS job queue -> Lambda consumer (event source mapping)
#                     |
#                     +-> redrive to dead-letter queue after max receives
#
# The DLQ captures jobs the consumer cannot process so they are never silently
# lost. The consumer reads from the job queue via an aws_lambda_event_source_mapping.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    System      = "job-processing"
  })
}

# ---------------------------------------------------------------------------
# KMS key for SQS + Lambda env encryption at rest
# ---------------------------------------------------------------------------
resource "aws_kms_key" "jobs" {
  description             = "${local.name_prefix} job system encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "jobs" {
  name          = "alias/${local.name_prefix}-jobs"
  target_key_id = aws_kms_key.jobs.key_id
}

# ---------------------------------------------------------------------------
# Dead-letter queue: terminal jobs the consumer could not process.
# A DLQ has no DLQ of its own by design (it IS the terminus).
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "jobs_dlq" {
  name = "${local.name_prefix}-jobs-dlq"

  # Retain failed jobs long enough to inspect and replay them.
  message_retention_seconds = 1209600 # 14 days (max)

  kms_master_key_id                 = aws_kms_key.jobs.key_id
  kms_data_key_reuse_period_seconds = 300

  tags = merge(local.common_tags, {
    Role = "dead-letter-queue"
  })
}

# Only the main job queue may redrive into the DLQ.
resource "aws_sqs_queue_redrive_allow_policy" "jobs_dlq" {
  queue_url = aws_sqs_queue.jobs_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.jobs.arn]
  })
}

# ---------------------------------------------------------------------------
# Primary job queue
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "jobs" {
  name = "${local.name_prefix}-jobs"

  # visibility_timeout must be >= the consumer's function timeout, otherwise a
  # still-running invocation's message becomes visible again and is processed
  # twice. Held at 6x the function timeout per AWS guidance.
  visibility_timeout_seconds = var.lambda_timeout_seconds * 6
  message_retention_seconds  = var.job_retention_seconds
  receive_wait_time_seconds  = 20 # long polling

  kms_master_key_id                 = aws_kms_key.jobs.key_id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.jobs_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = merge(local.common_tags, {
    Role = "job-queue"
  })
}

# ---------------------------------------------------------------------------
# Consumer Lambda execution role (least privilege)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "consumer" {
  name = "${local.name_prefix}-jobs-consumer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })

  tags = local.common_tags
}

# Scoped CloudWatch Logs access: only this function's own log group.
resource "aws_iam_role_policy" "consumer_logs" {
  name = "logs"
  role = aws_iam_role.consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CreateLogStreams"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.consumer.arn}:*"
      }
    ]
  })
}

# SQS access scoped to exactly the job queue the function consumes.
# The event source mapping needs Receive/Delete/GetAttributes on the source.
resource "aws_iam_role_policy" "consumer_sqs" {
  name = "sqs-consume"
  role = aws_iam_role.consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConsumeJobs"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.jobs.arn
      },
      {
        Sid      = "DecryptMessages"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.jobs.arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Consumer Lambda
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/aws/lambda/${local.name_prefix}-jobs-consumer"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.jobs.arn

  tags = local.common_tags
}

resource "aws_lambda_function" "consumer" {
  function_name = "${local.name_prefix}-jobs-consumer"
  role          = aws_iam_role.consumer.arn

  filename         = var.consumer_package_path
  source_code_hash = filebase64sha256(var.consumer_package_path)
  handler          = var.consumer_handler
  runtime          = var.consumer_runtime
  architectures    = ["arm64"]

  timeout     = var.lambda_timeout_seconds
  memory_size = var.lambda_memory_mb

  # Limit concurrent consumers so a job spike cannot exhaust account-wide
  # Lambda concurrency and starve other functions.
  reserved_concurrent_executions = var.consumer_max_concurrency

  kms_key_arn = aws_kms_key.jobs.arn

  environment {
    variables = {
      JOB_QUEUE_URL = aws_sqs_queue.jobs.url
      DLQ_URL       = aws_sqs_queue.jobs_dlq.url
    }
  }

  # Trace requests end-to-end through the async pipeline.
  tracing_config {
    mode = "Active"
  }

  # Don't activate the function until its log group exists, so the first
  # invocation's logs are captured with the configured retention/KMS.
  depends_on = [
    aws_iam_role_policy.consumer_logs,
    aws_cloudwatch_log_group.consumer,
  ]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Wire the queue to the consumer.
# This is the async invoker: SQS -> Lambda. With this mapping in place the
# Lambda is invoked by the SQS poller, so the function itself does not need
# its own DLQ (failed batches redrive to the SQS DLQ via maxReceiveCount).
# ---------------------------------------------------------------------------
resource "aws_lambda_event_source_mapping" "jobs" {
  event_source_arn = aws_sqs_queue.jobs.arn
  function_name    = aws_lambda_function.consumer.arn
  enabled          = true

  batch_size                         = var.batch_size
  maximum_batching_window_in_seconds = var.max_batching_window_seconds

  # Report per-message failures so only the failed jobs in a batch are retried
  # (and eventually redriven to the DLQ) instead of the whole batch.
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.consumer_max_concurrency
  }
}
