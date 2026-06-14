output "queue_url" {
  description = "URL of the main email work queue (enqueue messages here)."
  value       = aws_sqs_queue.email.url
}

output "queue_arn" {
  description = "ARN of the main email work queue."
  value       = aws_sqs_queue.email.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.email_dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.email_dlq.arn
}

output "lambda_function_name" {
  description = "Name of the email worker Lambda function."
  value       = aws_lambda_function.email_worker.function_name
}

output "lambda_function_arn" {
  description = "ARN of the email worker Lambda function."
  value       = aws_lambda_function.email_worker.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting the queues and Lambda environment."
  value       = aws_kms_key.email_worker.arn
}
