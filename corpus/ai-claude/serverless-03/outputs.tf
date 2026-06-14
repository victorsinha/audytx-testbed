output "api_endpoint" {
  description = "Base invoke URL for the HTTP API ($default stage)."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.items.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table."
  value       = aws_dynamodb_table.items.arn
}

output "lambda_function_names" {
  description = "Map of logical name -> deployed Lambda function name."
  value       = { for k, fn in aws_lambda_function.this : k => fn.function_name }
}

output "routes" {
  description = "Map of logical name -> HTTP route key wired into the API."
  value       = { for k, r in aws_apigatewayv2_route.this : k => r.route_key }
}
