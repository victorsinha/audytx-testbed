# Prod environment values. Apply with:
#   terraform apply -var-file="prod.tfvars"

aws_region   = "us-east-1"
environment  = "prod"
project_name = "myapp"

vpc_cidr             = "10.20.0.0/16"
private_subnet_cidrs = ["10.20.0.0/19", "10.20.32.0/19", "10.20.64.0/19"]
public_subnet_cidrs  = ["10.20.96.0/19", "10.20.128.0/19", "10.20.160.0/19"]

kubernetes_version = "1.29"

# Prod: larger instances, 3 AZs, more headroom for autoscaling.
node_instance_types = ["m5.large"]
node_desired_size   = 3
node_min_size       = 3
node_max_size       = 6

# Keep the API endpoint private in prod. If you must expose it, set true and
# list ONLY your trusted admin/CI CIDRs below — never 0.0.0.0/0.
cluster_endpoint_public_access       = false
cluster_endpoint_public_access_cidrs = []

log_retention_days = 90

tags = {
  CostCenter = "engineering-prod"
}
