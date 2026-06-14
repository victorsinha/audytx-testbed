variable "region" {
  description = "AWS region for the S3 origin bucket and supporting resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to derive resource names. Lowercase letters, numbers, and hyphens."
  type        = string
  default     = "static-site"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "default_root_object" {
  description = "Object CloudFront returns for requests to the distribution root."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront price class controlling which edge locations serve content."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be one of PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "tags" {
  description = "Tags applied to all resources. environment is used by downstream tooling."
  type        = map(string)
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
