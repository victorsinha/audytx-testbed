variable "aws_region" {
  description = "AWS region to deploy the mobile backend into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix all resources."
  type        = string
  default     = "mobileapp"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 365
}

variable "lambda_runtime" {
  description = "Lambda runtime for the API handler."
  type        = string
  default     = "nodejs20.x"
}

variable "alarm_email" {
  description = "Email address to receive operational alarm notifications. Leave empty to skip subscription."
  type        = string
  default     = ""
}
