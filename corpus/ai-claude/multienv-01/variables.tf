variable "project_name" {
  description = "Name of the project, used as a prefix for resource names."
  type        = string
  default     = "webapp"
}

variable "environment" {
  description = "Deployment environment. Drives per-environment sizing and naming."
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type for the web app servers."
  type        = string
  default     = "t3.small"
}

variable "instance_count" {
  description = "Number of web app instances to run."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "ami_id" {
  description = "AMI ID for the web app instances. If empty, the latest Amazon Linux 2023 AMI is used."
  type        = string
  default     = ""
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks permitted to reach SSH (port 22). Restrict this to known admin ranges; do not use 0.0.0.0/0."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}
