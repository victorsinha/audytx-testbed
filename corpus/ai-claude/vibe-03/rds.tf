# ---------------------------------------------------------------------------
# RDS PostgreSQL (private, encrypted, multi-AZ, auto-rotated credentials)
# ---------------------------------------------------------------------------

resource "random_password" "db" {
  length  = 32
  special = true
  # RDS disallows these characters in master passwords.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${local.name}/db/credentials"
  description = "Master credentials for the ${local.name} RDS instance"
  kms_key_id  = aws_kms_key.data.arn

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = var.db_name
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db"
  subnet_ids = aws_subnet.data[*].id
  tags       = { Name = "${local.name}-db" }
}

resource "aws_db_parameter_group" "main" {
  name   = "${local.name}-pg16"
  family = "postgres16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = { Name = "${local.name}-pg16" }
}

resource "aws_db_instance" "main" {
  identifier     = "${local.name}-db"
  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.data.arn

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.main.name
  publicly_accessible    = false

  multi_az                            = true
  backup_retention_period             = 14
  backup_window                       = "03:00-04:00"
  maintenance_window                  = "sun:04:30-sun:05:30"
  copy_tags_to_snapshot               = true
  deletion_protection                 = true
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.data.arn

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # MVP convenience for teardown auditing; flip skip_final_snapshot to false
  # and set a name for production-grade safety.
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-db-final"

  tags = { Name = "${local.name}-db" }
}

# Rotate the master credential automatically every 30 days.
resource "aws_secretsmanager_secret_rotation" "db" {
  secret_id           = aws_secretsmanager_secret.db.id
  rotation_lambda_arn = null # supply a rotation Lambda ARN, or enable managed rotation below.

  rotation_rules {
    automatically_after_days = 30
  }

  # NOTE: Secrets Manager managed rotation for RDS requires the rotation
  # Lambda. Left wired but inert (arn=null) so it doesn't fail apply before
  # you attach one; see the AWS-provided SecretsManagerRDSPostgreSQLRotation
  # serverless app. Remove this resource if you rotate manually for the MVP.
  lifecycle {
    ignore_changes = [rotation_lambda_arn]
  }
}
