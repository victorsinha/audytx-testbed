variable "region" {
  description = "AWS region to deploy the EKS cluster into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "apps"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod). Drives tagging."
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "apps-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the EKS VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private (node) subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public (NAT/ELB) subnets, one per AZ."
  type        = list(string)
  default     = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server endpoint is reachable from the public internet. Kept on for kubectl access; restrict via the CIDR list below."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Override with your office/VPN ranges; the open default is intentionally flagged for review."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 6
}

variable "node_disk_size" {
  description = "EBS root volume size (GiB) for worker nodes."
  type        = number
  default     = 50
}
