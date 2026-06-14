variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "csv-to-redshift"
}

variable "tags" {
  description = "Common tags applied to all resources. Set environment to drive context-aware policy."
  type        = map(string)
  default = {
    Project     = "csv-to-redshift"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

variable "redshift_database_name" {
  description = "Initial database created in the Redshift cluster."
  type        = string
  default     = "analytics"
}

variable "redshift_master_username" {
  description = "Master username for the Redshift cluster."
  type        = string
  default     = "admin"
}

variable "redshift_node_type" {
  description = "Redshift node type."
  type        = string
  default     = "ra3.xlplus"
}

variable "redshift_number_of_nodes" {
  description = "Number of compute nodes in the Redshift cluster."
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC hosting the Redshift cluster and Lambda."
  type        = string
  default     = "10.40.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)."
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda log group."
  type        = number
  default     = 365
}
