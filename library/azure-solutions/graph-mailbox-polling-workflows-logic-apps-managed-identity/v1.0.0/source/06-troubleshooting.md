# 6. Troubleshooting Guide — Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)

Use `GRAPHPOLL-Discovery.ps1` / `GRAPHPOLL-Validate.ps1` for readiness state, `GRAPHPOLL-Report.ps1` for backlog + watermark, and `GRAPHPOLL-Test-Watermark.ps1` for an exactly-once proof. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names. Where a symptom depends on a Microsoft-versioned behavior (throttling limit, delta expiry, Consumption-vs-Standard, national-cloud endpoint), **verify against current Microsoft documentation** rather than assuming.

## A. Messages processed twice (double-processing)
| Symptom | Cause | Remediation |
|---|---|---|
| The same message is handled on consecutive runs | Watermark not advanced/persisted after processing | Confirm Step 5.7 writes the newest `receivedDateTime` back to row `watermark` in table `mailpollingwatermark`; run `GRAPHPOLL-Report.ps1` to see if the stored watermark moved |
| Duplicates after a crash mid-run | Processed but interrupted before watermark write | Rely on the **mark/move backstop** — ensure Step 5.6.2 marks-as-read and/or moves to `Processed`; a re-read of a moved/read item must be filtered out so it isn't re-handled |
| Same-timestamp messages re-read | Ties on `receivedDateTime` at the watermark boundary | Also store the last processed message **`id`** and skip it next run (Step 5.7); confirm with `GRAPHPOLL-Test-Watermark.ps1` (no overlap) |

## B. Messages skipped (never processed)
| Symptom | Cause | Remediation |
|---|---|---|
| New mail is never picked up | Watermark set too far in the future, or never seeded | Reseed row `watermark` to a correct past time; `GRAPHPOLL-Report.ps1` shows watermark vs. newest message |
| A page of a backlog is missed | Paging loop not following `@odata.nextLink` | Confirm the **Until loop** (Step 5.5) iterates on `@odata.nextLink` until absent; `GRAPHPOLL-Test-Watermark.ps1` reports any GAP |
| Filter excludes valid mail | `$filter`/`$orderby` mismatch (e.g. wrong property or descending order) | Use `receivedDateTime gt <wm>` with `$orderby=receivedDateTime asc`; verify the property/query against current Microsoft documentation |

## C. Runs throttled / failing with HTTP 429
| Symptom | Cause | Remediation |
|---|---|---|
| Run fails or errors under load | Graph 429 not handled | Add the 429 branch (Step 5.4): read **`Retry-After`**, **Delay**, then retry; enable the action retry policy. **Never hard-code a limit — defer to `Retry-After` (exact limits: verify against current Microsoft documentation)** |
| Repeated throttling every run | Interval too aggressive / page size too large | Lengthen the recurrence interval, lower `$top` (e.g. 25), and let paging drain the backlog across the run |
| 5xx transient errors | Service blips | Exponential backoff retry on transient 5xx; the run should recover, not fail |

## D. Watermark stuck or lost
| Symptom | Cause | Remediation |
|---|---|---|
| Watermark never changes | Write step failing (store permission or wrong row) | Confirm the managed identity has the least-priv data role on table `mailpollingwatermark`; `GRAPHPOLL-Validate.ps1` checks store reachability |
| Watermark reset to empty → whole mailbox reprocessed | Store cleared / new store without seed | Reseed the `watermark` row to the last-known-good time; the mark/move backstop limits damage (already-moved items aren't re-handled) |
| Standard workflow state lost | Relying on run-scoped variable instead of durable store | Persist the watermark in the **durable store** (table/blob/stateful workflow), never only in memory; verify Standard state options against current Microsoft documentation |

## E. Graph read returns 403 (access denied)
| Symptom | Cause | Remediation |
|---|---|---|
| GET messages returns 403 | App permission not granted/consented to the identity | Run `GRAPHPOLL-Set-AppRole.ps1 -Execute` to assign the app role (grants + consents); confirm with `GRAPHPOLL-Validate.ps1` |
| 403 on the target mailbox specifically | The application permission is not **scoped** to include this mailbox | Apply the one-mailbox scope per **product #4** (Application Access Policy / Graph RBAC-for-Exchange); the group `Mail Polling Scoped – Support Mailbox – Prod` must include `supportmailbox@contoso.com` |
| Reads succeed on the WRONG mailbox too | Grant is unscoped (tenant-wide) | This is the security risk the solution prevents — scope to one mailbox immediately (product #4); `GRAPHPOLL-Validate.ps1` flags broader-than-needed grants |

## F. Managed identity can't authenticate to Graph
- Confirm the Logic App **Identity** is **On** (system-assigned) or the user-assigned identity `Mail Polling MI – Support Mailbox – Prod` is attached (Step 1).
- Confirm the HTTP action uses **Managed identity** auth with **Audience** `https://graph.microsoft.com` (or the correct **national-cloud** audience — verify).
- A **401** at the HTTP action points to identity/audience; a **403** points to permission/scope (section E).

## G. Paging cut off / incomplete backlog
- If only the first page is processed, the **Until loop** (Step 5.5) isn't following `@odata.nextLink`. Ensure each iteration GETs the `@odata.nextLink` with the same Managed identity auth and stops only when it's absent.
- `GRAPHPOLL-Test-Watermark.ps1` will report a GAP if messages newer than the watermark are missed by the paging loop.

## H. Diagnostic scripts (quick reference)
```powershell
# Readiness: identity grants, mailbox reachability, backlog
powershell -File .\GRAPHPOLL-Discovery.ps1 -ManagedIdentityObjectId '<obj id>' -Mailbox 'supportmailbox@contoso.com'

# PASS/FAIL gates: identity + least-priv permission + mailbox in scope + watermark store reachable
powershell -File .\GRAPHPOLL-Validate.ps1 -ManagedIdentityObjectId '<obj id>' `
    -WatermarkTableUri 'https://<account>.table.core.windows.net/mailpollingwatermark'

# Backlog + last-processed watermark (+ CSV)
powershell -File .\GRAPHPOLL-Report.ps1 -Mailbox 'supportmailbox@contoso.com' -StoredWatermark '<iso8601 utc>'

# Exactly-once: two consecutive reads, no overlap / no gap
powershell -File .\GRAPHPOLL-Test-Watermark.ps1 -Mailbox 'supportmailbox@contoso.com' -StartWatermark '<iso8601 utc>'

# Assign the least-priv application permission (DEFAULTS TO -WhatIf; add -Execute to apply)
powershell -File .\GRAPHPOLL-Set-AppRole.ps1 -ManagedIdentityObjectId '<obj id>' -PermissionName 'Mail.Read'
```

## I. When to escalate
If the managed identity is On, the app role is granted and scoped to the one mailbox, the watermark store is reachable and seeded, throttling is handled via `Retry-After`, and mail is still skipped or double-processed after a clean `GRAPHPOLL-Test-Watermark.ps1` run, collect `GRAPHPOLL-Report.ps1` output, the Logic App run history for the affected run, and the workflow definition, and open a Microsoft support case. Re-confirm any throttling/delta/national-cloud assumption against current Microsoft documentation before escalating.
