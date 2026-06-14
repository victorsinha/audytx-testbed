variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (used for tagging)."
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "app-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of AZs to spread subnets across."
  type        = number
  default     = 3
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes (autoscaling floor)."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes (autoscaling ceiling)."
  type        = number
  default     = 6
}

variable "node_disk_size" {
  description = "EBS volume size (GiB) for each worker node."
  type        = number
  default     = 50
}

variable "public_access_cidrs" {
  description = "CIDRs permitted to reach the public EKS API endpoint. Restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_retention_days" {
  description = "Retention period (days) for the EKS control-plane CloudWatch log group."
  type        = number
  default     = 90
}
