output "uploads_bucket_name" {
  description = "Name of the S3 bucket where raw images are uploaded."
  value       = aws_s3_bucket.uploads.bucket
}

output "uploads_bucket_arn" {
  description = "ARN of the uploads S3 bucket."
  value       = aws_s3_bucket.uploads.arn
}

output "output_bucket_name" {
  description = "Name of the S3 bucket where resized images are written."
  value       = aws_s3_bucket.output.bucket
}

output "output_bucket_arn" {
  description = "ARN of the output S3 bucket."
  value       = aws_s3_bucket.output.arn
}

output "queue_url" {
  description = "URL of the SQS upload-event queue."
  value       = aws_sqs_queue.uploads.id
}

output "queue_arn" {
  description = "ARN of the SQS upload-event queue."
  value       = aws_sqs_queue.uploads.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.id
}

output "lambda_function_name" {
  description = "Name of the resizer Lambda function."
  value       = aws_lambda_function.resizer.function_name
}

output "lambda_function_arn" {
  description = "ARN of the resizer Lambda function."
  value       = aws_lambda_function.resizer.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting buckets, queues, and logs."
  value       = aws_kms_key.this.arn
}
