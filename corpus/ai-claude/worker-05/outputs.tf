output "job_queue_url" {
  description = "URL of the primary job queue (producers send here)."
  value       = aws_sqs_queue.jobs.url
}

output "job_queue_arn" {
  description = "ARN of the primary job queue."
  value       = aws_sqs_queue.jobs.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue holding jobs that exhausted retries."
  value       = aws_sqs_queue.jobs_dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.jobs_dlq.arn
}

output "consumer_function_name" {
  description = "Name of the consumer Lambda function."
  value       = aws_lambda_function.consumer.function_name
}

output "consumer_function_arn" {
  description = "ARN of the consumer Lambda function."
  value       = aws_lambda_function.consumer.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting the queues and logs."
  value       = aws_kms_key.jobs.arn
}
