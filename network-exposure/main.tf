# Scenario: network-exposure axis — public vs internal load balancer suppression
# 
# audytx should suppress AWS_OPS_026 (no third-party DNS / Route53 Resolver)
# on the internal LB (not internet-facing) and fire it on the public LB.

resource "aws_lb" "public_api" {
  name               = "public-api-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-aaa", "subnet-bbb"]
}

resource "aws_lb" "internal_svc" {
  name               = "internal-svc-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = ["subnet-aaa", "subnet-bbb"]
}

resource "aws_lb_listener" "public_https" {
  load_balancer_arn = aws_lb.public_api.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = "arn:aws:acm:us-east-1:123456789012:certificate/abc"

  default_action {
    type             = "forward"
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/api/abc"
  }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal_svc.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/svc/abc"
  }
}
