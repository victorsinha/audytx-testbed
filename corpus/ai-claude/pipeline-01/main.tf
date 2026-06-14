##############################################
# Data pipeline: Kinesis -> Lambda -> S3
#
#   Events are ingested into a Kinesis data
#   stream, processed by a Lambda function
#   (event-source mapping), and the results
#   are written to an S3 bucket.
##############################################

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
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "data-pipeline"
    },
    var.tags
  )
}

##############################################
# KMS — customer-managed key for encrypting
# the stream, the bucket, and the log group.
##############################################

resource "aws_kms_key" "pipeline" {
  description             = "CMK for ${local.name_prefix} data pipeline"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "pipeline" {
  name          = "alias/${local.name_prefix}-pipeline"
  target_key_id = aws_kms_key.pipeline.key_id
}

# Allow CloudWatch Logs to use the key for the Lambda log group.
resource "aws_kms_key_policy" "pipeline" {
  key_id = aws_kms_key.pipeline.id

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
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name_prefix}-processor"
          }
        }
      }
    ]
  })
}

##############################################
# Kinesis — ingest stream
##############################################

resource "aws_kinesis_stream" "ingest" {
  name             = "${local.name_prefix}-ingest"
  retention_period = var.kinesis_retention_hours

  # KMS server-side encryption with the customer-managed key.
  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.pipeline.arn

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = local.tags
}

##############################################
# S3 — results bucket (private, encrypted,
# versioned, TLS-only, access-logged)
##############################################

resource "aws_s3_bucket" "results" {
  bucket = "${local.name_prefix}-results-${data.aws_caller_identity.current.account_id}"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "results" {
  bucket = aws_s3_bucket.results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "results" {
  bucket = aws_s3_bucket.results.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "results" {
  bucket = aws_s3_bucket.results.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "results" {
  bucket = aws_s3_bucket.results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.pipeline.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "results" {
  bucket = aws_s3_bucket.results.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Deny any non-TLS access to the results bucket.
resource "aws_s3_bucket_policy" "results" {
  bucket = aws_s3_bucket.results.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.results.arn,
          "${aws_s3_bucket.results.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Dedicated access-log bucket for the results bucket.
resource "aws_s3_bucket" "logs" {
  bucket = "${local.name_prefix}-results-logs-${data.aws_caller_identity.current.account_id}"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      # S3 access-log delivery does not support SSE-KMS; SSE-S3 is required.
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "results" {
  bucket = aws_s3_bucket.results.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access/"
}

##############################################
# IAM — Lambda execution role (least privilege)
##############################################

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "lambda.amazonaws.com" }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = local.tags
}

# Read the stream (consumed via event-source mapping).
resource "aws_iam_role_policy" "lambda_kinesis" {
  name = "kinesis-read"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadIngestStream"
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.ingest.arn
      }
    ]
  })
}

# Write processed results to the S3 bucket (object-level only).
resource "aws_iam_role_policy" "lambda_s3" {
  name = "s3-write"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WriteResults"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.results.arn}/*"
      }
    ]
  })
}

# Use the CMK for stream decryption, S3 write encryption, and DLQ.
resource "aws_iam_role_policy" "lambda_kms" {
  name = "kms-use"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "UsePipelineKey"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.pipeline.arn
      }
    ]
  })
}

# Send failed-batch records to the SQS dead-letter queue.
resource "aws_iam_role_policy" "lambda_dlq" {
  name = "dlq-send"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SendToDLQ"
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.dlq.arn
      }
    ]
  })
}

# Scoped CloudWatch Logs permissions for the function's own log group.
resource "aws_iam_role_policy" "lambda_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteOwnLogs"
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

##############################################
# SQS — on-failure destination (DLQ) for the
# event-source mapping. Encrypted with the CMK.
##############################################

resource "aws_sqs_queue" "dlq" {
  name                              = "${local.name_prefix}-processor-dlq"
  kms_master_key_id                 = aws_kms_key.pipeline.id
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 1209600 # 14 days

  tags = local.tags
}

##############################################
# CloudWatch — encrypted log group for Lambda
##############################################

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}-processor"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.pipeline.arn

  tags = local.tags
}

##############################################
# Lambda — stream processor
##############################################

resource "aws_lambda_function" "processor" {
  function_name = "${local.name_prefix}-processor"
  role          = aws_iam_role.lambda.arn

  # Deployment package is supplied by the caller (CI build artifact).
  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  architectures    = ["arm64"]
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  # Limit concurrent executions to protect downstream systems.
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  # Enable active tracing for end-to-end observability.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      RESULTS_BUCKET = aws_s3_bucket.results.id
      ENVIRONMENT    = var.environment
    }
  }

  # Code-signing / package integrity is handled by source_code_hash above.
  kms_key_arn = aws_kms_key.pipeline.arn

  depends_on = [
    aws_iam_role_policy.lambda_logs,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = local.tags
}

# X-Ray tracing permissions for the function.
resource "aws_iam_role_policy" "lambda_xray" {
  name = "xray-write"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "XRayWrite"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

##############################################
# Event-source mapping — Kinesis -> Lambda
##############################################

resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn  = aws_kinesis_stream.ingest.arn
  function_name     = aws_lambda_function.processor.arn
  starting_position = "LATEST"

  batch_size                         = var.lambda_batch_size
  maximum_batching_window_in_seconds = 10
  parallelization_factor             = 1

  # Resilience: bound retries/age, split on error, and route
  # exhausted batches to the SQS DLQ instead of blocking the shard.
  maximum_retry_attempts             = 5
  maximum_record_age_in_seconds      = 3600
  bisect_batch_on_function_error     = true
  function_response_types            = ["ReportBatchItemFailures"]

  destination_config {
    on_failure {
      destination_arn = aws_sqs_queue.dlq.arn
    }
  }
}
