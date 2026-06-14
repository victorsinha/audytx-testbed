variable "project_name" {
  description = "Short name used to prefix and tag all resources."
  type        = string
  default     = "app-backend"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,30}$", var.project_name))
    error_message = "project_name must be 2-30 chars of lowercase letters, digits, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 for multi-AZ resilience."
  }
}

variable "lambda_runtime" {
  description = "Runtime for the backend Lambda function."
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_memory_mb" {
  description = "Memory (MB) allocated to the backend Lambda."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Timeout (seconds) for the backend Lambda."
  type        = number
  default     = 15
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days."
  type        = number
  default     = 30
}
