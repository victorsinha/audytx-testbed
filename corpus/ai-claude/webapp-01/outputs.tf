output "alb_dns_name" {
  description = "Public DNS name of the application load balancer. Point your DNS CNAME/alias here."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB, for Route53 alias records."
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

output "db_endpoint" {
  description = "RDS Postgres connection endpoint (host:port)."
  value       = aws_db_instance.main.endpoint
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}
