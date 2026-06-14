locals {
  # Map of logical function name -> its execution role. The HTTP method/route
  # binding for each lives in apigateway.tf.
  functions = {
    list_items = {
      handler  = "handler.list_items"
      role_arn = aws_iam_role.read.arn
      role_id  = aws_iam_role.read.id
    }
    get_item = {
      handler  = "handler.get_item"
      role_arn = aws_iam_role.read.arn
      role_id  = aws_iam_role.read.id
    }
    create_item = {
      handler  = "handler.create_item"
      role_arn = aws_iam_role.write.arn
      role_id  = aws_iam_role.write.id
    }
    update_item = {
      handler  = "handler.update_item"
      role_arn = aws_iam_role.write.arn
      role_id  = aws_iam_role.write.id
    }
    delete_item = {
      handler  = "handler.delete_item"
      role_arn = aws_iam_role.delete.arn
      role_id  = aws_iam_role.delete.id
    }
  }
}

# Placeholder deployment artifact. Replace with your real build pipeline
# (the source dir is expected to contain handler.py).
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

# Log group created explicitly (not implicitly by the first invocation) so we
# control retention and CMK encryption, and so IAM can scope to its ARN.
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.functions

  name              = "/aws/lambda/${var.project_name}-${var.environment}-${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.this.arn
}

resource "aws_lambda_function" "this" {
  for_each = local.functions

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = each.value.role_arn
  handler       = each.value.handler
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  # Synchronous (API Gateway) invocation only — no async/event-source path —
  # so no on-failure DLQ is required for these functions.
  reserved_concurrent_executions = -1

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  # Active tracing for end-to-end request visibility.
  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.logs_xray
  ]
}

# Grant API Gateway permission to invoke each function. SourceArn is scoped to
# this specific API so no other API can invoke these functions.
resource "aws_lambda_permission" "apigw" {
  for_each = local.functions

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
