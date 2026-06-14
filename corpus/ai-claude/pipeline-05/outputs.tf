output "kinesis_stream_name" {
  description = "Name of the Kinesis clickstream ingestion stream."
  value       = aws_kinesis_stream.clickstream.name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis clickstream ingestion stream."
  value       = aws_kinesis_stream.clickstream.arn
}

output "data_bucket" {
  description = "S3 bucket holding curated clickstream data."
  value       = aws_s3_bucket.data.id
}

output "athena_results_bucket" {
  description = "S3 bucket holding Athena query results."
  value       = aws_s3_bucket.athena_results.id
}

output "lambda_function_name" {
  description = "Name of the clickstream processor Lambda."
  value       = aws_lambda_function.processor.function_name
}

output "glue_database" {
  description = "Glue catalog database for clickstream tables."
  value       = aws_glue_catalog_database.clickstream.name
}

output "athena_workgroup" {
  description = "Athena workgroup for querying clickstream data."
  value       = aws_athena_workgroup.clickstream.name
}
