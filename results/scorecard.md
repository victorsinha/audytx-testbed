# Benchmark scorecard
Ground-truth iam-vulnerable paths: **31** (source: BishopFox iam-vulnerable README)
Clean production modules: **21**

## Table 1 — IAM precision/recall on iam-vulnerable

| Tool | Total HIGH findings | TP | FP | FN | Precision | Recall |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| audytx | 135 | 31 | 104 | 0 | 23% | 100% |
| checkov | 269 | 31 | 238 | 0 | 12% | 100% |
| kics | 9 | 1 | 8 | 30 | 11% | 3% |
| terrascan | DNF | — | — | — | — | — |
| trivy | 7 | 0 | 7 | 31 | 0% | 0% |

## Table 2 — Precision: high-severity alerts on 21 clean modules (lower = better)

| Corpus | exceptions | audytx | checkov | trivy | kics | terrascan |
|---|----|:---:|:---:|:---:|:---:|:---:|
| cloudposse-s3-bucket | 1 | 1 | 36 | 1 | 0 | 0 |
| terraform-aws-alb | 2 | 4 | 54 | 13 | 2 | 0 |
| terraform-aws-apigateway-v2 | 0 | 0 | 20 | 7 | 1 | 0 |
| terraform-aws-autoscaling | 0 | 0 | 11 | 6 | 0 | 0 |
| terraform-aws-cloudfront | 0 | 0 | 24 | 8 | 0 | 0 |
| terraform-aws-ecr | 1 | 1 | 5 | 1 | 2 | 0 |
| terraform-aws-ecs | 1 | 0 | 86 | 16 | 2 | 0 |
| terraform-aws-eks | 1 | 2 | 88 | 38 | 1 | 0 |
| terraform-aws-eventbridge | 1 | 7 | 57 | 18 | 12 | 0 |
| terraform-aws-iam | 1 | 2 | 287 | 1 | 0 | 0 |
| terraform-aws-kms | 0 | 0 | 1 | 0 | 0 | 0 |
| terraform-aws-lambda | 1 | 6 | 112 | 23 | 7 | 0 |
| terraform-aws-rds | 1 | 1 | 124 | 7 | 1 | 0 |
| terraform-aws-s3-bucket | 1 | 1 | 129 | 18 | 4 | 1 |
| terraform-aws-secure-baseline | 1 | 1 | 107 | 8 | 2 | 0 |
| terraform-aws-security-group | 1 | 0 | 10 | 2 | 0 | 0 |
| terraform-aws-sns | 0 | 0 | 4 | 0 | 0 | 0 |
| terraform-aws-sqs | 0 | 0 | 1 | 0 | 0 | 0 |
| terraform-aws-step-functions | 0 | 0 | 6 | 1 | 0 | 0 |
| terraform-aws-vpc | 0 | 0 | 25 | 3 | 0 | 0 |
| trussworks-s3-private | 1 | 1 | 6 | 4 | 0 | 0 |
| **Total** | | **27**|**1193**|**175**|**34**|**1** |

## Table 3 — Recall: high-severity findings on vulnerable corpora

| Corpus | audytx | checkov | trivy | kics | terrascan |
|---|:---:|:---:|:---:|:---:|:---:|
| KaiMonkey | 39 | 109 | 112 | 0 | 0 |
| iam-role-chain | 4 | 9 | 0 | 1 | 0 |
| learn-terraform-provision-eks-cluster | 0 | 3 | 3 | 0 | 0 |
| sadcloud | 47 | 201 | 26 | 53 | 0 |
| terraform-aws-eks-blueprints | 6 | 210 | DNF | 13 | 0 |
| terragoat | 52 | 466 | 93 | 70 | 0 |

## Appendix — Unmatched findings on iam-vulnerable (for audit)

### audytx (50 unmatched)

