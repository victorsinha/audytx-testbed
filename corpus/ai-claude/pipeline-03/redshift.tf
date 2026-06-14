# Generated master password, stored only in Secrets Manager (never in a var or in
# plaintext state output). Redshift can also manage this natively via
# manage_master_password, but Secrets Manager keeps it consumable by the Lambda.
resource "random_password" "redshift_master" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "redshift_master" {
  name       = "${var.project_name}/redshift/master"
  kms_key_id = aws_kms_key.etl.arn
}

resource "aws_secretsmanager_secret_version" "redshift_master" {
  secret_id = aws_secretsmanager_secret.redshift_master.id
  secret_string = jsonencode({
    username = var.redshift_master_username
    password = random_password.redshift_master.result
  })
}

resource "aws_redshift_subnet_group" "analytics" {
  name       = "${var.project_name}-analytics"
  subnet_ids = var.redshift_subnet_ids
}

resource "aws_security_group" "redshift" {
  name        = "${var.project_name}-redshift"
  description = "Ingress to Redshift on 5439 from approved internal ranges only"
  vpc_id      = var.vpc_id

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "redshift" {
  for_each = toset(var.redshift_allowed_cidr_blocks)

  security_group_id = aws_security_group.redshift.id
  description       = "Redshift SQL from approved range"
  cidr_ipv4         = each.value
  from_port         = 5439
  to_port           = 5439
  ip_protocol       = "tcp"
}

resource "aws_redshift_cluster" "analytics" {
  cluster_identifier = "${var.project_name}-analytics"
  database_name      = var.redshift_database_name
  master_username    = var.redshift_master_username
  master_password    = random_password.redshift_master.result

  node_type      = var.redshift_node_type
  cluster_type   = var.redshift_number_of_nodes >= 2 ? "multi-node" : "single-node"
  number_of_nodes = var.redshift_number_of_nodes

  cluster_subnet_group_name = aws_redshift_subnet_group.analytics.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]

  # Security posture
  encrypted                           = true
  kms_key_id                          = aws_kms_key.etl.arn
  publicly_accessible                 = false
  enhanced_vpc_routing                = true
  require_tls                         = true
  allow_version_upgrade               = true
  automated_snapshot_retention_period = 35

  # Audit logging to the access-log bucket.
  logging {
    enable        = true
    bucket_name   = aws_s3_bucket.logs.id
    s3_key_prefix = "redshift-audit/"
  }

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-analytics-final"
}
