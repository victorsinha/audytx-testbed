output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (ECS tasks + RDS)."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (NAT gateways)."
  value       = aws_subnet.public[*].id
}

output "alb_dns_name" {
  description = "Internal DNS name of the dashboard ALB."
  value       = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.main.name
}

output "rds_endpoint" {
  description = "RDS connection endpoint."
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS port."
  value       = aws_db_instance.main.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB master credentials."
  value       = aws_secretsmanager_secret.db.arn
}
