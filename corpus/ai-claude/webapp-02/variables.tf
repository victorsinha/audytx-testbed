variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "internal-dashboard"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "az_count must be at least 2 so RDS Multi-AZ and the ALB can span zones."
  }
}

variable "internal_access_cidrs" {
  description = "CIDR blocks permitted to reach the internal dashboard ALB (e.g. corporate VPN / office ranges). Defaults to RFC1918 so the dashboard is never exposed to the public internet."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "container_image" {
  description = "Container image for the dashboard service."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "container_port" {
  description = "Port the dashboard container listens on."
  type        = number
  default     = 8080
}

variable "service_desired_count" {
  description = "Number of ECS tasks to run."
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 1024
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "dashboard"
}

variable "db_username" {
  description = "Master username for RDS."
  type        = string
  default     = "dashboard_admin"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.4"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB."
  type        = number
  default     = 100
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the ECS service."
  type        = number
  default     = 90
}
