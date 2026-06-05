# iam-role-chain (crafted)

A minimal, hand-authored scenario demonstrating an IAM role-chaining
privilege-escalation path (MITRE T1078). Used to validate audytx's
AWS_IAM_022 reachability detection end-to-end.

Path: EC2 (SSRF) -> ci-runner role -> assume deploy-admin role -> admin.
