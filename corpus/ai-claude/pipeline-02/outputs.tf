output "queue_url" {
  description = "URL of the main SQS queue producers should write to."
  value       = aws_sqs_queue.main.id
}

output "queue_arn" {
  description = "ARN of the main SQS queue."
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.id
}

output "lambda_function_name" {
  description = "Name of the SQS consumer Lambda."
  value       = aws_lambda_function.consumer.function_name
}

output "redshift_endpoint" {
  description = "Redshift cluster endpoint (host:port)."
  value       = aws_redshift_cluster.this.endpoint
}

output "redshift_secret_arn" {
  description = "ARN of the Secrets Manager secret holding Redshift credentials."
  value       = aws_secretsmanager_secret.redshift.arn
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key encrypting the pipeline."
  value       = aws_kms_key.this.arn
}
