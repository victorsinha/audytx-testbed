variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources."
  type        = string
  default     = "items-api"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Node.js runtime for the Lambda functions."
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_memory_size" {
  description = "Memory (MB) allocated to each Lambda function."
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Timeout (seconds) for each Lambda function."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days for Lambda log groups."
  type        = number
  default     = 14
}
