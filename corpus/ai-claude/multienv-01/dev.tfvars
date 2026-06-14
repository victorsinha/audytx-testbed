# Apply with: terraform apply -var-file=dev.tfvars

environment    = "dev"
aws_region     = "us-east-1"
vpc_cidr       = "10.10.0.0/16"
instance_type  = "t3.small"
instance_count = 1

# Restrict to your admin/VPN ranges. Leave empty to disable SSH entirely.
allowed_ssh_cidrs = []

log_retention_days = 14
