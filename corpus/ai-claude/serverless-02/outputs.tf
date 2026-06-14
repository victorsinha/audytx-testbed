output "api_endpoint" {
  description = "Base invoke URL for the todo HTTP API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_function_name" {
  description = "Name of the API Lambda function."
  value       = aws_lambda_function.api.function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB todos table."
  value       = aws_dynamodb_table.todos.name
}
