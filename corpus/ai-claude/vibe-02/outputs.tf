output "alb_dns_name" {
  description = "Public DNS name of the application load balancer. Point your domain's CNAME/ALIAS here."
  value       = aws_lb.this.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)."
  value       = aws_db_instance.this.endpoint
}

output "db_password_secret_arn" {
  description = "Secrets Manager ARN holding the generated DB password."
  value       = aws_secretsmanager_secret.db_password.arn
}

output "assets_bucket" {
  description = "Name of the S3 assets bucket."
  value       = aws_s3_bucket.assets.bucket
}
