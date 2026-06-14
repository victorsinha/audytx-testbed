variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "rails-app"
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging)."
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (ALB). One per AZ."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for the private application subnets (EC2). One per AZ."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for the private database subnets (RDS). One per AZ."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the Rails app servers."
  type        = string
  default     = "t3.small"
}

variable "app_min_size" {
  description = "Minimum number of app instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum number of app instances in the Auto Scaling Group."
  type        = number
  default     = 4
}

variable "app_desired_capacity" {
  description = "Desired number of app instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port the Rails app (e.g. Puma) listens on."
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "HTTP path the ALB uses for target health checks."
  type        = string
  default     = "/up"
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate for HTTPS on the ALB. If empty, only HTTP (port 80) is served and a TODO is left for HTTPS. Strongly recommended to set this in production."
  type        = string
  default     = ""
}

variable "db_engine_version" {
  description = "MySQL engine version for RDS."
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage (GiB) for RDS."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper limit (GiB) for RDS storage autoscaling."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the application database created on the RDS instance."
  type        = string
  default     = "rails_production"
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "rails"
}

variable "db_multi_az" {
  description = "Whether to deploy RDS in Multi-AZ for high availability."
  type        = bool
  default     = true
}

variable "db_backup_retention_days" {
  description = "Number of days to retain automated RDS backups."
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Enable deletion protection on the RDS instance."
  type        = bool
  default     = true
}
