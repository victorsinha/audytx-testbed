output "s3_bucket_name" {
  description = "Name of the S3 bucket holding the static site content."
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "ARN of the static site S3 bucket."
  value       = aws_s3_bucket.site.arn
}

output "log_bucket_name" {
  description = "Name of the S3 bucket holding access logs."
  value       = aws_s3_bucket.logs.id
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.site.arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution (e.g. dxxxx.cloudfront.net)."
  value       = aws_cloudfront_distribution.site.domain_name
}
