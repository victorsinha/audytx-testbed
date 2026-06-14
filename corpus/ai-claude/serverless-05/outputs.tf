output "api_endpoint" {
  description = "Base invoke URL for the HTTP API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "get_item_url" {
  description = "Example GET route (substitute {id})."
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/items/{id}"
}

output "create_item_url" {
  description = "POST route to create an item."
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/items"
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.items.name
}

output "read_lambda_name" {
  description = "Name of the read Lambda function."
  value       = aws_lambda_function.read.function_name
}

output "write_lambda_name" {
  description = "Name of the write Lambda function."
  value       = aws_lambda_function.write.function_name
}
