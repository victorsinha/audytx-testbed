variable "project_name" {
  description = "Name of the project, used as a prefix for resource names."
  type        = string
  default     = "serverless-api"
}

variable "environment" {
  description = "Deployment environment. Drives naming, sizing, and retention. Use a separate tfvars/workspace per environment."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_handler" {
  description = "Lambda function handler entrypoint."
  type        = string
  default     = "index.handler"
}

variable "lambda_source_zip" {
  description = "Path to the packaged Lambda deployment zip."
  type        = string
  default     = "build/function.zip"
}

variable "lambda_memory_size" {
  description = "Lambda memory (MB). Per-environment tuning via tfvars."
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10
}

variable "lambda_environment_variables" {
  description = "Additional environment variables injected into the Lambda function."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days. Typically shorter in dev, longer in prod."
  type        = number
  default     = 14
}

variable "api_throttling_burst_limit" {
  description = "API Gateway stage throttling burst limit."
  type        = number
  default     = 1000
}

variable "api_throttling_rate_limit" {
  description = "API Gateway stage throttling steady-state rate limit (req/s)."
  type        = number
  default     = 2000
}

variable "provisioned_concurrency" {
  description = "Provisioned concurrency for the Lambda alias. 0 disables it (cheaper in dev)."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Extra tags merged onto all resources."
  type        = map(string)
  default     = {}
}
