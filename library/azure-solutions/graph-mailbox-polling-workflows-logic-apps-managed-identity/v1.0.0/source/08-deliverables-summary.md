# 8. Deliverables Summary — Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Graph mailbox polling is — recurrence Logic App, managed identity, exactly-once watermark/delta, throttling + paging, idempotent mark/move; when to poll vs webhook (product #2); pointers to #1 (parent) and #4 (scoping); benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (Logic App Consumption/Standard, managed identity, least-priv app permission + consent, one-mailbox scope, target mailbox, watermark store, Microsoft.Graph PowerShell, national-cloud) |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — enable MI, grant + consent app permission, scope to one mailbox (defer #4), provision watermark store, build the recurrence workflow (Graph read + 429 handling + nextLink paging + watermark + mark/move), pilot |
| 5. Testing Guide | Exactly-once validation with PASS/FAIL gates — each message once across two runs, watermark advances, burst not doubled, throttling handled |
| 6. Troubleshooting Guide | Field issues and remediation (double-processing, skipped mail, 429 runs, watermark stuck/lost, 403 read/scope, paging cut off) |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts (Microsoft.Graph)
| Script | What it does |
|---|---|
| `GRAPHPOLL-Discovery.ps1` | Read-only: the managed identity's app-permission grants, target mailbox reachability, and current message/backlog counts |
| `GRAPHPOLL-Validate.ps1` | PASS/FAIL: managed identity + least-privilege permission present, target mailbox in scope, workflow present, watermark store reachable |
| `GRAPHPOLL-Report.ps1` | Processing/backlog report — unread count and last-processed watermark — plus a CSV export |
| `GRAPHPOLL-Test-Watermark.ps1` | Read-only: inspects two consecutive reads to confirm exactly-once (no overlap, no gap) |
| `GRAPHPOLL-Set-AppRole.ps1` | The only state-changer: assigns/verifies the application permission (app-role) on the managed identity; **defaults to `-WhatIf`** |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand** — with an **exactly-once validation gate** and a documented rollback.

## Outcome
A dependable, credential-free mailbox-polling workflow that reads each message **exactly once** over Microsoft Graph — watermarked, throttle-safe, and idempotent — the right pattern when an event-driven webhook (product #2) isn't available, with the managed identity confined to one mailbox (product #4).
