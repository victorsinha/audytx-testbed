output "api_endpoint" {
  description = "Invoke URL for the deployed stage."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.api.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.api.arn
}

output "lambda_alias_arn" {
  description = "ARN of the 'live' Lambda alias used by the API integration."
  value       = aws_lambda_alias.live.arn
}

output "dlq_url" {
  description = "URL of the Lambda dead-letter queue."
  value       = aws_sqs_queue.lambda_dlq.url
}
