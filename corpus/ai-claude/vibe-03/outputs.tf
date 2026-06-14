output "alb_dns_name" {
  description = "Public DNS name of the application load balancer. Point your domain's CNAME/alias here."
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "Route53 hosted zone ID of the ALB (for alias records)."
  value       = aws_lb.app.zone_id
}

output "ecr_repository_url" {
  description = "Push your application image here, then update var.container_image."
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "app_bucket_name" {
  description = "S3 bucket for application data."
  value       = aws_s3_bucket.app.id
}

output "db_endpoint" {
  description = "RDS connection endpoint (host:port)."
  value       = aws_db_instance.main.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB credentials JSON."
  value       = aws_secretsmanager_secret.db.arn
}

output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}
