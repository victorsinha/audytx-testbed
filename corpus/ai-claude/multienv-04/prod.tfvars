# Apply with: terraform apply -var-file=env/prod.tfvars
environment = "prod"
aws_region  = "us-east-1"

lambda_memory_size = 1024
lambda_timeout     = 30

log_retention_days = 90

api_throttling_burst_limit = 2000
api_throttling_rate_limit  = 5000

# Keep instances warm in prod to avoid cold-start latency.
provisioned_concurrency = 2
