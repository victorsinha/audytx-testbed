# --- Additional security group for the cluster ------------------------------
# EKS creates its own managed cluster SG; this one is attached additionally for
# explicit control over node<->control-plane and egress rules.

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Additional security group for the ${var.cluster_name} EKS control plane."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic from the control plane."
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
