variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "user-management"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "lambda_log_retention_days" {
  description = "CloudWatch Logs retention in days for the Lambda function."
  type        = number
  default     = 365
}

variable "api_log_retention_days" {
  description = "CloudWatch Logs retention in days for API Gateway access logs."
  type        = number
  default     = 365
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttling burst limit."
  type        = number
  default     = 50
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttling steady-state rate limit (requests/sec)."
  type        = number
  default     = 100
}
