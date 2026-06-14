# Apply with: terraform apply -var-file=env/dev.tfvars
environment = "dev"
aws_region  = "us-east-1"

lambda_memory_size = 256
lambda_timeout     = 10

log_retention_days = 7

api_throttling_burst_limit = 100
api_throttling_rate_limit  = 200

# No provisioned concurrency in dev — cheaper, cold starts are acceptable.
provisioned_concurrency = 0
