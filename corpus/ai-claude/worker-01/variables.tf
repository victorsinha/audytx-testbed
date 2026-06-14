variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "async-jobs"
}

variable "max_receive_count" {
  description = "Times a message can be received before it is moved to the DLQ."
  type        = number
  default     = 5
}

variable "lambda_filename" {
  description = "Path to the Lambda deployment package (.zip)."
  type        = string
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
  description = "Lambda function timeout in seconds. Queue visibility timeout is derived as 6x this value."
  type        = number
  default     = 30
}

variable "reserved_concurrency" {
  description = "Reserved/maximum concurrent Lambda executions, also used as the event source mapping max concurrency. Bounds queue-driven fan-out."
  type        = number
  default     = 10
}
