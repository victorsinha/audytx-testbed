# ---- Lambda execution role ------------------------------------------------
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
  name               = "${var.project_name}-${var.environment}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Scoped CloudWatch Logs permissions (replaces the broad AWSLambdaBasicExecutionRole).
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.read.arn}:*",
      "${aws_cloudwatch_log_group.write.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_logs" {
  name   = "logs"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

# ---- DynamoDB data-plane access -------------------------------------------
# Read function: read-only. Write function: read + write. No wildcards on either
# the actions or the resource (scoped to the single table + its indexes).
data "aws_iam_policy_document" "ddb_read" {
  statement {
    sid    = "DynamoDBRead"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      aws_dynamodb_table.items.arn,
      "${aws_dynamodb_table.items.arn}/index/*",
    ]
  }
}

data "aws_iam_policy_document" "ddb_write" {
  statement {
    sid    = "DynamoDBReadWrite"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = [
      aws_dynamodb_table.items.arn,
      "${aws_dynamodb_table.items.arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "ddb_read" {
  name   = "dynamodb-read"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.ddb_read.json
}

resource "aws_iam_role_policy" "ddb_write" {
  name   = "dynamodb-write"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.ddb_write.json
}
