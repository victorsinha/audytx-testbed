variable "aws_region" {
  description = "AWS region for regional resources (the S3 bucket)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used to name resources."
  type        = string
  default     = "company-landing-page"
}

variable "domain_name" {
  description = "The custom domain for the landing page, e.g. www.example.com."
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the existing Route 53 hosted zone that owns domain_name. Used for ACM DNS validation and the alias record."
  type        = string
}

variable "default_root_object" {
  description = "Object served at the CDN root."
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Tags applied to all resources. environment is required so downstream tooling can reason about data sensitivity / blast radius."
  type        = map(string)
  default = {
    project     = "company-landing-page"
    environment = "production"
    managed_by  = "terraform"
  }
}
