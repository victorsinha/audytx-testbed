###############################################################################
# IAM for the ECS Fargate worker.
#
# Two distinct roles, by design:
#  - task_execution: used by the ECS agent to pull the image and ship logs.
#  - task:          used by the running container; scoped to exactly the SQS
#                   actions a consumer needs, on this one work queue + DLQ.
###############################################################################

# --- Task execution role (image pull + log shipping) -------------------------

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    # Confused-deputy guard: only this account's ECS can assume the roles.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name}-worker-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The execution role also needs to write to the (KMS-encrypted) log group and
# decrypt with the worker key for the awslogs driver.
data "aws_iam_policy_document" "task_execution_extra" {
  statement {
    sid    = "WriteWorkerLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.worker.arn}:*"]
  }

  statement {
    sid    = "UseKmsForLogs"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.worker.arn]
  }
}

resource "aws_iam_role_policy" "task_execution_extra" {
  name   = "${local.name}-worker-execution-extra"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_extra.json
}

# --- Task role (runtime permissions for the worker code) ---------------------

resource "aws_iam_role" "task" {
  name               = "${local.name}-worker-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.tags
}

# Least-privilege SQS consumer permissions: receive/delete from the work queue,
# read DLQ for replay tooling, and use the KMS key to decrypt message payloads.
data "aws_iam_policy_document" "task_sqs" {
  statement {
    sid    = "ConsumeWorkQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [
      aws_sqs_queue.work.arn,
      aws_sqs_queue.work_dlq.arn,
    ]
  }

  statement {
    sid    = "DecryptMessages"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.worker.arn]
  }
}

resource "aws_iam_role_policy" "task_sqs" {
  name   = "${local.name}-worker-task-sqs"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_sqs.json
}
