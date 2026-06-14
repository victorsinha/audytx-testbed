# --- EKS managed add-ons ----------------------------------------------------
# Core add-ons kept on the EKS-managed lifecycle so they track the cluster
# version. vpc-cni / kube-proxy / coredns are the baseline; EBS CSI lets
# stateful app workloads use encrypted gp3 PersistentVolumes.

data "aws_eks_addon_version" "this" {
  for_each = toset(["vpc-cni", "kube-proxy", "coredns", "aws-ebs-csi-driver"])

  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "this" {
  for_each = data.aws_eks_addon_version.this

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.apps]
}
