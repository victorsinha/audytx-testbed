# Benchmark scorecard
Ground-truth iam-vulnerable paths: **31** (source: BishopFox iam-vulnerable README)
Clean production modules: **21**

## Table 1 — IAM precision/recall on iam-vulnerable

| Tool | Total HIGH findings | TP | FP | FN | Precision | Recall |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| audytx | MISSING | — | — | — | — | — |
| checkov | 0 | 0 | 0 | 31 | — | 0% |
| kics | ERROR | — | — | — | — | — |
| terrascan | DNF | — | — | — | — | — |
| trivy | 7 | 0 | 7 | 31 | 0% | 0% |

## Table 2 — Precision: high-severity alerts on 21 clean modules (lower = better)

| Corpus | exceptions | audytx | checkov | trivy | kics | terrascan |
|---|----|:---:|:---:|:---:|:---:|:---:|
| cloudposse-s3-bucket | 1 | MISSING | 0 | 1 | ERROR | 0 |
| terraform-aws-alb | 2 | MISSING | 0 | 13 | ERROR | 0 |
| terraform-aws-apigateway-v2 | 0 | MISSING | 0 | 7 | ERROR | 0 |
| terraform-aws-autoscaling | 0 | MISSING | 0 | 6 | ERROR | 0 |
| terraform-aws-cloudfront | 0 | MISSING | 0 | 8 | ERROR | 0 |
| terraform-aws-ecr | 1 | MISSING | 0 | 1 | ERROR | 0 |
| terraform-aws-ecs | 1 | MISSING | 0 | 16 | ERROR | 0 |
| terraform-aws-eks | 1 | MISSING | 0 | 38 | ERROR | 0 |
| terraform-aws-eventbridge | 1 | MISSING | 0 | 18 | ERROR | 0 |
| terraform-aws-iam | 1 | MISSING | 0 | 1 | ERROR | 0 |
| terraform-aws-kms | 0 | MISSING | 0 | 0 | ERROR | 0 |
| terraform-aws-lambda | 1 | MISSING | 0 | 23 | ERROR | 0 |
| terraform-aws-rds | 1 | MISSING | 0 | 7 | ERROR | 0 |
| terraform-aws-s3-bucket | 1 | MISSING | 0 | 18 | ERROR | 1 |
| terraform-aws-secure-baseline | 1 | MISSING | 0 | 8 | ERROR | 0 |
| terraform-aws-security-group | 1 | MISSING | 0 | 2 | ERROR | 0 |
| terraform-aws-sns | 0 | MISSING | 0 | 0 | ERROR | 0 |
| terraform-aws-sqs | 0 | MISSING | 0 | 0 | ERROR | 0 |
| terraform-aws-step-functions | 0 | MISSING | 0 | 1 | ERROR | 0 |
| terraform-aws-vpc | 0 | MISSING | 0 | 3 | ERROR | 0 |
| trussworks-s3-private | 1 | MISSING | 0 | 4 | ERROR | 0 |
| **Total** | | **None**|**0**|**175**|**None**|**1** |

## Table 3 — Recall: high-severity findings on vulnerable corpora

| Corpus | audytx | checkov | trivy | kics | terrascan |
|---|:---:|:---:|:---:|:---:|:---:|
| KaiMonkey | MISSING | 0 | 112 | ERROR | 0 |
| iam-role-chain | MISSING | 0 | 0 | ERROR | 0 |
| learn-terraform-provision-eks-cluster | MISSING | 0 | 3 | ERROR | 0 |
| sadcloud | MISSING | 0 | 26 | ERROR | 0 |
| terraform-aws-eks-blueprints | MISSING | 0 | DNF | ERROR | 0 |
| terragoat | MISSING | 0 | 93 | ERROR | 0 |

## Appendix — Unmatched findings on iam-vulnerable (for audit)

### audytx (0 unmatched)

_None — all findings matched a ground-truth entry._


### checkov (0 unmatched)

_None — all findings matched a ground-truth entry._


### kics (0 unmatched)

_None — all findings matched a ground-truth entry._


### terrascan (0 unmatched)

_None — all findings matched a ground-truth entry._


### trivy (7 unmatched)

| rule_id | file | resource | line |
|---------|------|----------|------|
| AWS-0345 | modules/free-resources/privesc-paths/sre.tf | module.privesc-paths | 8 |
| AWS-0345 | modules/free-resources/privesc-paths/sre.tf | module.privesc-paths | 8 |
| AWS-0028 | modules/non-free-resources/ec2/ec2.tf | aws_instance.ec2 | 38 |
| AWS-0104 | modules/non-free-resources/ec2/ec2.tf | aws_security_group.allow_ssh_from_world | 28 |
| AWS-0104 | modules/non-free-resources/ec2/ec2.tf | aws_security_group.allow_ssh_from_world | 29 |
| AWS-0107 | modules/non-free-resources/ec2/ec2.tf | aws_security_group.allow_ssh_from_world | 21 |
| AWS-0131 | modules/non-free-resources/ec2/ec2.tf | aws_instance.ec2 | 38 |

