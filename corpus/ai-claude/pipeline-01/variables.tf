##############################################
# Input variables
##############################################

variable "aws_region" {
  description = "AWS region to deploy the pipeline into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used to name resources."
  type        = string
  default     = "events"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric with hyphens only."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}

# --- Kinesis ---

variable "kinesis_retention_hours" {
  description = "Hours to retain records in the Kinesis stream (24-8760)."
  type        = number
  default     = 24

  validation {
    condition     = var.kinesis_retention_hours >= 24 && var.kinesis_retention_hours <= 8760
    error_message = "kinesis_retention_hours must be between 24 and 8760."
  }
}

# --- Lambda ---

variable "lambda_package_path" {
  description = "Path to the Lambda deployment package (.zip) produced by CI."
  type        = string
  default     = "build/processor.zip"
}

variable "lambda_handler" {
  description = "Lambda handler entrypoint."
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_size" {
  description = "Lambda memory allocation in MB."
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 60
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for the processor function."
  type        = number
  default     = 10
}

variable "lambda_batch_size" {
  description = "Max records per batch delivered from Kinesis to Lambda."
  type        = number
  default     = 100
}

# --- Observability ---

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda log group."
  type        = number
  default     = 365
}
