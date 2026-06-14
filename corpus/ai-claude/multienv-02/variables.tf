variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "app"
}

variable "vpc_cidr_by_env" {
  description = "VPC CIDR block per workspace/environment."
  type        = map(string)
  default = {
    dev     = "10.10.0.0/16"
    staging = "10.20.0.0/16"
    prod    = "10.30.0.0/16"
  }
}

variable "az_count" {
  description = "Number of Availability Zones to span (min 2 for RDS Multi-AZ)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "az_count must be at least 2 so the DB subnet group spans multiple AZs."
  }
}

variable "container_image" {
  description = "Container image (repo:tag) for the ECS service."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

# ---------------------------------------------------------------------------
# Per-environment sizing. Keyed by terraform.workspace so dev/staging/prod each
# get appropriate capacity, deletion protection, and backup posture from the
# SAME code. Looked up via the `env` local below.
# ---------------------------------------------------------------------------
variable "env_settings" {
  description = "Per-environment tuning, keyed by workspace name."
  type = map(object({
    ecs_task_cpu            = string
    ecs_task_memory        = string
    ecs_desired_count      = number
    db_instance_class      = string
    db_allocated_storage   = number
    db_max_allocated_storage = number
    db_multi_az            = bool
    db_backup_retention    = number
    db_deletion_protection = bool
    log_retention_days     = number
  }))
  default = {
    dev = {
      ecs_task_cpu             = "256"
      ecs_task_memory          = "512"
      ecs_desired_count        = 1
      db_instance_class        = "db.t3.small"
      db_allocated_storage     = 20
      db_max_allocated_storage = 50
      db_multi_az              = false
      db_backup_retention      = 7
      db_deletion_protection   = true
      log_retention_days       = 30
    }
    staging = {
      ecs_task_cpu             = "512"
      ecs_task_memory          = "1024"
      ecs_desired_count        = 2
      db_instance_class        = "db.t3.medium"
      db_allocated_storage     = 50
      db_max_allocated_storage = 100
      db_multi_az              = true
      db_backup_retention      = 14
      db_deletion_protection   = true
      log_retention_days       = 90
    }
    prod = {
      ecs_task_cpu             = "1024"
      ecs_task_memory          = "2048"
      ecs_desired_count        = 3
      db_instance_class        = "db.r6g.large"
      db_allocated_storage     = 100
      db_max_allocated_storage = 500
      db_multi_az              = true
      db_backup_retention      = 35
      db_deletion_protection   = true
      log_retention_days       = 365
    }
  }
}
