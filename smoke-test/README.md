# smoke-test

Single-purpose scenario: **does audytx post a PR comment at all?**

This is the most basic possible validation of the full webhook chain
(webhook signature → installation token → file fetch → engine →
comment post). One resource, one obvious finding, one expected
comment.

## What's in here

`main.tf` declares a public S3 bucket with no public-access-block
configuration. The audytx engine should flag this with at least one
finding (the exact rule ID depends on the catalog — most likely an
`AWS_S3_*` rule about missing public access controls).

## What "success" looks like

1. The webhook fires on PR open / push.
2. audytx posts one comment on the PR within ~10s.
3. The comment shows at least one finding referencing
   `aws_s3_bucket.smoke_test_public`.
4. The footer reports the engine version + rule count.

If any of those four don't happen, something in the production
chain has broken since the last deploy — fix that before opening
the next scenario.
