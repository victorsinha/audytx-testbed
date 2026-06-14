variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate for the internal dashboard HTTPS listener. Use a cert issued for the dashboard's internal hostname (public ACM or ACM Private CA)."
  type        = string
}
