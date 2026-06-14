resource "aws_kms_key" "main" {
  description             = "CMK for ${local.name_prefix} data at rest (S3, RDS, Secrets, logs)."
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.main.key_id
}
