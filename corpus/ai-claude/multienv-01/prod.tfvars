# Apply with: terraform apply -var-file=prod.tfvars

environment    = "prod"
aws_region     = "us-east-1"
vpc_cidr       = "10.20.0.0/16"
instance_type  = "t3.large"
instance_count = 2

# Restrict to your admin/VPN ranges. Leave empty to disable SSH entirely.
allowed_ssh_cidrs = []

log_retention_days = 90
