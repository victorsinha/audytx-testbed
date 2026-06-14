# Async job processor: SQS queue -> Lambda consumer
#
# Data flow: a producer sends a message to aws_sqs_queue.jobs; Lambda polls the
# queue via an event source mapping and processes messages in batches. Messages
# that fail processing repeatedly (>= redrive maxReceiveCount) are moved to a
# dead-letter queue for inspection/replay rather than being lost or retried
# forever. This is the canonical async-invocation shape where a DLQ is
# genuinely required.

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Encryption: customer-managed KMS key for the queues. SSE-SQS (AWS-owned key)
# would also satisfy encryption-at-rest, but a CMK gives key-rotation control
# and an explicit key policy. Reused for the Lambda env-var encryption too.
# ---------------------------------------------------------------------------
resource "aws_kms_key" "jobs" {
  description             = "CMK for async job processor (SQS + Lambda)"
  deletion_window_in_days = 14
  enable_key_rotation     = true
}

resource "aws_kms_alias" "jobs" {
  name          = "alias/${var.name_prefix}-jobs"
  target_key_id = aws_kms_key.jobs.key_id
}

# ---------------------------------------------------------------------------
# SQS: main work queue + dead-letter queue.
# ---------------------------------------------------------------------------

# Dead-letter queue. Holds messages that exhausted maxReceiveCount on the main
# queue so they can be inspected/replayed. A DLQ is itself a terminal sink and
# does not need its own redrive target.
resource "aws_sqs_queue" "jobs_dlq" {
  name = "${var.name_prefix}-jobs-dlq"

  # Keep failed messages long enough to investigate (14 days, the SQS max).
  message_retention_seconds = 1209600

  kms_master_key_id                 = aws_kms_key.jobs.key_id
  kms_data_key_reuse_period_seconds = 300
}

# Main job queue. visibility_timeout_seconds must be >= the Lambda timeout so a
# message isn't redelivered while still being processed; here it is 6x the
# function timeout, matching the AWS guidance for SQS-triggered Lambda.
resource "aws_sqs_queue" "jobs" {
  name = "${var.name_prefix}-jobs"

  visibility_timeout_seconds = var.lambda_timeout * 6
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # long polling

  kms_master_key_id                 = aws_kms_key.jobs.key_id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.jobs_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# Only the DLQ may be used as a redrive target for the main queue.
resource "aws_sqs_queue_redrive_allow_policy" "jobs_dlq" {
  queue_url = aws_sqs_queue.jobs_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.jobs.arn]
  })
}

# ---------------------------------------------------------------------------
# IAM for the Lambda. Execution role + tightly-scoped inline policies:
# scoped CloudWatch Logs, SQS consume on exactly the job queue, and KMS
# decrypt/generate on exactly the one CMK. No wildcards on resources.
# ---------------------------------------------------------------------------
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
  name               = "${var.name_prefix}-jobs-processor"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Scoped log access to this function's log group only (no logs:* on *).
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_logs" {
  name   = "logs"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

# Consume permissions on exactly the job queue (the event source mapping needs
# these to poll and delete messages).
data "aws_iam_policy_document" "lambda_sqs" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [aws_sqs_queue.jobs.arn]
  }
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name   = "sqs-consume"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_sqs.json
}

# KMS decrypt for reading encrypted queue payloads, scoped to the one CMK.
data "aws_iam_policy_document" "lambda_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.jobs.arn]
  }
}

resource "aws_iam_role_policy" "lambda_kms" {
  name   = "kms"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_kms.json
}

# ---------------------------------------------------------------------------
# CloudWatch log group: explicit, with retention and CMK encryption, so logs
# don't live forever in an auto-created group.
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name_prefix}-jobs-processor"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.jobs.arn
}

# ---------------------------------------------------------------------------
# Lambda consumer.
#
# The deployment package path is provided by the caller (var.lambda_filename).
# X-Ray active tracing and reserved concurrency are set so a backlog can't
# fan out unbounded. dead_letter_config is intentionally omitted: the
# function's failure path is the SQS redrive policy above (failed batch items
# return to the queue and, after max_receive_count, land in jobs_dlq). For an
# SQS event-source-mapped function the on-failure destination IS the source
# queue's DLQ; an additional Lambda async DLQ would be dead config since the
# function is poll-invoked, not async-invoked.
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "processor" {
  function_name = "${var.name_prefix}-jobs-processor"
  role          = aws_iam_role.lambda.arn

  filename         = var.lambda_filename
  source_code_hash = filebase64sha256(var.lambda_filename)
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = 256

  reserved_concurrent_executions = var.reserved_concurrency

  kms_key_arn = aws_kms_key.jobs.arn

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      JOBS_QUEUE_URL = aws_sqs_queue.jobs.id
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs,
    aws_cloudwatch_log_group.lambda,
  ]
}

# Wire the queue to the function. report_batch_item_failures lets the function
# ack only the messages it processed successfully, so a single poison message
# in a batch doesn't force the whole batch back onto the queue.
resource "aws_lambda_event_source_mapping" "jobs" {
  event_source_arn        = aws_sqs_queue.jobs.arn
  function_name           = aws_lambda_function.processor.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.reserved_concurrency
  }
}
