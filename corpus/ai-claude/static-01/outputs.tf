output "s3_bucket_name" {
  description = "Name of the private origin S3 bucket. Upload site assets here."
  value       = aws_s3_bucket.site.id
}

output "s3_bucket_arn" {
  description = "ARN of the origin S3 bucket."
  value       = aws_s3_bucket.site.arn
}

output "log_bucket_name" {
  description = "Name of the access-log S3 bucket."
  value       = aws_s3_bucket.logs.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (use for cache invalidations)."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name. Point your DNS CNAME/ALIAS here."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route 53 alias records."
  value       = aws_cloudfront_distribution.site.hosted_zone_id
}

output "website_url" {
  description = "Public URL of the static website."
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.site.domain_name}"
}
