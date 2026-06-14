output "environment" {
  description = "The environment that was deployed."
  value       = var.environment
}

output "instance_type" {
  description = "Instance type used for this environment."
  value       = local.config.instance_type
}

output "instance_count" {
  description = "Number of instances deployed for this environment."
  value       = local.config.instance_count
}

output "instance_ids" {
  description = "IDs of the deployed instances."
  value       = aws_instance.app[*].id
}

output "instance_private_ips" {
  description = "Private IPs of the deployed instances."
  value       = aws_instance.app[*].private_ip
}
