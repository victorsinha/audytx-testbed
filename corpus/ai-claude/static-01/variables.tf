variable "aws_region" {
  description = "AWS region for the S3 buckets (CloudFront is global)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used for resource naming and tags."
  type        = string
  default     = "static-site"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Optional custom domain (e.g. example.com). Leave empty to use the default CloudFront domain."
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional domain aliases (e.g. www.example.com) to serve from the distribution."
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 for the custom domain. Required if domain_name is set."
  type        = string
  default     = ""
}

variable "web_acl_arn" {
  description = "Optional AWS WAFv2 web ACL ARN (must be CLOUDFRONT scope, in us-east-1) to attach to the distribution."
  type        = string
  default     = ""
}

variable "index_document" {
  description = "Default root object served by CloudFront."
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Object served for 403/404 responses."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class controlling edge-location coverage."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be one of PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "log_retention_days" {
  description = "Days to retain access logs before expiry."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Additional tags merged onto every resource."
  type        = map(string)
  default     = {}
}
