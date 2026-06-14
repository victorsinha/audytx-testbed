# Internal ALB — not internet-facing. Only reachable from within the VPC / peered
# networks, consistent with an internal dashboard.
resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.private[*].id

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  tags = {
    Name = "${local.name}-alb"
  }
}

resource "aws_lb_target_group" "main" {
  name        = "${local.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  deregistration_delay = 30
}

# HTTPS listener. Supply an ACM certificate ARN for the dashboard's internal hostname.
# A self-signed/private-CA cert is appropriate for an internal-only endpoint.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
