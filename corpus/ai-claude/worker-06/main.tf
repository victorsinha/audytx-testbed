##############################################################################
# Image-processing worker
#
# Flow:
#   1. Images are uploaded to the "uploads" S3 bucket.
#   2. S3 emits an ObjectCreated event to an SQS queue.
#   3. A Lambda is triggered by the queue, resizes the image, and writes the
#      output to the "output" S3 bucket.
#
# Failed messages land in a dead-letter queue after maxReceiveCount is hit so
# poison images don't get retried forever.
##############################################################################

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
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

##############################################################################
# KMS key — used to encrypt both buckets, the queues, and Lambda env vars.
##############################################################################

resource "aws_kms_key" "this" {
  description             = "${local.name_prefix} image-processing encryption key"
  deletion_window_in_days = 14
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.this.key_id
}

# Allow S3 and SQS to use the key for the service-to-service handoffs.
resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id

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
        Sid       = "AllowS3UseOfKey"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource  = "*"
      },
      {
        Sid       = "AllowSQSUseOfKey"
        Effect    = "Allow"
        Principal = { Service = "sqs.amazonaws.com" }
        Action    = ["kms:GenerateDataKey", "kms:Decrypt"]
        Resource  = "*"
      }
    ]
  })
}

##############################################################################
# S3 — upload (source) bucket
##############################################################################

resource "aws_s3_bucket" "uploads" {
  bucket = "${local.name_prefix}-uploads"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "expire-raw-uploads"
    status = "Enabled"

    filter {}

    expiration {
      days = var.uploads_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

##############################################################################
# S3 — output (processed) bucket
##############################################################################

resource "aws_s3_bucket" "output" {
  bucket = "${local.name_prefix}-output"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "output" {
  bucket = aws_s3_bucket.output.id

  block_public_acls       = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets  = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "output" {
  bucket = aws_s3_bucket.output.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.this.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "output" {
  bucket = aws_s3_bucket.output.id
  versioning_configuration {
    status = "Enabled"
  }
}

##############################################################################
# SQS — main queue + dead-letter queue
#
# visibility_timeout must be >= the Lambda timeout (AWS requires >= for an SQS
# event source; we use 6x per AWS guidance to cover retries).
##############################################################################

resource "aws_sqs_queue" "dlq" {
  name                              = "${local.name_prefix}-uploads-dlq"
  message_retention_seconds         = 1209600 # 14 days — max, so failures can be inspected
  kms_master_key_id                 = aws_kms_key.this.id
  kms_data_key_reuse_period_seconds = 300

  tags = local.common_tags
}

resource "aws_sqs_queue" "uploads" {
  name                       = "${local.name_prefix}-uploads"
  visibility_timeout_seconds = var.lambda_timeout_seconds * 6
  message_retention_seconds  = 345600 # 4 days

  kms_master_key_id                 = aws_kms_key.this.id
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = local.common_tags
}

# Allow only this S3 bucket to send messages to the queue.
resource "aws_sqs_queue_policy" "uploads" {
  queue_url = aws_sqs_queue.uploads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3ToSendMessages"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.uploads.arn
        Condition = {
          ArnEquals    = { "aws:SourceArn" = aws_s3_bucket.uploads.arn }
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
        }
      }
    ]
  })
}

# Allow the main queue to redrive into the DLQ.
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.uploads.arn]
  })
}

##############################################################################
# S3 -> SQS event notification
##############################################################################

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  queue {
    queue_arn = aws_sqs_queue.uploads.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.uploads]
}

##############################################################################
# IAM — Lambda execution role
##############################################################################

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-resizer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })

  tags = local.common_tags
}

# Scoped permissions — only what the resizer actually needs.
resource "aws_iam_role_policy" "lambda" {
  name = "${local.name_prefix}-resizer-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConsumeFromQueue"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.uploads.arn
      },
      {
        Sid      = "ReadSourceObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      },
      {
        Sid      = "WriteProcessedObjects"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.output.arn}/*"
      },
      {
        Sid    = "UseEncryptionKey"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.this.arn
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

##############################################################################
# CloudWatch log group (created explicitly so retention + KMS are controlled)
##############################################################################

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}-resizer"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.this.arn

  tags = local.common_tags
}

##############################################################################
# Lambda — the resizer
#
# The deployment package is built/uploaded out of band (CI). We reference an
# S3 object so this config doesn't depend on a local build artifact.
##############################################################################

resource "aws_lambda_function" "resizer" {
  function_name = "${local.name_prefix}-resizer"
  role          = aws_iam_role.lambda.arn

  s3_bucket = var.lambda_artifact_bucket
  s3_key    = var.lambda_artifact_key

  handler = var.lambda_handler
  runtime = var.lambda_runtime

  timeout     = var.lambda_timeout_seconds
  memory_size = var.lambda_memory_mb

  reserved_concurrent_executions = var.lambda_reserved_concurrency

  # Trace requests end-to-end through the pipeline.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.output.bucket
      LOG_LEVEL     = var.environment == "prod" ? "INFO" : "DEBUG"
    }
  }

  kms_key_arn = aws_kms_key.this.arn

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_cloudwatch_log_group.lambda
  ]

  tags = local.common_tags
}

# Wire the queue to the Lambda.
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn                   = aws_sqs_queue.uploads.arn
  function_name                      = aws_lambda_function.resizer.arn
  batch_size                         = var.lambda_batch_size
  maximum_batching_window_in_seconds = 5

  # Don't fail the whole batch when one image is bad — only the failed records
  # are returned to the queue (Lambda must report them via batchItemFailures).
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.lambda_reserved_concurrency
  }
}
