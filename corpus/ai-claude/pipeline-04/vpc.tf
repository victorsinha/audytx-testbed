# Redshift and the transforming Lambda run inside private subnets. No internet
# gateway, no NAT — the Lambda reaches S3, Secrets Manager, and the Redshift
# Data API through VPC endpoints, so traffic never leaves the AWS network.
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, { Name = "${var.name_prefix}-private-${count.index}" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-private" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- VPC flow logs -----------------------------------------------------------
resource "aws_cloudwatch_log_group" "vpc_flow" {
  name              = "/aws/vpc/${var.name_prefix}/flow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.pipeline.arn
  tags              = var.tags
}

resource "aws_iam_role" "vpc_flow" {
  name = "${var.name_prefix}-vpc-flow-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow" {
  name = "${var.name_prefix}-vpc-flow-logs"
  role = aws_iam_role.vpc_flow.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.vpc_flow.arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  iam_role_arn    = aws_iam_role.vpc_flow.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.this.id
  tags            = var.tags
}

# --- Security groups ---------------------------------------------------------
resource "aws_security_group" "lambda" {
  name        = "${var.name_prefix}-lambda"
  description = "Egress for the transformer Lambda to VPC endpoints and Redshift"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-lambda" })
}

resource "aws_security_group" "redshift" {
  name        = "${var.name_prefix}-redshift"
  description = "Redshift cluster — accepts SQL only from the transformer Lambda"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-redshift" })
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-vpce"
  description = "HTTPS to interface VPC endpoints from the Lambda"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-vpce" })
}

# Lambda may egress 443 to the endpoint SG and 5439 to Redshift only.
resource "aws_vpc_security_group_egress_rule" "lambda_to_endpoints" {
  security_group_id            = aws_security_group.lambda.id
  description                  = "HTTPS to interface VPC endpoints"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.endpoints.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_redshift" {
  security_group_id            = aws_security_group.lambda.id
  description                  = "SQL to Redshift cluster"
  ip_protocol                  = "tcp"
  from_port                    = 5439
  to_port                      = 5439
  referenced_security_group_id = aws_security_group.redshift.id
}

# Redshift accepts 5439 only from the Lambda SG.
resource "aws_vpc_security_group_ingress_rule" "redshift_from_lambda" {
  security_group_id            = aws_security_group.redshift.id
  description                  = "SQL from transformer Lambda"
  ip_protocol                  = "tcp"
  from_port                    = 5439
  to_port                      = 5439
  referenced_security_group_id = aws_security_group.lambda.id
}

# Endpoints accept 443 only from the Lambda SG.
resource "aws_vpc_security_group_ingress_rule" "endpoints_from_lambda" {
  security_group_id            = aws_security_group.endpoints.id
  description                  = "HTTPS from transformer Lambda"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.lambda.id
}

# --- VPC endpoints (keep traffic on the AWS backbone, no NAT needed) ---------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = merge(var.tags, { Name = "${var.name_prefix}-s3" })
}

locals {
  interface_endpoints = {
    secretsmanager   = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
    redshift_data    = "com.amazonaws.${data.aws_region.current.name}.redshift-data"
    logs             = "com.amazonaws.${data.aws_region.current.name}.logs"
    kms              = "com.amazonaws.${data.aws_region.current.name}.kms"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = local.interface_endpoints
  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name_prefix}-${each.key}" })
}
