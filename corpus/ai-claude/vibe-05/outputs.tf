output "alb_dns_name" {
  description = "Public DNS name of the load balancer. Point your domain's CNAME/alias here."
  value       = aws_lb.main.dns_name
}

output "data_bucket_name" {
  description = "Name of the S3 data bucket."
  value       = aws_s3_bucket.data.bucket
}

output "db_endpoint" {
  description = "RDS connection endpoint."
  value       = aws_db_instance.main.address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}
