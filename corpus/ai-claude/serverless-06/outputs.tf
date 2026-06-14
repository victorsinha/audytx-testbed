output "api_endpoint" {
  description = "Invoke URL for the HTTP API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_function_name" {
  description = "Name of the API Lambda function."
  value       = aws_lambda_function.api.function_name
}

output "dynamodb_table_name" {
  description = "Name of the image-metadata DynamoDB table."
  value       = aws_dynamodb_table.metadata.name
}

output "uploads_bucket_name" {
  description = "Name of the S3 uploads bucket."
  value       = aws_s3_bucket.uploads.id
}

output "lambda_dlq_url" {
  description = "URL of the Lambda dead-letter queue."
  value       = aws_sqs_queue.lambda_dlq.url
}
