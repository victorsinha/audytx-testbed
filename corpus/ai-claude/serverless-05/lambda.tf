# Inline Node.js source packaged at plan/apply time. Replace with your real
# build artifact (e.g. an S3 object or a CI-produced zip) for production.
data "archive_file" "read" {
  type        = "zip"
  output_path = "${path.module}/build/read.zip"

  source {
    content  = <<-JS
      const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
      const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");
      const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
      exports.handler = async (event) => {
        const id = event.pathParameters?.id;
        const out = await ddb.send(new GetCommand({ TableName: process.env.TABLE_NAME, Key: { id } }));
        return { statusCode: out.Item ? 200 : 404, body: JSON.stringify(out.Item ?? { message: "not found" }) };
      };
    JS
    filename = "index.js"
  }
}

data "archive_file" "write" {
  type        = "zip"
  output_path = "${path.module}/build/write.zip"

  source {
    content  = <<-JS
      const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
      const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
      const { randomUUID } = require("crypto");
      const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({}));
      exports.handler = async (event) => {
        const body = JSON.parse(event.body ?? "{}");
        const item = { id: body.id ?? randomUUID(), ...body };
        await ddb.send(new PutCommand({ TableName: process.env.TABLE_NAME, Item: item }));
        return { statusCode: 201, body: JSON.stringify(item) };
      };
    JS
    filename = "index.js"
  }
}

resource "aws_lambda_function" "read" {
  function_name = "${var.project_name}-${var.environment}-read"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "index.handler"
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = data.archive_file.read.output_path
  source_code_hash = data.archive_file.read.output_base64sha256

  # Concurrency cap bounds blast radius and runaway invocation cost.
  reserved_concurrent_executions = 25

  # Active tracing for request-level visibility.
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.read]
}

resource "aws_lambda_function" "write" {
  function_name = "${var.project_name}-${var.environment}-write"
  role          = aws_iam_role.lambda.arn
  runtime       = var.lambda_runtime
  handler       = "index.handler"
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = data.archive_file.write.output_path
  source_code_hash = data.archive_file.write.output_base64sha256

  reserved_concurrent_executions = 25

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.write]
}

# Pre-create log groups so retention is enforced and the scoped logs policy
# (iam.tf) can reference their ARNs.
resource "aws_cloudwatch_log_group" "read" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-read"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "write" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-write"
  retention_in_days = var.log_retention_days
}
