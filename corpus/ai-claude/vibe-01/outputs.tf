output "api_endpoint" {
  description = "Public base URL for the HTTP API."
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "lambda_function_name" {
  description = "Name of the backend Lambda function."
  value       = aws_lambda_function.backend.function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB data table."
  value       = aws_dynamodb_table.main.name
}

output "dlq_url" {
  description = "URL of the Lambda dead-letter queue."
  value       = aws_sqs_queue.dlq.id
}

output "kms_key_arn" {
  description = "ARN of the customer-managed encryption key."
  value       = aws_kms_key.main.arn
}

output "vpc_id" {
  description = "ID of the VPC the backend runs in."
  value       = aws_vpc.main.id
}
