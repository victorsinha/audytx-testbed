variable "aws_region" {
  description = "AWS region for regional resources such as the S3 origin bucket."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix and tag resources."
  type        = string
  default     = "react-spa"
}

variable "domain_name" {
  description = "Primary domain the SPA is served from (e.g. app.example.com)."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domains (SANs) to include on the certificate / CloudFront aliases."
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for the domain. Used for ACM DNS validation and the alias record."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class controlling which edge locations are used."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be one of PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "tags" {
  description = "Common tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
