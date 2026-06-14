variable "region" {
  description = "AWS region to deploy the job system into."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used as a resource name prefix."
  type        = string
  default     = "jobsys"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags applied to every resource."
  type        = map(string)
  default     = {}
}

# --- SQS -------------------------------------------------------------------

variable "job_retention_seconds" {
  description = "How long an unprocessed job stays in the main queue."
  type        = number
  default     = 345600 # 4 days
}

variable "max_receive_count" {
  description = "Times a job is delivered to the consumer before redrive to the DLQ."
  type        = number
  default     = 5
}

# --- Lambda consumer -------------------------------------------------------

variable "consumer_package_path" {
  description = "Path to the consumer Lambda deployment package (.zip)."
  type        = string
  default     = "build/consumer.zip"
}

variable "consumer_handler" {
  description = "Consumer Lambda handler entrypoint."
  type        = string
  default     = "index.handler"
}

variable "consumer_runtime" {
  description = "Consumer Lambda runtime."
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_timeout_seconds" {
  description = "Consumer function timeout. Queue visibility timeout is derived as 6x this."
  type        = number
  default     = 30

  validation {
    condition     = var.lambda_timeout_seconds >= 1 && var.lambda_timeout_seconds <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_memory_mb" {
  description = "Consumer function memory (MB)."
  type        = number
  default     = 256
}

variable "consumer_max_concurrency" {
  description = "Max concurrent consumer invocations (reserved concurrency + ESM scaling cap)."
  type        = number
  default     = 10

  validation {
    condition     = var.consumer_max_concurrency >= 2
    error_message = "SQS event source mapping maximum_concurrency must be at least 2."
  }
}

variable "batch_size" {
  description = "Max jobs delivered to the consumer per invocation."
  type        = number
  default     = 10
}

variable "max_batching_window_seconds" {
  description = "Max time the poller waits to fill a batch before invoking."
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the consumer function."
  type        = number
  default     = 14
}
