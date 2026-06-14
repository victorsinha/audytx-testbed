variable "aws_region" {
  description = "AWS region to deploy the ETL pipeline into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "etl-pipeline"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod). Drives tag-based context."
  type        = string
  default     = "prod"
}

variable "lambda_runtime" {
  description = "Runtime for the transform Lambda."
  type        = string
  default     = "python3.12"
}

variable "lambda_handler" {
  description = "Handler entrypoint for the transform Lambda."
  type        = string
  default     = "transform.handler"
}

variable "lambda_source_dir" {
  description = "Local directory containing the Lambda source to package."
  type        = string
  default     = "./src/transform"
}

variable "lambda_memory_mb" {
  description = "Memory allocated to the transform Lambda."
  type        = number
  default     = 512
}

variable "lambda_timeout_seconds" {
  description = "Timeout for the transform Lambda."
  type        = number
  default     = 300
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for the Lambda log group."
  type        = number
  default     = 365
}

variable "redshift_node_type" {
  description = "Redshift node type."
  type        = string
  default     = "ra3.xlplus"
}

variable "redshift_number_of_nodes" {
  description = "Number of compute nodes (>=2 selects multi-node)."
  type        = number
  default     = 2
}

variable "redshift_database_name" {
  description = "Initial Redshift database name."
  type        = string
  default     = "analytics"
}

variable "redshift_master_username" {
  description = "Redshift master username. The password is generated and stored in Secrets Manager; it is never set in Terraform variables or state in plaintext."
  type        = string
  default     = "etl_admin"
}

variable "vpc_id" {
  description = "VPC in which to place the Redshift cluster."
  type        = string
}

variable "redshift_subnet_ids" {
  description = "Private subnet IDs (>= 2 AZs) for the Redshift subnet group."
  type        = list(string)

  validation {
    condition     = length(var.redshift_subnet_ids) >= 2
    error_message = "Provide at least two subnet IDs across distinct AZs."
  }
}

variable "redshift_allowed_cidr_blocks" {
  description = "CIDR blocks permitted to reach Redshift on 5439. Keep this to internal/VPC ranges; do not use 0.0.0.0/0."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.redshift_allowed_cidr_blocks, "0.0.0.0/0")
    error_message = "Redshift must not be reachable from 0.0.0.0/0."
  }
}
