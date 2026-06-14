output "alb_dns_name" {
  description = "Public DNS name of the load balancer. Point your domain's CNAME/ALIAS here."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB, for Route 53 alias records."
  value       = aws_lb.main.zone_id
}

output "db_endpoint" {
  description = "Connection endpoint for the MySQL RDS instance."
  value       = aws_db_instance.main.address
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}
