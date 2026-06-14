# Single customer-managed key for all data-at-rest in the pipeline
# (S3 objects, Redshift storage, the Redshift password secret, and Lambda env).
resource "aws_kms_key" "etl" {
  description             = "${var.project_name} ETL data-at-rest encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "etl" {
  name          = "alias/${var.project_name}-etl"
  target_key_id = aws_kms_key.etl.key_id
}
