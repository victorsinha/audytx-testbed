output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "app_instance_ids" {
  description = "IDs of the web app instances."
  value       = aws_instance.app[*].id
}

output "assets_bucket" {
  description = "Name of the S3 assets bucket."
  value       = aws_s3_bucket.assets.bucket
}
