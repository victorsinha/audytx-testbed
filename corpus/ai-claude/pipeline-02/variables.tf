variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix applied to all resource names."
  type        = string
  default     = "sqs-redshift-stream"
}

variable "environment" {
  description = "Deployment environment (used for tagging and context)."
  type        = string
  default     = "production"
}

variable "vpc_id" {
  description = "VPC the Lambda and Redshift cluster live in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the Lambda ENIs and the Redshift subnet group. Must reach Redshift; no public route."
  type        = list(string)
}

variable "lambda_source_path" {
  description = "Path to the zipped Lambda deployment package."
  type        = string
  default     = "build/handler.zip"
}

variable "lambda_handler" {
  description = "Lambda handler entrypoint."
  type        = string
  default     = "handler.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "redshift_master_username" {
  description = "Redshift admin username."
  type        = string
  default     = "admin"
}

variable "redshift_database_name" {
  description = "Initial Redshift database name."
  type        = string
  default     = "analytics"
}

variable "redshift_node_type" {
  description = "Redshift node type."
  type        = string
  default     = "ra3.xlplus"
}

variable "redshift_cluster_type" {
  description = "single-node or multi-node."
  type        = string
  default     = "single-node"
}

variable "sqs_batch_size" {
  description = "Max messages the event source mapping delivers per Lambda invocation."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default     = {}
}
