# FIXTURE — NOT PRODUCTION CODE.
#
# Exercises the network_exposure reasoning axis (the engine's 5th axis,
# shipped in PR #48). Same noisy load-balancer rule (AWS_OPS_026 —
# deletion_protection disabled) fires on a public-facing LB and is
# context-suppressed on an internal-only LB.
#
# A hypothetical inventory app ("cellar"). Two ALBs, one CloudFront,
# and two API Gateway endpoints — each with a different exposure
# verdict.

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Public ALB for the storefront. AWS_OPS_026 should fire LIVE — public
# LBs are the rule's intended target (third-party DNS, partner Route53
# consumers, external integrations).
resource "aws_lb" "cellar_storefront" {
  name                       = "cellar-storefront"
  load_balancer_type         = "application"
  internal                   = false
  enable_deletion_protection = false
  security_groups            = []
  subnets                    = []
}

# Internal admin ALB. Same rule should be SUPPRESSED — the deletion-
# protection concern (external DNS / partner consumers) doesn't apply
# to an LB that's only reachable from inside the VPC. Accidental
# destruction is recoverable.
resource "aws_lb" "cellar_admin" {
  name                       = "cellar-admin"
  load_balancer_type         = "application"
  internal                   = true
  enable_deletion_protection = false
  security_groups            = []
  subnets                    = []
}

# CloudFront — always internet-facing per the network_exposure axis.
# Included as a positive control: classifier should not mis-classify
# this as internal even though it has no `internal` flag.
resource "aws_cloudfront_distribution" "cellar_cdn" {
  enabled = true
}

# API Gateway v2 with explicit PRIVATE endpoint — InternalOnly.
resource "aws_apigatewayv2_api" "cellar_admin_api" {
  name          = "cellar-admin-api"
  protocol_type = "HTTP"
  endpoint_type = "PRIVATE"
}

# API Gateway v2 default — InternetFacing.
resource "aws_apigatewayv2_api" "cellar_public_api" {
  name          = "cellar-public-api"
  protocol_type = "HTTP"
}
