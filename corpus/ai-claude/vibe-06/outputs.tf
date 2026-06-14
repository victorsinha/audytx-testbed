output "alb_dns_name" {
  description = "Public DNS name of the load balancer. Point your domain's CNAME/ALIAS here."
  value       = aws_lb.app.dns_name
}

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)."
  value       = aws_db_instance.main.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding DB credentials. The app role can read it at runtime."
  value       = aws_secretsmanager_secret.db.arn
}

output "autoscaling_group_name" {
  description = "Name of the app Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}
