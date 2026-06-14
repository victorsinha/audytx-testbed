variable "region" {
  description = "AWS region for the S3 bucket and supporting resources."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket that holds the blog's static files."
  type        = string
}

variable "default_root_object" {
  description = "Object served when a viewer requests the root URL (e.g. index.html)."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class controlling which edge locations are used."
  type        = string
  default     = "PriceClass_100"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudFront access logs in the log bucket before expiry."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "blog"
    ManagedBy = "terraform"
  }
}
