# CMK used to envelope-encrypt Kubernetes secrets stored in etcd.
resource "aws_kms_key" "eks" {
  description             = "EKS secrets encryption key for ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "${var.cluster_name}-secrets-kms"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks.key_id
}
