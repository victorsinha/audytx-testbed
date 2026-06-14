output "alb_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Route53 hosted zone ID of the ALB (for alias records)."
  value       = aws_lb.main.zone_id
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "autoscaling_group_name" {
  description = "Name of the app autoscaling group."
  value       = aws_autoscaling_group.app.name
}

output "db_endpoint" {
  description = "Connection endpoint (host:port) of the PostgreSQL instance."
  value       = aws_db_instance.postgres.endpoint
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}
