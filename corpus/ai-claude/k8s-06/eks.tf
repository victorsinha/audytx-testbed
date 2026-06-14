# --- EKS cluster ------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  # Control-plane logging: full set of log types shipped to CloudWatch.
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  # Envelope-encrypt Kubernetes Secrets with a customer-managed KMS key.
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.cluster,
  ]

  tags = {
    Name = var.cluster_name
  }
}

# Pre-create the log group so retention + KMS apply (EKS would otherwise
# create it with never-expire retention and no CMK).
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.logs.arn
}

# Dedicated control-plane security group (egress-only by default; EKS manages
# the node<->control-plane rules on its own managed SG).
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "EKS control plane security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.cluster_name}-cluster"
  }
}

resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  description       = "Allow all outbound from the control plane"
  security_group_id = aws_security_group.cluster.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
