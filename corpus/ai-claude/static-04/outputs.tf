output "bucket_name" {
  description = "Name of the S3 origin bucket. Upload site files here."
  value       = aws_s3_bucket.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront-generated domain (before DNS propagation of the custom domain)."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  description = "Distribution ID, useful for cache invalidations on deploy."
  value       = aws_cloudfront_distribution.site.id
}

output "site_url" {
  description = "The public HTTPS URL of the landing page."
  value       = "https://${var.domain_name}"
}
