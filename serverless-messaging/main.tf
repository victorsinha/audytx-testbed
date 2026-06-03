# FIXTURE — NOT PRODUCTION CODE.
#
# Mirrors the a real-world false-positive pattern that motivated the
# entire audytx context-reasoning layer. Five intentional patterns, each
# of which a naive scanner flags but audytx context-suppresses with a
# stated reason:
#
#   1. SQS DLQ recursion — `chirp_outbox` redrives to `chirp_outbox_dlq`;
#      the DLQ has no redrive_policy of its own. A naive scanner flags
#      the DLQ for "missing CMK". audytx suppresses via sqs_dlq_identity
#      (DLQs are the terminal failure target).
#
#   2. SQS managed-SSE on the DLQ — `sqs_managed_sse_enabled = true` is
#      real encryption. The strict-CMK ask is a separate concern.
#
#   3. Sync Lambda — `chirp_api` is invoked only via API Gateway v2.
#      A naive scanner flags "Lambda has no dead_letter_config". audytx
#      suppresses via lambda_invocation_graph — sync invokers never put
#      anything onto the Lambda DLQ; the caller handles the failure.
#
#   4. Polled-async Lambda — `chirp_outbox_worker` is driven by an SQS
#      event source mapping. Same naive flag; same axis. Polled invokers
#      surface failures via the source queue's redrive_policy, not a
#      Lambda-level DLQ.
#
#   5. DDB with TTL — `chirp_request_log` has TTL enabled and PITR off.
#      A naive scanner flags "no point-in-time recovery". audytx
#      suppresses via data_lifetime — PITR rollback is a semantic
#      mismatch for storage that actively expires its own data.

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
  region = "us-east-1"
}

# ---------------------------------------------------------------------
# 1 + 2. SQS DLQ recursion and managed-SSE
# ---------------------------------------------------------------------

resource "aws_sqs_queue" "chirp_outbox" {
  name = "chirp-outbox"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.chirp_outbox_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "chirp_outbox_dlq" {
  name                      = "chirp-outbox-dlq"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600
}

# ---------------------------------------------------------------------
# 3. Sync Lambda — fronted by API Gateway v2 integration.
# ---------------------------------------------------------------------

resource "aws_lambda_function" "chirp_api" {
  function_name = "chirp-api"
  role          = "arn:aws:iam::123456789012:role/chirp-api"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
}

resource "aws_apigatewayv2_integration" "chirp_api" {
  api_id             = "apiid"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.chirp_api.invoke_arn
  integration_method = "POST"
}

# ---------------------------------------------------------------------
# 4. Polled-async Lambda — driven by SQS event source mapping.
# ---------------------------------------------------------------------

resource "aws_lambda_function" "chirp_outbox_worker" {
  function_name = "chirp-outbox-worker"
  role          = "arn:aws:iam::123456789012:role/chirp-outbox-worker"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
}

resource "aws_lambda_event_source_mapping" "chirp_outbox_esm" {
  function_name    = aws_lambda_function.chirp_outbox_worker.arn
  event_source_arn = aws_sqs_queue.chirp_outbox.arn
  batch_size       = 10
}

# ---------------------------------------------------------------------
# 5. DDB with TTL — ephemeral storage, PITR intentionally off.
# ---------------------------------------------------------------------

resource "aws_dynamodb_table" "chirp_request_log" {
  name         = "chirp-request-log"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"

  point_in_time_recovery {
    enabled = false
  }

  ttl {
    enabled        = true
    attribute_name = "expires_at"
  }

  attribute {
    name = "request_id"
    type = "S"
  }
}
