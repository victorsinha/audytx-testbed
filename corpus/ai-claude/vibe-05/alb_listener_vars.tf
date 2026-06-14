variable "certificate_arn" {
  description = "ARN of an ACM certificate for the HTTPS listener. Required for the ALB HTTPS listener."
  type        = string
}