| rule_id | file | resource | line |
|---------|------|----------|------|
| AWS_IAM_006 | erable/modules/free-resources/privesc-paths/sre.tf |  | 48 |
| AWS_IAM_006 | tool-testing/fn3-ExploitableConditionConstraint.tf |  | 59 |
| AWS_IAM_006 | /tool-testing/fn2-ExploitableResourceConstraint.tf |  | 43 |
| AWS_IAM_006 | resources/tool-testing/fn4-ExploitableNotAction.tf |  | 49 |
| AWS_IAM_006 | ces/tool-testing/fp1-allow-and-deny-same-policy.tf |  | 49 |
| AWS_IAM_006 | le/modules/free-resources/tool-testing/fp3-deny.tf |  | 44 |
| AWS_IAM_006 | ol-testing/fp2-allow-and-deny-multiple-policies.tf |  | 64 |
| AWS_IAM_006 | ol-testing/fp4-NonExploitableResourceConstraint.tf |  | 43 |
| AWS_IAM_006 | l-testing/fp5-NonExploitableConditionConstraint.tf |  | 59 |
| AWS_IAM_006 | ces/tool-testing/fn1-privesc3-multiple-policies.tf |  | 69 |
| AWS_EC2_003 | m-vulnerable/modules/non-free-resources/ec2/ec2.tf |  | 12 |
| AWS_EC2_006 | m-vulnerable/modules/non-free-resources/ec2/ec2.tf |  | 38 |
| AWS_OPS_038 | free-resources/privesc-paths/privesc-AssumeRole.tf |  | 78 |
| AWS_OPS_038 | c-paths/privesc-sageMakerCreateNotebookPassRole.tf |  | 54 |
| AWS_OPS_038 | privesc-paths/privesc-cloudFormationUpdateStack.tf |  | 46 |
| AWS_OPS_038 | sc-paths/privesc-codeBuildCreateProjectPassRole.tf |  | 51 |
| AWS_OPS_038 | ources/privesc-paths/privesc-ec2InstanceConnect.tf |  | 49 |
| AWS_OPS_038 | ths/privesc-sageMakerCreatePresignedNotebookURL.tf |  | 48 |
| AWS_OPS_038 | rivesc-paths/privesc-sageMakerCreateTrainingJob.tf |  | 48 |
| AWS_OPS_038 | vesc-paths/privesc-sageMakerCreateProcessingJob.tf |  | 48 |
| AWS_OPS_038 | -resources/privesc-paths/privesc-ssmSendCommand.tf |  | 50 |
| AWS_OPS_038 | resources/privesc-paths/privesc-ssmStartSession.tf |  | 53 |
| AWS_OPS_038 | s/privesc-paths/privesc1-CreateNewPolicyVersion.tf |  | 43 |
| AWS_OPS_038 | resources/privesc-paths/privesc10-PutUserPolicy.tf |  | 42 |
| AWS_OPS_038 | esources/privesc-paths/privesc11-PutGroupPolicy.tf |  | 42 |
| AWS_OPS_038 | esources/privesc-paths/privesc13-AddUserToGroup.tf |  | 42 |
| AWS_OPS_038 | rivesc-paths/privesc14-UpdatingAssumeRolePolicy.tf |  | 46 |
| AWS_OPS_038 | resources/privesc-paths/privesc12-PutRolePolicy.tf |  | 42 |
| AWS_OPS_038 | privesc15-PassExistingRoleToNewLambdaThenInvoke.tf |  | 46 |
| AWS_OPS_038 | hs/privesc17-EditExistingLambdaFunctionWithRole.tf |  | 45 |
| AWS_OPS_038 | c16-PassRoleToNewLambdaThenTriggerWithNewDynamo.tf |  | 46 |
| AWS_OPS_038 | c-paths/privesc19-UpdateExistingGlueDevEndpoint.tf |  | 45 |
| AWS_OPS_038 | /privesc18-PassExistingRoleToNewGlueDevEndpoint.tf |  | 46 |
| AWS_OPS_038 | ths/privesc21-PassExistingRoleToNewDataPipeline.tf |  | 51 |
| AWS_OPS_038 | aths/privesc20-PassExistingRoleToCloudFormation.tf |  | 47 |
| AWS_OPS_038 | /privesc-paths/privesc3-CreateEC2WithExistingIP.tf |  | 51 |
| AWS_OPS_038 | -paths/privesc2-SetExistingDefaultPolicyVersion.tf |  | 47 |
| AWS_OPS_038 | esources/privesc-paths/privesc4-CreateAccessKey.tf |  | 43 |
| AWS_OPS_038 | urces/privesc-paths/privesc5-CreateLoginProfile.tf |  | 42 |
| AWS_OPS_038 | sources/privesc-paths/privesc7-AttachUserPolicy.tf |  | 42 |
| AWS_OPS_038 | urces/privesc-paths/privesc6-UpdateLoginProfile.tf |  | 42 |
| AWS_OPS_038 | sources/privesc-paths/privesc9-AttachRolePolicy.tf |  | 42 |
| AWS_OPS_038 | ources/privesc-paths/privesc8-AttachGroupPolicy.tf |  | 42 |
| AWS_OPS_038 | erable/modules/free-resources/privesc-paths/sre.tf |  | 48 |
| AWS_OPS_038 | tool-testing/fn3-ExploitableConditionConstraint.tf |  | 59 |
| AWS_OPS_038 | /tool-testing/fn2-ExploitableResourceConstraint.tf |  | 43 |
| AWS_OPS_038 | resources/tool-testing/fn4-ExploitableNotAction.tf |  | 49 |
| AWS_OPS_038 | ces/tool-testing/fp1-allow-and-deny-same-policy.tf |  | 49 |
| AWS_OPS_038 | le/modules/free-resources/tool-testing/fp3-deny.tf |  | 44 |
| AWS_OPS_038 | ol-testing/fp2-allow-and-deny-multiple-policies.tf |  | 64 |

