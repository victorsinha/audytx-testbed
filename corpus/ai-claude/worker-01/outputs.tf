output "jobs_queue_url" {
  description = "URL of the main job queue (send messages here)."
  value       = aws_sqs_queue.jobs.id
}

output "jobs_queue_arn" {
  description = "ARN of the main job queue."
  value       = aws_sqs_queue.jobs.arn
}

output "jobs_dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.jobs_dlq.id
}

output "jobs_dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.jobs_dlq.arn
}

output "processor_function_name" {
  description = "Name of the Lambda processor function."
  value       = aws_lambda_function.processor.function_name
}

output "processor_function_arn" {
  description = "ARN of the Lambda processor function."
  value       = aws_lambda_function.processor.arn
}

output "kms_key_arn" {
  description = "ARN of the CMK encrypting the queues and Lambda."
  value       = aws_kms_key.jobs.arn
}
