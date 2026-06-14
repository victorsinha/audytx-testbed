output "queue_url" {
  description = "URL of the main SQS queue producers should send to."
  value       = aws_sqs_queue.main.url
}

output "queue_arn" {
  description = "ARN of the main SQS queue."
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "lambda_function_name" {
  description = "Name of the processor Lambda function."
  value       = aws_lambda_function.processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the processor Lambda function."
  value       = aws_lambda_function.processor.arn
}

output "data_lake_bucket" {
  description = "Name of the S3 data-lake bucket."
  value       = aws_s3_bucket.data_lake.id
}

output "data_lake_bucket_arn" {
  description = "ARN of the S3 data-lake bucket."
  value       = aws_s3_bucket.data_lake.arn
}

output "kms_key_arn" {
  description = "ARN of the CMK encrypting the pipeline."
  value       = aws_kms_key.pipeline.arn
}