### checkov (50 unmatched)

| rule_id | file | resource | line |
|---------|------|----------|------|
| CKV_AWS_355 | free-resources/privesc-paths/privesc-AssumeRole.tf | licy.privesc-AssumeRole-high-priv-policy | 1 |
| CKV_AWS_286 | free-resources/privesc-paths/privesc-AssumeRole.tf | licy.privesc-AssumeRole-high-priv-policy | 1 |
| CKV_AWS_62 | free-resources/privesc-paths/privesc-AssumeRole.tf | licy.privesc-AssumeRole-high-priv-policy | 1 |
| CKV_AWS_288 | free-resources/privesc-paths/privesc-AssumeRole.tf | licy.privesc-AssumeRole-high-priv-policy | 1 |
| CKV_AWS_289 | free-resources/privesc-paths/privesc-AssumeRole.tf | licy.privesc-AssumeRole-high-priv-policy | 1 |
| CKV_AWS_63 | free-resources/privesc-paths/privesc-AssumeRole.tf | licy.privesc-AssumeRole-high-priv-policy | 1 |
| CKV_AWS_287 | free-resources/privesc-paths/privesc-AssumeRole.tf | licy.privesc-AssumeRole-high-priv-policy | 1 |
| CKV_AWS_273 | free-resources/privesc-paths/privesc-AssumeRole.tf | s_iam_user.privesc-AssumeRole-start-user | 74 |
| CKV_AWS_355 | privesc-paths/privesc-cloudFormationUpdateStack.tf | policy.privesc-CloudFormationUpdateStack | 1 |
| CKV_AWS_273 | privesc-paths/privesc-cloudFormationUpdateStack.tf | r.privesc-CloudFormationUpdateStack-user | 41 |
| CKV_AWS_40 | privesc-paths/privesc-cloudFormationUpdateStack.tf | dFormationUpdateStack-user-attach-policy | 51 |
| CKV_AWS_355 | sc-paths/privesc-codeBuildCreateProjectPassRole.tf | sc-codeBuildCreateProjectPassRole-policy | 1 |
| CKV_AWS_289 | sc-paths/privesc-codeBuildCreateProjectPassRole.tf | sc-codeBuildCreateProjectPassRole-policy | 1 |
| CKV_AWS_273 | sc-paths/privesc-codeBuildCreateProjectPassRole.tf | vesc-codeBuildCreateProjectPassRole-user | 46 |
| CKV_AWS_40 | sc-paths/privesc-codeBuildCreateProjectPassRole.tf | CreateProjectPassRole-user-attach-policy | 57 |
| CKV_AWS_355 | ources/privesc-paths/privesc-ec2InstanceConnect.tf | policy.privesc-ec2InstanceConnect-policy | 1 |
| CKV_AWS_273 | ources/privesc-paths/privesc-ec2InstanceConnect.tf | iam_user.privesc-ec2InstanceConnect-user | 44 |
| CKV_AWS_40 | ources/privesc-paths/privesc-ec2InstanceConnect.tf | sc-ec2InstanceConnect-user-attach-policy | 55 |
| CKV_AWS_355 | c-paths/privesc-sageMakerCreateNotebookPassRole.tf | c-sageMakerCreateNotebookPassRole-policy | 1 |
| CKV_AWS_289 | c-paths/privesc-sageMakerCreateNotebookPassRole.tf | c-sageMakerCreateNotebookPassRole-policy | 1 |
| CKV_AWS_273 | c-paths/privesc-sageMakerCreateNotebookPassRole.tf | esc-sageMakerCreateNotebookPassRole-user | 49 |
| CKV_AWS_40 | c-paths/privesc-sageMakerCreateNotebookPassRole.tf | reateNotebookPassRole-user-attach-policy | 60 |
| CKV_AWS_355 | ths/privesc-sageMakerCreatePresignedNotebookURL.tf | geMakerCreatePresignedNotebookURL-policy | 1 |
| CKV_AWS_273 | ths/privesc-sageMakerCreatePresignedNotebookURL.tf | sageMakerCreatePresignedNotebookURL-user | 43 |
| CKV_AWS_40 | ths/privesc-sageMakerCreatePresignedNotebookURL.tf | ePresignedNotebookURL-user-attach-policy | 54 |
| CKV_AWS_355 | vesc-paths/privesc-sageMakerCreateProcessingJob.tf | eMakerCreateProcessingJobPassRole-policy | 1 |
| CKV_AWS_289 | vesc-paths/privesc-sageMakerCreateProcessingJob.tf | eMakerCreateProcessingJobPassRole-policy | 1 |
| CKV_AWS_273 | vesc-paths/privesc-sageMakerCreateProcessingJob.tf | ageMakerCreateProcessingJobPassRole-user | 43 |
| CKV_AWS_40 | vesc-paths/privesc-sageMakerCreateProcessingJob.tf | ProcessingJobPassRole-user-attach-policy | 54 |
| CKV_AWS_355 | rivesc-paths/privesc-sageMakerCreateTrainingJob.tf | ageMakerCreateTrainingJobPassRole-policy | 1 |
| CKV_AWS_289 | rivesc-paths/privesc-sageMakerCreateTrainingJob.tf | ageMakerCreateTrainingJobPassRole-policy | 1 |
| CKV_AWS_273 | rivesc-paths/privesc-sageMakerCreateTrainingJob.tf | -sageMakerCreateTrainingJobPassRole-user | 43 |
| CKV_AWS_40 | rivesc-paths/privesc-sageMakerCreateTrainingJob.tf | teTrainingJobPassRole-user-attach-policy | 54 |
| CKV_AWS_355 | -resources/privesc-paths/privesc-ssmSendCommand.tf | iam_policy.privesc-ssmSendCommand-policy | 1 |
| CKV_AWS_273 | -resources/privesc-paths/privesc-ssmSendCommand.tf | aws_iam_user.privesc-ssmSendCommand-user | 45 |
| CKV_AWS_40 | -resources/privesc-paths/privesc-ssmSendCommand.tf | rivesc-ssmSendCommand-user-attach-policy | 56 |
| CKV_AWS_355 | resources/privesc-paths/privesc-ssmStartSession.tf | am_policy.privesc-ssmStartSession-policy | 1 |
| CKV_AWS_273 | resources/privesc-paths/privesc-ssmStartSession.tf | ws_iam_user.privesc-ssmStartSession-user | 48 |
| CKV_AWS_40 | resources/privesc-paths/privesc-ssmStartSession.tf | ivesc-ssmStartSession-user-attach-policy | 59 |
| CKV_AWS_286 | s/privesc-paths/privesc1-CreateNewPolicyVersion.tf | m_policy.privesc1-CreateNewPolicyVersion | 1 |
| CKV_AWS_289 | s/privesc-paths/privesc1-CreateNewPolicyVersion.tf | m_policy.privesc1-CreateNewPolicyVersion | 1 |
| CKV_AWS_273 | s/privesc-paths/privesc1-CreateNewPolicyVersion.tf | ser.privesc1-CreateNewPolicyVersion-user | 38 |
| CKV_AWS_40 | s/privesc-paths/privesc1-CreateNewPolicyVersion.tf | reateNewPolicyVersion-user-attach-policy | 48 |
| CKV_AWS_286 | resources/privesc-paths/privesc10-PutUserPolicy.tf | s.aws_iam_policy.privesc10-PutUserPolicy | 1 |
| CKV_AWS_289 | resources/privesc-paths/privesc10-PutUserPolicy.tf | s.aws_iam_policy.privesc10-PutUserPolicy | 1 |
| CKV_AWS_273 | resources/privesc-paths/privesc10-PutUserPolicy.tf | ws_iam_user.privesc10-PutUserPolicy-user | 37 |
| CKV_AWS_40 | resources/privesc-paths/privesc10-PutUserPolicy.tf | ivesc10-PutUserPolicy-user-attach-policy | 47 |
| CKV_AWS_286 | esources/privesc-paths/privesc11-PutGroupPolicy.tf | .aws_iam_policy.privesc11-PutGroupPolicy | 1 |
| CKV_AWS_289 | esources/privesc-paths/privesc11-PutGroupPolicy.tf | .aws_iam_policy.privesc11-PutGroupPolicy | 1 |
| CKV_AWS_273 | esources/privesc-paths/privesc11-PutGroupPolicy.tf | s_iam_user.privesc11-PutGroupPolicy-user | 37 |

