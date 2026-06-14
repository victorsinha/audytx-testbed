data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Trust policy: only Lambda may assume these roles.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# One role per function so each gets least-privilege scoping and isolated logs.
resource "aws_iam_role" "lambda" {
  for_each = var.functions

  name               = "${var.project_name}-${var.environment}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Scoped CloudWatch Logs permissions for each function's own log group only.
data "aws_iam_policy_document" "lambda_logging" {
  for_each = var.functions

  statement {
    sid    = "WriteOwnLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda[each.key].arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  for_each = var.functions

  name   = "logging"
  role   = aws_iam_role.lambda[each.key].id
  policy = data.aws_iam_policy_document.lambda_logging[each.key].json
}

# Least-privilege DynamoDB access. Read-only methods (GET) get only read
# actions; mutating methods get read+write. No table-wide "dynamodb:*".
data "aws_iam_policy_document" "lambda_dynamodb" {
  for_each = var.functions

  statement {
    sid    = "TableAccess"
    effect = "Allow"
    actions = upper(each.value.method) == "GET" ? [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      ] : [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
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

resource "aws_iam_role_policy" "lambda_dynamodb" {
  for_each = var.functions

  name   = "dynamodb-access"
  role   = aws_iam_role.lambda[each.key].id
  policy = data.aws_iam_policy_document.lambda_dynamodb[each.key].json
}
