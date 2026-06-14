output "bucket_name" {
  description = "Name of the S3 bucket holding the blog's static files."
  value       = aws_s3_bucket.blog.id
}

output "bucket_arn" {
  description = "ARN of the blog content bucket."
  value       = aws_s3_bucket.blog.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID (use for cache invalidations)."
  value       = aws_cloudfront_distribution.blog.id
}

output "distribution_domain_name" {
  description = "CloudFront domain name to access the blog (https://<this>)."
  value       = aws_cloudfront_distribution.blog.domain_name
}
