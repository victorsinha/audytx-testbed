# audytx-testbed

Mono-repo of intentionally-imperfect Terraform / CloudFormation plans, used to
validate [audytx](https://audytx.com) end-to-end against real GitHub webhooks.

Every top-level directory is a self-contained scenario. PRs in this repo
exercise the live audytx GitHub App — the comment that lands on each PR is
the source of truth for what shipped.

## Why this exists

The synthetic unit + integration tests in the main audytx repo validate
engine logic in <1 minute. They can't validate:

- The live GitHub webhook signature verification path
- Octokit installation token exchange + file fetching
- PR comment posting (permissions, rate limits, multi-file PRs)
- SARIF upload to GitHub Code Scanning
- `.audytx-baseline.yaml` resolution from real PR head SHAs
- Cloudflare Worker cold-start + `Context::wait_until` semantics

A separate testbed repo with the App installed catches all of these at
real-PR time, not synthetic time.

## Folder rules

- Each top-level directory is one scenario (one app archetype, one workflow).
- Each scenario is self-contained — `terraform init` runs from inside it.
- Anti-patterns are intentional and documented in the scenario's own README.
- No real company / trademark names. Use distinct fictional names.

## Scenarios

| Directory | What it validates |
|---|---|
| `smoke-test/` | Minimal smoke test — does audytx post a comment on a new PR at all? |

(more scenarios will land as separate PRs)

## How to add a scenario

1. Create a new top-level folder. Add a brief README explaining the
   intent.
2. Add `.tf` files with the intended pattern(s). Mix legitimate
   patterns with the anti-patterns you want audytx to catch.
3. Open a PR. The webhook fires; audytx posts a comment.
4. Compare what fired vs. what you expected. Update the scenario's
   README with the actual result.

## License

Fixtures only. Not for production use.
