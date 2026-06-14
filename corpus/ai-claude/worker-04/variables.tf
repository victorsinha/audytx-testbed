variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "email-worker"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod). Used for tagging."
  type        = string
  default     = "dev"
}

variable "email_from_address" {
  description = "Verified SES identity (email address or domain) that the worker sends from."
  type        = string
}

variable "lambda_timeout_seconds" {
  description = "Lambda execution timeout. The source queue visibility timeout is derived as 6x this value."
  type        = number
  default     = 30
}

variable "max_receive_count" {
  description = "Number of delivery attempts before a message is moved to the DLQ."
  type        = number
  default     = 5
}

variable "reserved_concurrency" {
  description = "Reserved/maximum concurrent Lambda executions. Bounds the send rate to the email provider."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
