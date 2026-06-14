variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier, used as a name prefix."
  type        = string
  default     = "bgworker"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Additional tags merged into every resource."
  type        = map(string)
  default     = {}
}

# --- Networking --------------------------------------------------------------

variable "vpc_id" {
  description = "VPC the worker tasks run in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the Fargate tasks. Need egress to SQS/ECR/CloudWatch via NAT or VPC endpoints."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "Provide at least one private subnet ID."
  }
}

# --- Worker container --------------------------------------------------------

variable "container_image" {
  description = "Fully-qualified container image (e.g. <acct>.dkr.ecr.<region>.amazonaws.com/worker:tag) for the consumer."
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Baseline number of running consumer tasks."
  type        = number
  default     = 2
}

# --- Queue behaviour ---------------------------------------------------------

variable "visibility_timeout_seconds" {
  description = "SQS visibility timeout. Must exceed the worker's max processing time per message."
  type        = number
  default     = 300
}

variable "max_receive_count" {
  description = "Failed-delivery attempts before a message is redriven to the DLQ."
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch log retention for worker logs."
  type        = number
  default     = 30
}

# --- Autoscaling (optional) --------------------------------------------------

variable "enable_autoscaling" {
  description = "Scale the consumer count on SQS backlog depth."
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of consumer tasks when autoscaling is enabled."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of consumer tasks when autoscaling is enabled."
  type        = number
  default     = 10
}

variable "autoscaling_target_backlog_per_task" {
  description = "Target number of visible messages per running task (target-tracking setpoint)."
  type        = number
  default     = 100
}
