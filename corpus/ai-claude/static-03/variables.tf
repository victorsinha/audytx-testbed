variable "aws_region" {
  description = "AWS region for the S3 buckets. CloudFront itself is global."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket holding the static site. The log bucket is named \"<bucket_name>-logs\"."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class controlling which edge locations are used."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "price_class must be one of PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain access logs in the log bucket."
  type        = number
  default     = 90
}

variable "web_acl_id" {
  description = "Optional AWS WAFv2 web ACL ARN (must be in us-east-1/global scope) to associate with the distribution. Null disables WAF."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to taggable resources."
  type        = map(string)
  default     = {}
}
