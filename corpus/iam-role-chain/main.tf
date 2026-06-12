# Bench: IAM role-chaining scenario (ci-runner → deploy-admin)
#
# Validates AWS_IAM_022 — role-chaining path detection.
# ci-runner is trusted by EC2, can AssumeRole to deploy-admin.
# deploy-admin has full admin wildcard. Neither role looks dangerous
# in isolation — audytx should surface the chained path.

resource "aws_iam_role" "ci_runner" {
  name = "ci-runner"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ci_runner_perms" {
  name = "ci-runner-perms"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.deploy_admin.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ci_runner" {
  role       = aws_iam_role.ci_runner.name
  policy_arn = aws_iam_policy.ci_runner_perms.arn
}

resource "aws_iam_role" "deploy_admin" {
  name = "deploy-admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = aws_iam_role.ci_runner.arn }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "deploy_admin_perms" {
  name = "deploy-admin-perms"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "deploy_admin" {
  role       = aws_iam_role.deploy_admin.name
  policy_arn = aws_iam_policy.deploy_admin_perms.arn
}
