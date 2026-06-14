output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS Kubernetes API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "general_node_group_arn" {
  description = "ARN of the general workload node group."
  value       = aws_eks_node_group.general.arn
}

output "batch_node_group_arn" {
  description = "ARN of the batch job node group."
  value       = aws_eks_node_group.batch.arn
}

output "vpc_id" {
  description = "ID of the VPC created for the cluster."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets hosting the node groups."
  value       = aws_subnet.private[*].id
}
