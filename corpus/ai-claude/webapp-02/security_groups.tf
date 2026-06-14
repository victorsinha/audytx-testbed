# ALB security group: only accepts traffic from internal/corporate ranges.
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Ingress to the internal dashboard ALB from trusted CIDRs only."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.internal_access_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internal range ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to ECS tasks"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

# ECS task security group: inbound only from the ALB; egress to the DB + internet (via NAT).
resource "aws_security_group" "ecs_tasks" {
  name        = "${local.name}-ecs-tasks-sg"
  description = "ECS task ingress from ALB only."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-ecs-tasks-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "tasks_from_alb" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "App port from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tasks_to_db" {
  security_group_id            = aws_security_group.ecs_tasks.id
  description                  = "PostgreSQL to RDS"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tasks_https_out" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "HTTPS egress (ECR pulls, Secrets Manager, AWS APIs)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# RDS security group: inbound only from ECS tasks. No egress needed.
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "RDS ingress from ECS tasks only."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_tasks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from ECS tasks"
  referenced_security_group_id = aws_security_group.ecs_tasks.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
