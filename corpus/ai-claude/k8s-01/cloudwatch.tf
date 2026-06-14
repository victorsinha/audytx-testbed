# --- Control-plane log group (encrypted, retained) ---------------------------
# Pre-create the log group so retention and the audit/authenticator log classes
# are managed in Terraform rather than left to EKS defaults.

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 90
}
