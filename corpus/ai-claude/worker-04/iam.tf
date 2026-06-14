###############################################################################
# Execution role for the Lambda. Trust is scoped to lambda.amazonaws.com and
# locked to this account/function via aws:SourceAccount + aws:SourceArn to
# prevent the confused-deputy class.
###############################################################################

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-email-worker"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json

  tags = local.tags
}

###############################################################################
# Least-privilege inline policy. Every action is resource-scoped — no
# wildcards on resources, and SES sending is constrained to the configured
# From identity.
###############################################################################

data "aws_iam_policy_document" "lambda" {
  # Consume from the work queue (the event source mapping uses the role).
  statement {
    sid    = "ConsumeWorkQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.email.arn]
  }

  # Send permanently-failed messages on to the DLQ.
  statement {
    sid       = "SendToDLQ"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.email_dlq.arn]
  }

  # Decrypt SQS payloads and Lambda env vars with the CMK.
  statement {
    sid    = "UseKmsKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.email_worker.arn]
  }

  # Write logs to the function's own log group only.
  statement {
    sid    = "WriteOwnLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  # X-Ray trace segments (no resource-level scoping available for these).
  statement {
    sid    = "XRayTracing"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    resources = ["*"]
  }

  # Send email via SES, constrained to the verified From identity.
  statement {
    sid    = "SendEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = [
      "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/${var.email_from_address}"
    ]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name_prefix}-email-worker"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}
