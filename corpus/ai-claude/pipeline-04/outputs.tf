output "landing_bucket" {
  description = "Name of the S3 bucket where CSV files are uploaded."
  value       = aws_s3_bucket.landing.id
}

output "transformer_function_name" {
  description = "Name of the Lambda transformer function."
  value       = aws_lambda_function.transformer.function_name
}

output "transformer_dlq_url" {
  description = "URL of the dead-letter queue for failed transforms."
  value       = aws_sqs_queue.transformer_dlq.url
}

output "redshift_cluster_id" {
  description = "Identifier of the Redshift cluster."
  value       = aws_redshift_cluster.this.cluster_identifier
}

output "redshift_endpoint" {
  description = "Redshift cluster endpoint (host:port)."
  value       = aws_redshift_cluster.this.endpoint
}

output "redshift_secret_arn" {
  description = "Secrets Manager ARN holding Redshift master credentials."
  value       = aws_secretsmanager_secret.redshift.arn
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key encrypting the pipeline."
  value       = aws_kms_key.pipeline.arn
}
