# Dev environment values. Apply with:
#   terraform apply -var-file="dev.tfvars"

aws_region   = "us-east-1"
environment  = "dev"
project_name = "myapp"

vpc_cidr             = "10.10.0.0/16"
private_subnet_cidrs = ["10.10.0.0/19", "10.10.32.0/19"]
public_subnet_cidrs  = ["10.10.96.0/19", "10.10.128.0/19"]

kubernetes_version = "1.29"

# Dev: smaller, cheaper footprint.
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

# Private API endpoint by default; flip to true + restrict CIDRs if you need kubectl from outside the VPC.
cluster_endpoint_public_access       = false
cluster_endpoint_public_access_cidrs = []

log_retention_days = 30

tags = {
  CostCenter = "engineering-dev"
}
