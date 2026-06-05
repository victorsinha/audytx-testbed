# Role-chaining attack path — demonstrates a toxic combination that no
# single-resource scanner can detect. Neither role looks dangerous alone:
#  - the entry role holds only sts:AssumeRole on ONE specific role (looks scoped)
#  - the admin role is trusted ONLY by the entry role (looks locked down)
# The risk is the PATH: compromise an EC2 instance (SSRF) -> entry role ->
# assume the admin role -> full account takeover.

# ── Entry role: assumable by EC2, can ONLY assume the admin role ──────────────
resource "aws_iam_role" "ci_runner" {
  name = "ci-runner"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "ci_runner_assume" {
  name = "ci-runner-assume"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action   = "sts:AssumeRole"
      Effect   = "Allow"
      Resource = "arn:aws:iam::123456789012:role/deploy-admin"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ci_runner_attach" {
  role       = aws_iam_role.ci_runner.name
  policy_arn = aws_iam_policy.ci_runner_assume.arn
}

# ── Admin role: trusted ONLY by the entry role, but holds full admin ──────────
resource "aws_iam_role" "deploy_admin" {
  name = "deploy-admin"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::123456789012:role/ci-runner" }
    }]
  })
}

resource "aws_iam_policy" "deploy_admin_perms" {
  name = "deploy-admin-perms"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action   = "*"
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "deploy_admin_attach" {
  role       = aws_iam_role.deploy_admin.name
  policy_arn = aws_iam_policy.deploy_admin_perms.arn
}
