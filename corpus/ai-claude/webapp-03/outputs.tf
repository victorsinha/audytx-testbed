output "alb_dns_name" {
  description = "Public DNS name of the ALB. Point your app's DNS record here."
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB, for Route 53 alias records."
  value       = aws_lb.app.zone_id
}

output "rds_endpoint" {
  description = "Connection endpoint (host:port) for the MySQL RDS instance."
  value       = aws_db_instance.main.endpoint
}

output "rds_database_name" {
  description = "Name of the application database."
  value       = aws_db_instance.main.db_name
}

output "db_master_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master credentials. Grant the app role read access and fetch DB_PASSWORD from here."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "app_security_group_id" {
  description = "Security group ID attached to the app instances."
  value       = aws_security_group.app.id
}
