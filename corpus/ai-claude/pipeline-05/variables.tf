variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "clickstream"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "kinesis_shard_count" {
  description = "Number of shards for the Kinesis data stream."
  type        = number
  default     = 2
}

variable "kinesis_retention_hours" {
  description = "Data retention period for the Kinesis stream, in hours."
  type        = number
  default     = 24
}

variable "lambda_runtime" {
  description = "Lambda runtime for the processor function."
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_mb" {
  description = "Memory (MB) allocated to the processor Lambda."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Timeout (seconds) for the processor Lambda."
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda log group."
  type        = number
  default     = 90
}
