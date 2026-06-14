resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets envelope encryption (${var.cluster_name})"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = var.tags
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}
