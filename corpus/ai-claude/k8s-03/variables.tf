variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "app-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ). Node groups run here."
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ). Used for NAT gateways."
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
}

variable "general_instance_types" {
  description = "Instance types for the general workload node group."
  type        = list(string)
  default     = ["m5.large"]
}

variable "general_desired_size" {
  description = "Desired number of nodes in the general node group."
  type        = number
  default     = 2
}

variable "general_min_size" {
  description = "Minimum number of nodes in the general node group."
  type        = number
  default     = 2
}

variable "general_max_size" {
  description = "Maximum number of nodes in the general node group."
  type        = number
  default     = 5
}

variable "batch_instance_types" {
  description = "Instance types for the batch job node group."
  type        = list(string)
  default     = ["c5.xlarge"]
}

variable "batch_desired_size" {
  description = "Desired number of nodes in the batch node group."
  type        = number
  default     = 0
}

variable "batch_min_size" {
  description = "Minimum number of nodes in the batch node group."
  type        = number
  default     = 0
}

variable "batch_max_size" {
  description = "Maximum number of nodes in the batch node group."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
