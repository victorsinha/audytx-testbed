variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "wordpress"
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

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public (ALB) subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for the private application (EC2) subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for the private database (RDS) subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the WordPress web tier."
  type        = string
  default     = "t3.small"
}

variable "db_instance_class" {
  description = "RDS instance class for the MySQL database."
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "Initial WordPress database name."
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "Master username for the MySQL database."
  type        = string
  default     = "wpadmin"
}

variable "db_allocated_storage" {
  description = "Allocated storage (GB) for the RDS instance."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper limit (GB) for RDS storage autoscaling."
  type        = number
  default     = 100
}

variable "allowed_https_cidrs" {
  description = "CIDR blocks permitted to reach the load balancer over HTTPS. Defaults to the public internet for a public site."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate for the ALB HTTPS listener. Required to terminate TLS at the load balancer."
  type        = string
}

variable "ssh_key_name" {
  description = "Optional EC2 key pair name. Leave null to rely solely on SSM Session Manager for access."
  type        = string
  default     = null
}
