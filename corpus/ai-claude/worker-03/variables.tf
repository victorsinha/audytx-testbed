variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Base name applied to the queue, Lambda, and related resources."
  type        = string
  default     = "queue-worker"
}

variable "lambda_runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds. Queue visibility timeout is derived from this (6x)."
  type        = number
  default     = 30
}

variable "batch_size" {
  description = "Maximum number of SQS messages delivered to the function per invocation."
  type        = number
  default     = 10
}

variable "max_concurrency" {
  description = "Maximum number of concurrent Lambda invocations the event source mapping will drive (2-1000)."
  type        = number
  default     = 10
}

variable "reserved_concurrency" {
  description = "Reserved concurrency for the function. -1 = unreserved (account pool)."
  type        = number
  default     = -1
}

variable "max_receive_count" {
  description = "Number of processing attempts before a message is moved to the dead-letter queue."
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days for the Lambda log group."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "queue-worker"
    ManagedBy = "terraform"
  }
}
