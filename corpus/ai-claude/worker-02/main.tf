###############################################################################
# Background worker: SQS (ingress) -> ECS Fargate tasks (consumers)
#
# Data flow: producers send messages to aws_sqs_queue.work; the ECS service
# runs N Fargate tasks that long-poll the queue and process messages. Messages
# that fail processing maxReceiveCount times are redriven to the dead-letter
# queue so a single poison message cannot wedge the consumers forever.
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = "${var.project_name}-${var.environment}"

  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "background-worker"
    },
    var.tags
  )
}

###############################################################################
# KMS key for at-rest encryption of the queues and the log group.
###############################################################################

resource "aws_kms_key" "worker" {
  description             = "${local.name} background worker encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "worker" {
  name          = "alias/${local.name}-worker"
  target_key_id = aws_kms_key.worker.key_id
}

###############################################################################
# SQS: work queue + dead-letter queue.
#
# The DLQ is the redrive target of the work queue, so it does NOT need its own
# redrive policy (it is the terminal sink, not a source). Messages land here
# only after maxReceiveCount failed processing attempts.
###############################################################################

resource "aws_sqs_queue" "work_dlq" {
  name = "${local.name}-work-dlq"

  # Retain failed messages long enough to inspect/replay them.
  message_retention_seconds = 1209600 # 14 days (max)

  sqs_managed_sse_enabled = false
  kms_master_key_id       = aws_kms_key.worker.id

  tags = merge(local.tags, { Role = "dead-letter-queue" })
}

resource "aws_sqs_queue" "work" {
  name = "${local.name}-work"

  # Visibility timeout should exceed the worker's max processing time so a
  # message is not redelivered while a task is still working on it.
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # long polling, fewer empty receives

  sqs_managed_sse_enabled = false
  kms_master_key_id       = aws_kms_key.worker.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.work_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = merge(local.tags, { Role = "work-queue" })
}

# Allow only this account's principals to interact with the queue, and require
# TLS in transit.
resource "aws_sqs_queue_policy" "work" {
  queue_url = aws_sqs_queue.work.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.work.arn
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

###############################################################################
# CloudWatch log group for the worker containers.
###############################################################################

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${local.name}-worker"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.worker.arn

  tags = local.tags
}

###############################################################################
# ECS cluster + Fargate service running the consumer tasks.
###############################################################################

resource "aws_ecs_cluster" "this" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${local.name}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "worker"
      image     = var.container_image
      essential = true

      # The worker is a pure consumer: no inbound ports are published.
      environment = [
        { name = "QUEUE_URL", value = aws_sqs_queue.work.id },
        { name = "DLQ_URL", value = aws_sqs_queue.work_dlq.id },
        { name = "AWS_REGION", value = var.aws_region }
      ]

      readonlyRootFilesystem = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "worker"
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "worker" {
  name            = "${local.name}-worker"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # No load balancer: this is a queue consumer, not a request server.
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.worker.id]
    assign_public_ip = false
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = local.tags
}

###############################################################################
# Security group: egress-only. The worker needs outbound TLS to reach SQS,
# ECR, and CloudWatch (via VPC endpoints or a NAT gateway); it accepts no
# inbound traffic.
###############################################################################

resource "aws_security_group" "worker" {
  name        = "${local.name}-worker"
  description = "Egress-only SG for the ${local.name} SQS background worker"
  vpc_id      = var.vpc_id

  egress {
    description = "Outbound HTTPS to AWS service endpoints (SQS/ECR/CloudWatch)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

###############################################################################
# Optional: scale the consumer count on queue depth so a backlog drains and an
# idle queue scales back toward the minimum.
###############################################################################

resource "aws_appautoscaling_target" "worker" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "worker_queue_depth" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.name}-worker-queue-depth"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker[0].resource_id
  scalable_dimension = aws_appautoscaling_target.worker[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker[0].service_namespace

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Average"

      dimensions {
        name  = "QueueName"
        value = aws_sqs_queue.work.name
      }
    }

    target_value       = var.autoscaling_target_backlog_per_task
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
