# Customer-managed KMS key encrypting the SPA origin bucket. Key rotation is
# enabled; the key policy grants account admin and lets CloudFront's OAC
# decrypt objects it fetches from the origin.
resource "aws_kms_key" "site" {
  description             = "${var.project_name} S3 origin encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "site" {
  name          = "alias/${var.project_name}-site"
  target_key_id = aws_kms_key.site.key_id
}

data "aws_iam_policy_document" "kms" {
  # Account administration of the key.
  statement {
    sid       = "EnableIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Allow CloudFront (this distribution only) to decrypt objects it reads.
  statement {
    sid       = "AllowCloudFrontDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_kms_key_policy" "site" {
  key_id = aws_kms_key.site.id
  policy = data.aws_iam_policy_document.kms.json
}