### kics (8 unmatched)

| rule_id | file | resource | line |
|---------|------|----------|------|
| 575a2155-6af1-4026-b1af-d5bc8fe2a904 | ources/privesc-paths/service-linked-role-common.tf | privesc-high-priv-service-policy | 10 |
| 575a2155-6af1-4026-b1af-d5bc8fe2a904 | ol-testing/fp2-allow-and-deny-multiple-policies.tf | fp2-allow-all | 8 |
| 575a2155-6af1-4026-b1af-d5bc8fe2a904 | vulnerable/modules/non-free-resources/glue/glue.tf | privesc-high-priv-glue-policy2 | 27 |
| 575a2155-6af1-4026-b1af-d5bc8fe2a904 | erable/modules/non-free-resources/lambda/lambda.tf | privesc-high-priv-lambda-policy2 | 8 |
| 575a2155-6af1-4026-b1af-d5bc8fe2a904 | /modules/non-free-resources/sagemaker/sagemaker.tf | privesc-high-priv-sagemaker-policy2 | 33 |
| f3674e0c-f6be-43fa-b71c-bf346d1aed99 | /modules/non-free-resources/sagemaker/sagemaker.tf | privesc-sagemakerNotebook | 1 |
| 381c3f2a-ef6f-4eff-99f7-b169cda3422c | m-vulnerable/modules/non-free-resources/ec2/ec2.tf | allow_ssh_from_world | 16 |
| 4728cd65-a20c-49da-8b31-9c08b423e4db | m-vulnerable/modules/non-free-resources/ec2/ec2.tf | allow_ssh_from_world | 21 |

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

