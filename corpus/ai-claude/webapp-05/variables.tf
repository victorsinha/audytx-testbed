variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as a prefix for resource names."
  type        = string
  default     = "flask-api"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public (ALB) subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for the private application subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for the private database subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "app_port" {
  description = "Port the Flask app listens on inside each instance."
  type        = number
  default     = 8000
}

variable "instance_type" {
  description = "EC2 instance type for the app tier."
  type        = string
  default     = "t3.small"
}

variable "asg_min_size" {
  description = "Minimum number of app instances."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of app instances."
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Desired number of app instances."
  type        = number
  default     = 2
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
  description = "Initial allocated storage for RDS in GiB."
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
  default     = "flaskdb"
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "flaskadmin"
}

variable "db_multi_az" {
  description = "Whether to run RDS in Multi-AZ for high availability."
  type        = bool
  default     = true
}

variable "allowed_https_cidrs" {
  description = "CIDR blocks allowed to reach the ALB over HTTPS."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate for the ALB HTTPS listener. Leave empty to disable the HTTPS listener."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch / ALB log retention in days."
  type        = number
  default     = 90
}
