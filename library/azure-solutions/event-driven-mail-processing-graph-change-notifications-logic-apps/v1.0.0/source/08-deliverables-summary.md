# 8. Deliverables Summary — Event-Driven Mail Processing with Microsoft Graph Change Notifications

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the change-notification (webhook) pattern is — subscription + receiver + managed identity; why event-driven over the O365 connector or polling; benefits, limitations; pointers to products #1/#3/#4 |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (public HTTPS endpoint, managed identity, app permission + consent, mailbox, Microsoft.Graph, TLS, national cloud) |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — enable MI, grant + consent least-priv permission, scope to one mailbox, build the receiver (handshake → clientState → idempotent read), create the subscription, build renewal + catch-up, reliability, pilot |
| 5. Testing Guide | Validation procedures with PASS/FAIL gates (handshake, real event, forged-call rejection, renewal, dedup, catch-up, scoping) |
| 6. Troubleshooting Guide | Field issues and remediation (creation fails, handshake fails, notifications stop, 403 reading the message, duplicates, clientState mismatch) |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts (Microsoft.Graph)
| Script | What it does |
|---|---|
| `GRAPHSUB-Discovery.ps1` | Read-only — lists current Graph change-notification subscriptions (resource, expiry, notificationUrl) and the managed identity's application-permission grants |
| `GRAPHSUB-Validate.ps1` | PASS/FAIL — managed identity + least-privilege permission present, an active non-expired subscription on the target mailbox exists, receiver reachable as far as Graph can be checked |
| `GRAPHSUB-Report.ps1` | Subscription inventory (resource, expiry, notificationUrl host) with a CSV export |
| `GRAPHSUB-Renew.ps1` | The only state-changer — renews/extends a subscription nearing expiry; **defaults to -WhatIf** and says so |
| `GRAPHSUB-Test-Notification.ps1` | Read-only helper — checks recent notification/processing evidence and flags a lapsed subscription (a gap in coverage) |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following **Assess → Configure → Pilot → Validate → Expand** — with an explicit end-to-end event test and a documented rollback (delete the subscription; the mailbox is untouched).

## Outcome
Near-real-time mail processing driven by a Graph change-notification subscription and a managed identity — event-driven, credential-free, scoped to one mailbox, and operationally durable with renewal and catch-up built in — proven on a pilot mailbox before you scale.
