output "api_endpoint" {
  description = "Base URL of the mobile backend HTTP API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID for the mobile client."
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito app client ID used by the mobile app."
  value       = aws_cognito_user_pool_client.mobile.id
}

output "dynamodb_table_name" {
  description = "Primary application DynamoDB table."
  value       = aws_dynamodb_table.app.name
}

output "media_bucket_name" {
  description = "S3 bucket for user media/assets."
  value       = aws_s3_bucket.media.bucket
}

output "jobs_queue_url" {
  description = "SQS queue URL for async background jobs."
  value       = aws_sqs_queue.jobs.url
}
