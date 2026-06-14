variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "serverless-api"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.project_name))
    error_message = "project_name must be 2-31 chars, lowercase alphanumeric or hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_mb" {
  description = "Memory (MB) allocated to each Lambda function."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days."
  type        = number
  default     = 365
}

variable "api_throttle_burst_limit" {
  description = "API Gateway stage-level throttling burst limit."
  type        = number
  default     = 100
}

variable "api_throttle_rate_limit" {
  description = "API Gateway stage-level throttling steady-state rate limit (requests/sec)."
  type        = number
  default     = 50
}
