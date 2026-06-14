# Package each function's source directory into a zip at plan time.
# Expected layout: ${path.module}/src/<function_name>/
data "archive_file" "lambda" {
  for_each = var.functions

  type        = "zip"
  source_dir  = "${path.module}/src/${each.key}"
  output_path = "${path.module}/build/${each.key}.zip"
}

# Explicit log groups (created before the function) so retention and the
# scoped logging IAM policy are managed by Terraform, not auto-created.
resource "aws_cloudwatch_log_group" "lambda" {
  for_each = var.functions

  name              = "/aws/lambda/${var.project_name}-${var.environment}-${each.key}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "this" {
  for_each = var.functions

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = aws_iam_role.lambda[each.key].arn
  handler       = each.value.handler
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_seconds

  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256

  # X-Ray tracing for request-level observability across the API.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
      LOG_LEVEL  = "INFO"
    }
  }

  # Ensure the log group exists (with retention) before the function so it is
  # not implicitly created with infinite retention on first invocation.
  depends_on = [aws_cloudwatch_log_group.lambda]
}
