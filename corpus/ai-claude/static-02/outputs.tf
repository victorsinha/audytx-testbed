output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution (use for cache invalidations on deploy)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "The *.cloudfront.net domain name of the distribution."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "site_bucket_name" {
  description = "Name of the S3 bucket holding the SPA build artifacts (sync your build/ here)."
  value       = aws_s3_bucket.site.id
}

output "site_url" {
  description = "Primary HTTPS URL the SPA is served from."
  value       = "https://${var.domain_name}"
}
