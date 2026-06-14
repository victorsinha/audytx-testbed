# SQS -> Lambda -> S3 data-lake pipeline
#
# Flow:
#   producers -> SQS queue -> Lambda (event source mapping) -> S3 data lake
# Messages that fail processing after maxReceiveCount land in a dead-letter
# queue so the pipeline never silently drops data.

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

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Pipeline    = "sqs-lambda-s3-datalake"
    },
    var.tags,
  )
}

# ---------------------------------------------------------------------------
# KMS key for at-rest encryption (shared by SQS, S3, and Lambda env/logs)
# ---------------------------------------------------------------------------
resource "aws_kms_key" "pipeline" {
  description             = "CMK for ${local.name_prefix} SQS/Lambda/S3 pipeline"
  deletion_window_in_days = 14
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "pipeline" {
  name          = "alias/${local.name_prefix}-pipeline"
  target_key_id = aws_kms_key.pipeline.key_id
}

# Allow CloudWatch Logs and the AWS service principals that touch this key.
data "aws_iam_policy_document" "kms" {
  # Root account retains full control so the key is never orphaned.
  statement {
    sid       = "EnableRootAccount"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # CloudWatch Logs needs to encrypt the Lambda log group.
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name_prefix}-processor"]
    }
  }
}

resource "aws_kms_key_policy" "pipeline" {
  key_id = aws_kms_key.pipeline.id
  policy = data.aws_iam_policy_document.kms.json
}

# ---------------------------------------------------------------------------
# SQS: main queue + dead-letter queue
# ---------------------------------------------------------------------------
resource "aws_sqs_queue" "dlq" {
  name = "${local.name_prefix}-dlq"

  # Keep failed messages long enough to investigate (14 days, the max).
  message_retention_seconds = 1209600

  kms_master_key_id                 = aws_kms_key.pipeline.arn
  kms_data_key_reuse_period_seconds = 300

  tags = local.tags
}

resource "aws_sqs_queue" "main" {
  name = "${local.name_prefix}-queue"

  # Visibility timeout must be >= Lambda timeout (AWS guidance: 6x) so an
  # in-flight message is not re-delivered while Lambda is still processing it.
  visibility_timeout_seconds = var.lambda_timeout * 6
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20 # long polling

  kms_master_key_id                 = aws_kms_key.pipeline.arn
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = local.tags
}

# Restrict who can redrive from the DLQ back to the main queue.
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}

# Enforce TLS in transit for all SQS access.
data "aws_iam_policy_document" "sqs_tls" {
  for_each = {
    main = aws_sqs_queue.main.arn
    dlq  = aws_sqs_queue.dlq.arn
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = [each.value]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id
  policy    = data.aws_iam_policy_document.sqs_tls["main"].json
}

resource "aws_sqs_queue_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id
  policy    = data.aws_iam_policy_document.sqs_tls["dlq"].json
}

# ---------------------------------------------------------------------------
# S3: the data lake bucket (private, encrypted, versioned, no public access)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "data_lake" {
  bucket = "${local.name_prefix}-data-lake-${data.aws_caller_identity.current.account_id}"

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy      = true
  ignore_public_acls       = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.pipeline.arn
    }
    bucket_key_enabled = true
  }
}

# Tier old objects to cheaper storage and clean up incomplete uploads.
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "transition-and-expire"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Deny any non-TLS access to the data lake.
data "aws_iam_policy_document" "s3_tls" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.data_lake.arn,
      "${aws_s3_bucket.data_lake.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  policy = data.aws_iam_policy_document.s3_tls.json

  depends_on = [aws_s3_bucket_public_access_block.data_lake]
}

# ---------------------------------------------------------------------------
# IAM: least-privilege execution role for the Lambda
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
  name               = "${local.name_prefix}-processor-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = local.tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  # Write its own logs.
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  # Consume from the main queue (event source mapping).
  statement {
    sid    = "ConsumeQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [aws_sqs_queue.main.arn]
  }

  # Land processed objects in the data lake (scoped to a single prefix).
  statement {
    sid    = "WriteDataLake"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.data_lake.arn}/${var.s3_landing_prefix}/*"]
  }

  # Use the CMK for SQS decrypt and S3 encrypt.
  statement {
    sid    = "UseKmsKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.pipeline.arn]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.name_prefix}-processor-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# ---------------------------------------------------------------------------
# CloudWatch Logs for the Lambda (explicit group => retention + encryption)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}-processor"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.pipeline.arn

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Lambda: the processor
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "processor" {
  function_name = "${local.name_prefix}-processor"
  role          = aws_iam_role.lambda.arn

  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  # Encrypt environment variables with the CMK.
  kms_key_arn = aws_kms_key.pipeline.arn

  # X-Ray tracing for end-to-end observability.
  tracing_config {
    mode = "Active"
  }

  # Constrain concurrency so a backlog spike can't exhaust account limits.
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  environment {
    variables = {
      DATA_LAKE_BUCKET = aws_s3_bucket.data_lake.id
      LANDING_PREFIX   = var.s3_landing_prefix
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = local.tags
}

# Wire SQS -> Lambda.
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.processor.arn
  enabled          = true

  batch_size                         = var.lambda_batch_size
  maximum_batching_window_in_seconds = 5

  # Only delete the messages that actually succeeded; the rest stay visible
  # and eventually flow to the DLQ via maxReceiveCount.
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.lambda_reserved_concurrency
  }
}
