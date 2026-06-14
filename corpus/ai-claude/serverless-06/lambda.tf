# Dead-letter queue for failed asynchronous Lambda invocations
# (e.g. S3 -> Lambda upload-processing events).
resource "aws_sqs_queue" "lambda_dlq" {
  name                              = "${local.name_prefix}-lambda-dlq"
  kms_master_key_id                 = aws_kms_key.main.id
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 1209600 # 14 days
}

# Package the function source. Expects a ./src directory containing handler code.
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_lambda_function" "api" {
  function_name = "${local.name_prefix}-api"
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  # Enable active tracing for observability.
  tracing_config {
    mode = "Active"
  }

  # Route failed async invocations to the DLQ.
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  # Reserve concurrency to bound blast radius / cost.
  reserved_concurrent_executions = 50

  environment {
    variables = {
      METADATA_TABLE = aws_dynamodb_table.metadata.name
      UPLOAD_BUCKET  = aws_s3_bucket.uploads.id
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda_basic
  ]
}

# Allow API Gateway to invoke the function.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
