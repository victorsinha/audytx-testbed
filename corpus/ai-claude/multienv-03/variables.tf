variable "project" {
  description = "Project name, used for naming and tagging resources."
  type        = string
  default     = "example"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Which environment to deploy (selects an entry from env_config)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "ami_id" {
  description = "AMI ID for the instances. Leave null to use the latest Amazon Linux 2023 AMI."
  type        = string
  default     = null
}

# Per-environment instance sizing and counts. Each environment maps to its own
# instance_type and instance_count so the same code deploys differently sized
# fleets per environment.
variable "env_config" {
  description = "Per-environment instance size and count configuration."
  type = map(object({
    instance_type  = string
    instance_count = number
  }))

  default = {
    dev = {
      instance_type  = "t3.micro"
      instance_count = 1
    }
    staging = {
      instance_type  = "t3.small"
      instance_count = 2
    }
    prod = {
      instance_type  = "m5.large"
      instance_count = 4
    }
  }
}
