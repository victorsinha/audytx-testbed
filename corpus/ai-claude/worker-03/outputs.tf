output "queue_url" {
  description = "URL of the primary work queue."
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "ARN of the primary work queue."
  value       = aws_sqs_queue.this.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.id
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "lambda_function_name" {
  description = "Name of the worker Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the worker Lambda function."
  value       = aws_lambda_function.this.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the queues and logs."
  value       = aws_kms_key.this.arn
}
