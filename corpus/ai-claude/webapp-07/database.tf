resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${local.name}-db-credentials"
  description = "WordPress MySQL master credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    dbname   = var.db_name
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = {
    Name = "${local.name}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${local.name}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  port                   = 3306

  backup_retention_period   = 14
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-mysql-final"
  copy_tags_to_snapshot     = true

  auto_minor_version_upgrade           = true
  iam_database_authentication_enabled  = true
  enabled_cloudwatch_logs_exports      = ["error", "slowquery"]
  performance_insights_enabled         = true
  performance_insights_retention_period = 7

  tags = {
    Name = "${local.name}-mysql"
  }
}
