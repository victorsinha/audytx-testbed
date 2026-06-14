output "api_endpoint" {
  description = "Base invoke URL for the HTTP API."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB items table."
  value       = aws_dynamodb_table.items.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB items table."
  value       = aws_dynamodb_table.items.arn
}

output "lambda_function_names" {
  description = "Map of logical name to deployed Lambda function name."
  value       = { for k, fn in aws_lambda_function.this : k => fn.function_name }
}

output "kms_key_arn" {
  description = "ARN of the customer-managed CMK."
  value       = aws_kms_key.this.arn
}
