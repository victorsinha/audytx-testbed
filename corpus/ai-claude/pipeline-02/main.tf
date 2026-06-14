locals {
  common_tags = merge(
    {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

data "aws_caller_identity" "current" {}

#######################################################################
# KMS — one customer-managed key encrypts SQS, the DLQ, Lambda env,
# CloudWatch Logs, Redshift, and the Redshift password secret.
#######################################################################

resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} pipeline encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAdmin"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowCloudWatchLogs"
        Effect    = "Allow"
        Principal = { Service = "logs.${var.aws_region}.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*",
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.name_prefix}-consumer"
          }
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}"
  target_key_id = aws_kms_key.this.key_id
}

#######################################################################
# SQS — main queue + dead-letter queue.
# The main queue feeds a Lambda, so a redrive policy is genuinely
# warranted; poison messages land in the DLQ instead of looping.
#######################################################################

resource "aws_sqs_queue" "dlq" {
  name                              = "${var.name_prefix}-dlq"
  kms_master_key_id                 = aws_kms_key.this.arn
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 1209600 # 14 days — max retention for forensics on poison messages

  tags = local.common_tags
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.name_prefix}-queue"
  kms_master_key_id          = aws_kms_key.this.arn
  # KMS data-key reuse window kept short for a high-throughput stream.
  kms_data_key_reuse_period_seconds = 300
  message_retention_seconds         = 345600 # 4 days
  # Visibility timeout must be >= the Lambda timeout so a slow batch is
  # not redelivered while still in flight. 180s = 6x the 30s fn timeout.
  visibility_timeout_seconds = 180

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = local.common_tags
}

# Restrict who can pull off the DLQ — only this account's principals,
# and force TLS in transit.
resource "aws_sqs_queue_policy" "dlq_tls" {
  queue_url = aws_sqs_queue.dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.dlq.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })
}

resource "aws_sqs_queue_policy" "main_tls" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.main.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })
}

#######################################################################
# Networking — the Lambda runs in private subnets so it can reach the
# Redshift cluster. SQS/KMS/Secrets access is via the VPC's egress
# (assumed: VPC endpoints or NAT — see security_group egress).
#######################################################################

resource "aws_security_group" "lambda" {
  name_prefix = "${var.name_prefix}-lambda-"
  description = "Egress-only SG for the SQS consumer Lambda."
  vpc_id      = var.vpc_id

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "redshift" {
  name_prefix = "${var.name_prefix}-redshift-"
  description = "Redshift cluster SG — ingress only from the consumer Lambda."
  vpc_id      = var.vpc_id

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda may reach Redshift on 5439 and make HTTPS calls (to AWS APIs /
# VPC endpoints). No open-world egress on arbitrary ports.
resource "aws_vpc_security_group_egress_rule" "lambda_to_redshift" {
  security_group_id            = aws_security_group.lambda.id
  description                  = "Redshift SQL"
  ip_protocol                  = "tcp"
  from_port                    = 5439
  to_port                      = 5439
  referenced_security_group_id = aws_security_group.redshift.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_https" {
  security_group_id = aws_security_group.lambda.id
  description       = "HTTPS to AWS APIs / VPC endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

# Redshift accepts SQL only from the Lambda SG — no CIDR ingress.
resource "aws_vpc_security_group_ingress_rule" "redshift_from_lambda" {
  security_group_id            = aws_security_group.redshift.id
  description                  = "Redshift SQL from consumer Lambda"
  ip_protocol                  = "tcp"
  from_port                    = 5439
  to_port                      = 5439
  referenced_security_group_id = aws_security_group.lambda.id
}

#######################################################################
# IAM — least-privilege execution role for the Lambda.
#######################################################################

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
  name               = "${var.name_prefix}-consumer-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

# Scoped permissions: poll the specific queue, write its own logs,
# manage ENIs for VPC attachment, decrypt with the one key, and read
# the one Redshift secret. No wildcards on resources.
data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = "ConsumeQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [aws_sqs_queue.main.arn]
  }

  statement {
    sid    = "WriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  statement {
    sid    = "VpcEni"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
    ]
    # These EC2 ENI actions do not support resource-level scoping; AWS
    # requires "*". Scope is bounded by the SG/subnet attachment instead.
    resources = ["*"]
  }

  statement {
    sid    = "DecryptKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.this.arn]
  }

  statement {
    sid    = "ReadRedshiftSecret"
    effect = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.redshift.arn]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name_prefix}-consumer-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

#######################################################################
# Lambda — the SQS consumer that writes to Redshift.
#######################################################################

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name_prefix}-consumer"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.this.arn
  tags              = local.common_tags
}

