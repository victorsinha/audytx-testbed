# network-exposure

The same noisy load-balancer rule should fire on a public LB and stay
quiet on an internal one. That's the network_exposure axis — the
engine's 5th reasoning dimension, shipped in audytx PR #48.

This scenario is a hypothetical inventory app ("cellar") with two ALBs,
one CloudFront distribution, and two API Gateway endpoints — each with
a different exposure verdict.

## What's in here

| Resource | `internal` / endpoint | network_exposure axis verdict |
|---|---|---|
| `aws_lb.cellar_storefront` | `internal = false` | InternetFacing |
| `aws_lb.cellar_admin` | `internal = true` | InternalOnly |
| `aws_cloudfront_distribution.cellar_cdn` | n/a | Always InternetFacing |
| `aws_apigatewayv2_api.cellar_admin_api` | `endpoint_type = "PRIVATE"` | InternalOnly |
| `aws_apigatewayv2_api.cellar_public_api` | default endpoint | InternetFacing |

## What "success" looks like on this PR

1. audytx posts a comment within ~10s.
2. **AWS_OPS_026** ("LB deletion_protection disabled") fires LIVE on
   `aws_lb.cellar_storefront`.
3. **AWS_OPS_026** is in the suppression block on `aws_lb.cellar_admin`
   with a reason that names `internal-only` and the
   `network_exposure` axis.
4. Same suppression visible as a "dismissed" alert in the Security tab.

## What "regression" looks like

- AWS_OPS_026 missing on `cellar_storefront` → the live-finding path
  broke.
- AWS_OPS_026 in live findings on `cellar_admin` → the classifier
  failed to read `internal = true` from real HCL (the same class of
  bug `coerce_bool` was added to handle — see audytx PR #42).

## Why a PR (not a merged commit)

This PR stays open. The audytx comment is the live demo surface.
