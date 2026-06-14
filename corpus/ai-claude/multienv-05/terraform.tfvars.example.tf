# Copy to a per-stack tfvars file and select the stack with -var-file.
#
#   terraform workspace new dev   # or: prod
#   terraform apply -var-file="dev.tfvars"
#
# dev.tfvars
# -----------
# environment  = "dev"
# project_name = "mysite"
# aws_region   = "us-east-1"
#
# prod.tfvars
# -----------
# environment        = "prod"
# project_name       = "mysite"
# aws_region         = "us-east-1"
# domain_name        = "example.com"
# acm_certificate_arn = "arn:aws:acm:us-east-1:111122223333:certificate/abcd-..."

environment  = "dev"
project_name = "mysite"
aws_region   = "us-east-1"
