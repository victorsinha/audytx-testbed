output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for Route 53 alias records)."
  value       = aws_lb.main.zone_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.app.name
}

output "aurora_cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster."
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster."
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Aurora master credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}
