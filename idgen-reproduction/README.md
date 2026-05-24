# idgen-reproduction

The scenario that motivated audytx's existence: a hypothetical messaging app
("chirp") whose Terraform plan would be hammered by **at least four**
false positives from a naive scanner. audytx is meant to suppress them
with a stated reason instead.

## The four (really five) false-positive patterns

| # | Pattern | Naive scanner says | audytx says (and why) |
|---|---|---|---|
| 1 | `chirp_outbox` redrives to `chirp_outbox_dlq`; the DLQ has no DLQ of its own | "DLQ missing redrive_policy / CMK" | Suppressed via `sqs_dlq_identity` — DLQs are the terminal failure target |
| 2 | `chirp_outbox_dlq` uses `sqs_managed_sse_enabled = true`, not a CMK | "Queue not encrypted with a customer key" | Suppressed via `encryption_variants` — service-managed SSE is real encryption |
| 3 | `chirp_api` (Lambda) is fronted by API Gateway v2; no `dead_letter_config` | "Lambda has no DLQ" | Suppressed via `lambda_invocation_graph` — sync invokers never put events on a Lambda DLQ |
| 4 | `chirp_outbox_worker` is driven by an SQS event source mapping; no `dead_letter_config` | "Lambda has no DLQ" | Suppressed via `lambda_invocation_graph` — polled-async surfaces failures through the source queue, not Lambda's DLQ |
| 5 | `chirp_request_log` has TTL enabled and PITR disabled | "DDB has no point-in-time recovery" | Suppressed via `data_lifetime` — PITR is a semantic mismatch for storage that expires itself |

## What "success" looks like on this PR

1. audytx posts a comment within ~10s of PR open / push.
2. The comment includes a "🧠 audytx reasoned about N findings and chose
   not to flag them" block listing all the suppressions above with the
   stated axis as the reason.
3. The live findings list is short — only patterns where the engine
   actually has a concern, not the suppressed ones.
4. The same suppressions show up as "dismissed" alerts in the Security
   tab (SARIF v2.1.0 emission).

## What "regression" looks like

If any of the five resources from the table above appears in the
**live findings** section (not the suppression block), the context
layer has lost a predicate. That's the kind of regression this
testbed PR exists to catch — the in-repo synthetic tests can't, because
they bypass the HCL parser.

## Why a PR (not a merged commit)

This PR stays open. The audytx comment that lands on it is the live
demo surface — merging it would discard the artifact.
