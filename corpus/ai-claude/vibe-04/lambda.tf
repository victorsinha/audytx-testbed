# Placeholder deployment package. Replace source_file with your build
# artifact, or wire this to your CI pipeline / S3 object.
data "archive_file" "api_placeholder" {
  type        = "zip"
  output_path = "${path.module}/build/api.zip"

  source {
    content  = "exports.handler = async () => ({ statusCode: 200, body: JSON.stringify({ ok: true }) });"
    filename = "index.js"
  }
}

resource "aws_cloudwatch_log_group" "lambda_api" {
  name              = "/aws/lambda/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_lambda_function" "api" {
  function_name = "${local.name_prefix}-api"
  role          = aws_iam_role.lambda_api.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime

  filename         = data.archive_file.api_placeholder.output_path
  source_code_hash = data.archive_file.api_placeholder.output_base64sha256

  memory_size = 256
  timeout     = 15

  # Limit concurrency so a traffic spike or bug can't exhaust the
  # account-wide concurrency pool.
  reserved_concurrent_executions = 50

  # Capture and trace failed async invocations.
  dead_letter_config {
    target_arn = aws_sqs_queue.jobs_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME   = aws_dynamodb_table.app.name
      MEDIA_BUCKET = aws_s3_bucket.media.bucket
      JOBS_QUEUE   = aws_sqs_queue.jobs.url
      ENVIRONMENT  = var.environment
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logs,
    aws_cloudwatch_log_group.lambda_api
  ]
}

# Allow API Gateway to invoke the function.
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
