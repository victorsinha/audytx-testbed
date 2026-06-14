variable "environment" {
  description = "Which stack to deploy. This is the single variable that selects dev vs prod; per-environment settings are looked up from local.env_config."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be one of: dev, prod."
  }
}

variable "project_name" {
  description = "Base name for the site; combined with environment to name resources."
  type        = string
  default     = "mysite"
}

variable "aws_region" {
  description = "Region for the S3 origin bucket and most resources."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Custom domain for the CloudFront distribution (e.g. example.com). Leave empty to use the default *.cloudfront.net domain with the default certificate."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of an existing ACM certificate in us-east-1 to use for the custom domain. Required only when domain_name is set and you are not creating the certificate elsewhere."
  type        = string
  default     = ""
}
