output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA cert for the cluster (for kubeconfig)."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL used for IRSA."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA role trust policies."
  value       = aws_iam_openid_connect_provider.oidc.arn
}

output "node_group_name" {
  description = "Name of the managed node group running the apps."
  value       = aws_eks_node_group.apps.node_group_name
}

output "vpc_id" {
  description = "ID of the VPC hosting the cluster."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs where worker nodes run."
  value       = aws_subnet.private[*].id
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl against the new cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}"
}
