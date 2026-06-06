# Scenario: serverless-messaging — exercises all four false-positive suppression axes
#
# A hypothetical "chirp" messaging app. A naive scanner would fire 5+ findings.
# audytx should suppress them all and show zero live findings:
#
#   sqs_dlq_identity     — DLQ does not need its own DLQ
#   encryption_variants  — DLQ uses SQS-managed SSE, not a CMK (acceptable)
#   lambda_invocation_graph x2 — sync Lambda (API GW) and polled-async (SQS ESM)
#   data_lifetime        — DDB has TTL, so PITR warning is suppressed

resource "aws_sqs_queue" "chirp_messages" {
  name                      = "chirp-messages"
  message_retention_seconds = 345600
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.chirp_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "chirp_dlq" {
  name                  = "chirp-messages-dlq"
  sqs_managed_sse_enabled = true
}

resource "aws_lambda_function" "chirp_api" {
  function_name = "chirp-api"
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  role          = aws_iam_role.chirp_lambda.arn
  filename      = "chirp_api.zip"
}

resource "aws_lambda_function" "chirp_worker" {
  function_name = "chirp-worker"
  runtime       = "python3.12"
  handler       = "worker.lambda_handler"
  role          = aws_iam_role.chirp_lambda.arn
  filename      = "chirp_worker.zip"
}

resource "aws_lambda_event_source_mapping" "chirp_sqs" {
  event_source_arn = aws_sqs_queue.chirp_messages.arn
  function_name    = aws_lambda_function.chirp_worker.arn
  batch_size       = 10
}

resource "aws_apigatewayv2_api" "chirp" {
  name          = "chirp-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "chirp" {
  api_id             = aws_apigatewayv2_api.chirp.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.chirp_api.invoke_arn
}

resource "aws_dynamodb_table" "chirp_sessions" {
  name         = "chirp-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

resource "aws_iam_role" "chirp_lambda" {
  name = "chirp-lambda"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
