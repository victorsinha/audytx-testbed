output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (e.g. d111111abcdef8.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID, useful for cache invalidations."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "origin_bucket_name" {
  description = "Name of the private S3 origin bucket. Upload site assets here."
  value       = aws_s3_bucket.origin.id
}

output "origin_bucket_arn" {
  description = "ARN of the S3 origin bucket."
  value       = aws_s3_bucket.origin.arn
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket holding CloudFront and S3 access logs."
  value       = aws_s3_bucket.logs.id
}
