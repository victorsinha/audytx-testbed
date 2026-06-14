variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier, used as a name prefix for all resources."
  type        = string
  default     = "img-worker"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

##############################################################################
# S3 lifecycle
##############################################################################

variable "uploads_retention_days" {
  description = "Days to keep raw uploads before expiring them."
  type        = number
  default     = 30
}

##############################################################################
# Lambda
##############################################################################

variable "lambda_artifact_bucket" {
  description = "S3 bucket holding the Lambda deployment package (built by CI)."
  type        = string
}

variable "lambda_artifact_key" {
  description = "S3 key of the Lambda deployment package zip."
  type        = string
}

variable "lambda_handler" {
  description = "Lambda handler entrypoint."
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_timeout_seconds" {
  description = "Lambda timeout in seconds. Queue visibility timeout is derived from this (6x)."
  type        = number
  default     = 60
}

variable "lambda_memory_mb" {
  description = "Lambda memory in MB. Image resizing is memory/CPU bound, so default is generous."
  type        = number
  default     = 1024
}

variable "lambda_batch_size" {
  description = "Number of SQS messages delivered to the Lambda per invocation."
  type        = number
  default     = 10
}

variable "lambda_reserved_concurrency" {
  description = "Reserved/maximum concurrency for the resizer, to cap blast radius and downstream load."
  type        = number
  default     = 10
}

##############################################################################
# Observability
##############################################################################

variable "log_retention_days" {
  description = "CloudWatch log retention for the Lambda log group."
  type        = number
  default     = 30
}
