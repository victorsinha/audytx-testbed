# One execution role per function, each scoped to exactly the actions and the
# single table ARN it needs (least privilege). The read function cannot write;
# the write function cannot delete; etc.

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

# ---- list/get (read-only) ----
resource "aws_iam_role" "read" {
  name               = "${var.project_name}-${var.environment}-read"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "read" {
  statement {
    sid    = "DynamoRead"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.items.arn]
  }

  statement {
    sid       = "KmsDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_role_policy" "read" {
  name   = "dynamodb-read"
  role   = aws_iam_role.read.id
  policy = data.aws_iam_policy_document.read.json
}

# ---- create/update (write, no delete) ----
resource "aws_iam_role" "write" {
  name               = "${var.project_name}-${var.environment}-write"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "write" {
  statement {
    sid    = "DynamoWrite"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
    resources = [aws_dynamodb_table.items.arn]
  }

  statement {
    sid    = "KmsEncryptDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_role_policy" "write" {
  name   = "dynamodb-write"
  role   = aws_iam_role.write.id
  policy = data.aws_iam_policy_document.write.json
}

# ---- delete ----
resource "aws_iam_role" "delete" {
  name               = "${var.project_name}-${var.environment}-delete"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "delete" {
  statement {
    sid       = "DynamoDelete"
    effect    = "Allow"
    actions   = ["dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.items.arn]
  }

  statement {
    sid       = "KmsDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_role_policy" "delete" {
  name   = "dynamodb-delete"
  role   = aws_iam_role.delete.id
  policy = data.aws_iam_policy_document.delete.json
}

# Per-function CloudWatch Logs write + X-Ray trace publishing. Scoped to each
# function's own log group ARN rather than "*".
data "aws_iam_policy_document" "logs_xray" {
  for_each = local.functions

  statement {
    sid    = "WriteOwnLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda[each.key].arn}:*"
    ]
  }

  statement {
    sid    = "XRayTrace"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "logs_xray" {
  for_each = local.functions

  name   = "logs-xray"
  role   = local.functions[each.key].role_id
  policy = data.aws_iam_policy_document.logs_xray[each.key].json
}