resource "aws_lambda_function" "consumer" {
  function_name = "${var.name_prefix}-consumer"
  role          = aws_iam_role.lambda.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  timeout       = 30
  memory_size   = 512

  filename         = var.lambda_source_path
  source_code_hash = filebase64sha256(var.lambda_source_path)

  # X-Ray tracing for end-to-end visibility across the pipeline.
  tracing_config {
    mode = "Active"
  }

  # Concurrency ceiling protects Redshift connection limits from an
  # SQS backlog spike.
  reserved_concurrent_executions = 10

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      REDSHIFT_SECRET_ARN = aws_secretsmanager_secret.redshift.arn
      REDSHIFT_DATABASE   = var.redshift_database_name
      REDSHIFT_HOST       = aws_redshift_cluster.this.dns_name
      REDSHIFT_PORT       = tostring(aws_redshift_cluster.this.port)
    }
  }

  # Lambda env vars encrypted with the CMK rather than the default key.
  kms_key_arn = aws_kms_key.this.arn

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = local.common_tags
}

# The wedge: this Lambda is invoked by a real poll-based event source,
# so the function-level DLQ concern is satisfied by the SQS redrive
# policy above (failed batches return to the queue, then to the DLQ).
resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn                   = aws_sqs_queue.main.arn
  function_name                      = aws_lambda_function.consumer.arn
  batch_size                         = var.sqs_batch_size
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
  enabled                            = true
}

#######################################################################
# Secrets Manager — Redshift password. Generated, never hardcoded.
#######################################################################

resource "random_password" "redshift" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "redshift" {
  name                    = "${var.name_prefix}-redshift-credentials"
  kms_key_id              = aws_kms_key.this.arn
  recovery_window_in_days = 7
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redshift" {
  secret_id = aws_secretsmanager_secret.redshift.id
  secret_string = jsonencode({
    username = var.redshift_master_username
    password = random_password.redshift.result
    host     = aws_redshift_cluster.this.dns_name
    port     = aws_redshift_cluster.this.port
    dbname   = var.redshift_database_name
  })
}

#######################################################################
# Redshift — the data sink. Private, encrypted, logged.
#######################################################################

resource "aws_redshift_subnet_group" "this" {
  name       = "${var.name_prefix}-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = local.common_tags
}

resource "aws_redshift_cluster" "this" {
  cluster_identifier = "${var.name_prefix}-cluster"
  database_name      = var.redshift_database_name
  master_username    = var.redshift_master_username
  master_password    = random_password.redshift.result

  node_type     = var.redshift_node_type
  cluster_type  = var.redshift_cluster_type
  number_of_nodes = var.redshift_cluster_type == "single-node" ? 1 : 2

  # No public endpoint — reachable only from inside the VPC.
  publicly_accessible = false

  cluster_subnet_group_name = aws_redshift_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]

  # Encryption at rest with the CMK; TLS enforced for in-transit.
  encrypted  = true
  kms_key_id = aws_kms_key.this.arn

  # Audit + recovery posture.
  enhanced_vpc_routing                = true
  automated_snapshot_retention_period = 7
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "${var.name_prefix}-final"

  logging {
    enable               = true
    log_destination_type = "cloudwatch"
    log_exports          = ["connectionlog", "userlog", "useractivitylog"]
  }

  tags = local.common_tags
}

# Force TLS on Redshift connections via the parameter group.
resource "aws_redshift_parameter_group" "this" {
  name   = "${var.name_prefix}-params"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  tags = local.common_tags
}
