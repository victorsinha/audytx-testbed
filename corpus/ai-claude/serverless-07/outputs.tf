output "api_endpoint" {
  description = "Base invoke URL for the CRUD API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_function_name" {
  description = "Name of the CRUD Lambda function."
  value       = aws_lambda_function.crud.function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.items.name
}

output "lambda_dlq_url" {
  description = "URL of the Lambda dead-letter queue."
  value       = aws_sqs_queue.lambda_dlq.url
}
