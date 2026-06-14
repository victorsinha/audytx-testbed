variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "todo-app"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Lambda runtime for the API handler."
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_memory_mb" {
  description = "Memory (MB) allocated to the Lambda function."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Lambda execution timeout in seconds."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days."
  type        = number
  default     = 14
}
