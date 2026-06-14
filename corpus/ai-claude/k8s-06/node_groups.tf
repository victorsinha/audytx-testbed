# --- Managed node group -----------------------------------------------------
# Worker nodes for running the apps. Uses a custom launch template so we can
# enforce IMDSv2, encrypted EBS, and explicit disk sizing.

resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-node-"

  # Force IMDSv2 (token-required) and cap the hop limit so pods can't reach
  # the node's instance-profile credentials through the metadata endpoint.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-node"
    }
  }
}

resource "aws_eks_node_group" "apps" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "apps"
  node_role_arn   = aws_iam_role.node.arn

  # Nodes run in private subnets only.
  subnet_ids     = aws_subnet.private[*].id
  instance_types = var.node_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  labels = {
    role = "apps"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]

  tags = {
    Name = "${var.cluster_name}-apps"
  }

  lifecycle {
    # The scheduler may scale desired_size; don't fight it on apply.
    ignore_changes = [scaling_config[0].desired_size]
  }
}
