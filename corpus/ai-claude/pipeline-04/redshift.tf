# Redshift master password is generated and stored in Secrets Manager — never
# hardcoded and never surfaced in plan output beyond the random resource.
resource "random_password" "redshift" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "redshift" {
  name        = "${var.name_prefix}-redshift-master"
  description = "Redshift master credentials for the CSV pipeline"
  kms_key_id  = aws_kms_key.pipeline.arn
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "redshift" {
  secret_id = aws_secretsmanager_secret.redshift.id
  secret_string = jsonencode({
    username = var.redshift_master_username
    password = random_password.redshift.result
    dbname   = var.redshift_database_name
    host     = aws_redshift_cluster.this.dns_name
    port     = 5439
  })
}

resource "aws_redshift_subnet_group" "this" {
  name       = "${var.name_prefix}-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = var.tags
}

# IAM role the cluster assumes for the COPY command to read from S3.
resource "aws_iam_role" "redshift_copy" {
  name = "${var.name_prefix}-redshift-copy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "redshift_copy" {
  name = "${var.name_prefix}-redshift-copy"
  role = aws_iam_role.redshift_copy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadLandingBucket"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${aws_s3_bucket.landing.arn}/*"
      },
      {
        Sid      = "ListLandingBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.landing.arn
      },
      {
        Sid    = "DecryptObjects"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = aws_kms_key.pipeline.arn
      }
    ]
  })
}

resource "aws_redshift_cluster" "this" {
  cluster_identifier = "${var.name_prefix}-cluster"
  database_name      = var.redshift_database_name
  master_username    = var.redshift_master_username
  master_password    = random_password.redshift.result
  node_type          = var.redshift_node_type
  cluster_type       = var.redshift_number_of_nodes > 1 ? "multi-node" : "single-node"
  number_of_nodes    = var.redshift_number_of_nodes

  cluster_subnet_group_name = aws_redshift_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]

  # Security posture
  encrypted                           = true
  kms_key_id                          = aws_kms_key.pipeline.arn
  publicly_accessible                 = false
  enhanced_vpc_routing                = true
  require_ssl                         = true
  automated_snapshot_retention_period = 7
  allow_version_upgrade               = true

  iam_roles = [aws_iam_role.redshift_copy.arn]

  logging {
    enable               = true
    log_destination_type = "cloudwatch"
    log_exports          = ["connectionlog", "userlog", "useractivitylog"]
  }

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name_prefix}-final"

  tags = var.tags
}

resource "aws_redshift_cluster_iam_roles" "this" {
  cluster_identifier = aws_redshift_cluster.this.cluster_identifier
  iam_role_arns      = [aws_iam_role.redshift_copy.arn]
}
