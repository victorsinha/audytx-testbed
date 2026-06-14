variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names."
  type        = string
  default     = "serverless-backend"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Python runtime for all Lambda functions."
  type        = string
  default     = "python3.12"
}

variable "lambda_memory_mb" {
  description = "Memory (MB) allocated to each Lambda function."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Timeout (seconds) for each Lambda function."
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days."
  type        = number
  default     = 14
}

# Map of logical function name -> handler entrypoint.
# Each entry produces one Lambda function and one HTTP API route.
variable "functions" {
  description = "Map of Lambda functions keyed by logical name. Each value defines its handler, HTTP method, and route path."
  type = map(object({
    handler = string # e.g. "create_item.handler"
    method  = string # e.g. "POST"
    path    = string # e.g. "/items"
  }))
  default = {
    create_item = {
      handler = "create_item.handler"
      method  = "POST"
      path    = "/items"
    }
    get_item = {
      handler = "get_item.handler"
      method  = "GET"
      path    = "/items/{id}"
    }
    list_items = {
      handler = "list_items.handler"
      method  = "GET"
      path    = "/items"
    }
  }
}

variable "cors_allow_origins" {
  description = "Allowed CORS origins for the HTTP API. Tighten this to your frontend origins in production; '*' is intentionally not the default."
  type        = list(string)
  default     = []
}
