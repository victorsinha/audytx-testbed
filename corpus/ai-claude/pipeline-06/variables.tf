variable "aws_region" {
  description = "AWS region to deploy the pipeline into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used in resource names."
  type        = string
  default     = "datalake"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}

# --- SQS ---
variable "max_receive_count" {
  description = "Times a message is delivered before moving to the DLQ."
  type        = number
  default     = 5
}

# --- S3 ---
variable "s3_landing_prefix" {
  description = "Key prefix under which the Lambda lands processed objects."
  type        = string
  default     = "raw"
}

# --- Lambda ---
variable "lambda_package_path" {
  description = "Path to the zipped Lambda deployment package."
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

variable "lambda_timeout" {
  description = "Lambda timeout in seconds. SQS visibility timeout is derived as 6x this value."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory in MB."
  type        = number
  default     = 256
}

variable "lambda_batch_size" {
  description = "Max number of SQS messages delivered to the function per invocation."
  type        = number
  default     = 10
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions / max event-source concurrency for the processor."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda log group."
  type        = number
  default     = 90
}
