variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "sideproject"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric/hyphen, 3-30 chars."
  }
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging)."
  type        = string
  default     = "prod"
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
    error_message = "az_count must be 2 or 3 for Multi-AZ resilience."
  }
}

variable "app_instance_type" {
  description = "EC2 instance type for the web app autoscaling group."
  type        = string
  default     = "t3.small"
}

variable "app_min_size" {
  description = "Minimum number of app instances."
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of app instances."
  type        = number
  default     = 4
}

variable "app_port" {
  description = "Port the web app listens on behind the load balancer."
  type        = number
  default     = 8080
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for RDS."
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper bound for RDS storage autoscaling in GiB."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "appadmin"
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the public load balancer. Defaults to the whole internet for a public web app; restrict if private."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate for HTTPS on the ALB. If empty, only HTTP:80 -> redirect is skipped and the listener is HTTP-only (not recommended). Provide one for production."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 90
}
