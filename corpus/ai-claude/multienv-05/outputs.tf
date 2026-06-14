output "environment" {
  description = "The stack that was deployed."
  value       = var.environment
}

output "s3_bucket_name" {
  description = "Name of the private origin bucket."
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "ARN of the origin bucket."
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (use for cache invalidations)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "Default *.cloudfront.net domain for the distribution."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "site_url" {
  description = "URL to reach the site."
  value       = local.use_custom_domain ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.site.domain_name}"
}
