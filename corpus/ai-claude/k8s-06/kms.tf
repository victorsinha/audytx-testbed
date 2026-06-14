# --- KMS keys ---------------------------------------------------------------
# One key for Kubernetes secrets envelope encryption, one for log groups.
# Both have rotation enabled.

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eks" {
  description             = "EKS secrets envelope encryption for ${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "${var.project_name}-eks-secrets"
  }
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-eks-secrets"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_kms_key" "logs" {
  description             = "CloudWatch log encryption for ${var.project_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.logs_kms.json

  tags = {
    Name = "${var.project_name}-logs"
  }
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.project_name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# Allow CloudWatch Logs in this region to use the log key.
data "aws_iam_policy_document" "logs_kms" {
  statement {
    sid       = "EnableRootAccount"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}
