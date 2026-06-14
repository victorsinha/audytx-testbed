output "raw_bucket_name" {
  description = "Name of the S3 raw data bucket."
  value       = aws_s3_bucket.raw.id
}

output "raw_bucket_arn" {
  description = "ARN of the S3 raw data bucket."
  value       = aws_s3_bucket.raw.arn
}

output "transform_lambda_name" {
  description = "Name of the transform Lambda function."
  value       = aws_lambda_function.transform.function_name
}

output "transform_lambda_arn" {
  description = "ARN of the transform Lambda function."
  value       = aws_lambda_function.transform.arn
}

output "redshift_cluster_endpoint" {
  description = "Redshift cluster endpoint (host:port)."
  value       = aws_redshift_cluster.analytics.endpoint
}

output "redshift_database_name" {
  description = "Initial Redshift database name."
  value       = aws_redshift_cluster.analytics.database_name
}

output "redshift_master_secret_arn" {
  description = "Secrets Manager ARN holding the Redshift master credentials."
  value       = aws_secretsmanager_secret.redshift_master.arn
}

output "kms_key_arn" {
  description = "ARN of the ETL data-at-rest KMS key."
  value       = aws_kms_key.etl.arn
}
