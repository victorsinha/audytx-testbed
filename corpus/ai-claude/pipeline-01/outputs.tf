##############################################
# Outputs
##############################################

output "kinesis_stream_name" {
  description = "Name of the Kinesis ingest stream."
  value       = aws_kinesis_stream.ingest.name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis ingest stream."
  value       = aws_kinesis_stream.ingest.arn
}

output "lambda_function_name" {
  description = "Name of the stream-processor Lambda function."
  value       = aws_lambda_function.processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the stream-processor Lambda function."
  value       = aws_lambda_function.processor.arn
}

output "results_bucket_name" {
  description = "Name of the S3 bucket holding processed results."
  value       = aws_s3_bucket.results.id
}

output "results_bucket_arn" {
  description = "ARN of the S3 results bucket."
  value       = aws_s3_bucket.results.arn
}

output "dlq_url" {
  description = "URL of the SQS dead-letter queue for failed batches."
  value       = aws_sqs_queue.dlq.id
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key encrypting the pipeline."
  value       = aws_kms_key.pipeline.arn
}
