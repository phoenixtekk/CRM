# 6. Troubleshooting — Purview Audit → SIEM Integration

The failure modes that make an audit feed **silent, partial, or untrusted** — plus the app-identity,
subscription, webhook, and reconciliation issues you'll hit getting Purview audit into a SIEM. Each:
**symptom → likely cause → fix.** The recurring lesson: *a feed you haven't reconciled is a feed you
can't trust* — most "we're missing events" reports are a stopped subscription, an expired webhook, or an
un-collected blob, not lost audit data (the **source log is untouched** by any of this).

## `AUDSIEM-Discovery.ps1` reports `UnifiedAuditLogIngestionEnabled = False`
- **Cause:** unified audit logging is off at the source, so there is nothing to export.
- **Fix:** enable it (Requirement 2.1) — `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`
  via Exchange Online — under change control, and allow time for it to take effect. **Verify** whether your
  tenant/region already has it on by default before assuming a defect.

## The app identity won't authenticate app-only
- **Cause A — consent not granted.** `ActivityFeed.Read` (and `ActivityFeed.ReadDlp` for DLP) are
  **Application** permissions needing **admin consent**. **Fix:** grant admin consent on
  `Audit Feed – Management API – AppReg` (Requirement 2.3); re-run discovery to confirm the token carries
  the `ActivityFeed.*` roles.
- **Cause B — certificate/thumbprint mismatch.** The `.cer` uploaded to the app doesn't match the private
  key on the collection host, or the wrong thumbprint was passed. **Fix:** confirm the
  `Audit Feed – App-Only – Certificate` thumbprint matches the installed private key (Requirement 2.4);
  re-upload the public cert if needed. **No secret/key ever goes in code** — thumbprint only.
- **Cause C — expired certificate.** **Fix:** roll the certificate, upload the new `.cer`, update the
  thumbprint; the source audit log is unaffected while you do.

## `subscriptions/start` fails the webhook validation handshake
- **Cause:** the Management Activity API POSTs a **validation** notification to your webhook and your
  endpoint must echo it back; if it doesn't answer, the start fails.
- **Fix:** confirm `Audit Feed – Blob Notification – Webhook` is publicly reachable and returns the
  validation token synchronously. Test with `AUDSIEM-Configure-Subscription.ps1 ... -WebhookAddress <url>
  -WhatIf` first (it prints the exact body), then `-Commit`. If push delivery can't be made reliable, use
  **poll** delivery (omit the webhook; the collector calls `subscriptions/content`).

## Blobs are available at the API but absent in the SIEM
- **Cause:** the gap is **collection/connector-side**, not the subscription — webhook unreachable, collector
  not polling, or the parser dropped the records.
- **Fix:** `AUDSIEM-Validate.ps1 ... -ContentType <type> -Hours 1` lists available content blobs for the
  window (read-only). If blobs exist there but not in the SIEM, fix the collector/connector: webhook
  reachability, poll cadence, or the workload's schema parsing. The subscription is fine.

## Reconciliation shows a material shortfall (source ≫ SIEM)
- **Cause A — feed latency.** The newest minutes always lag; comparing right up to "now" understates the
  SIEM. **Fix:** `AUDSIEM-Reconcile.ps1 -ContentType <type> -Hours 24` — align the window to allow for
  latency; the very newest minutes are expected to trail.
- **Cause B — silent loss.** A stopped subscription, an expired webhook, un-collected blobs, or a
  connector filter dropped events. **Fix:** run `AUDSIEM-Discovery.ps1` to confirm the subscription is
  `enabled` and the webhook current; investigate the collector. Reconcile again after the fix — a shortfall
  outside tolerance is a **real** finding, not noise.

## A native connector and a manual subscription are double-ingesting
- **Cause:** a SIEM native connector (Sentinel Office 365 / Microsoft 365, Splunk Add-on) already ingests a
  content type you also subscribed to manually.
- **Fix:** discovery prompts you to confirm any native connector — **do not** stand up a duplicate feed for
  a content type a connector already covers. Choose one path per content type (Requirement 2.2); stop the
  redundant subscription (`-Action Stop -Commit`) — the source log is unaffected.

## A webhook subscription "just stopped" after working
- **Cause:** Management Activity API **webhook subscriptions expire** and must be renewed.
- **Fix:** schedule the read-only health chain (`AUDSIEM-Discovery.ps1` → `AUDSIEM-Report.ps1`) so an
  expiring/expired webhook or a subscription flipping to disabled is caught as an alert; renew the
  subscription and re-validate. Treat **feed health as a first-class alert**.

## The Graph Audit Log Query API isn't available / behaves differently
- **Cause:** `/security/auditLog/queries` is newer and its availability/GA state is **tenant-dependent**.
- **Fix:** **verify availability/GA in your tenant** before standardizing on it; the `Search-UnifiedAuditLog`
  source-of-truth path in `AUDSIEM-Reconcile.ps1` remains the fallback. Don't assume parity across tenants.

## DLP events aren't exporting
- **Cause:** DLP content needs the extra `ActivityFeed.ReadDlp` application permission and a separate
  `Audit Export – DLP – Subscription`.
- **Fix:** add `ActivityFeed.ReadDlp` (admin consent), confirm DLP is licensed, then start the DLP
  subscription previewed-then-committed. Verify DLP export is available on your plan.

## `Connect-ExchangeOnline` / `Connect-IPPSSession` / `Connect-MgGraph` fails
- **Cause:** module not installed, or MFA/modern-auth not completed.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and `Install-Module Microsoft.Graph
  -Scope CurrentUser`; complete the interactive modern-auth sign-in (Requirement 2.3). App-only automation
  uses the certificate + thumbprint, never a stored secret.

## When to escalate beyond this solution
- **Whether a content type is *in scope* to export, and audit-retention obligations** → **compliance,
  records, and legal** (this solution moves and reconciles the signal; it does not decide what must be
  retained or for how long).
- **SOC detection logic and use-case tuning** → your **security operations** team, using the
  `Audit-to-Detection – Use-Case – Map` as the starting contract.
- **A source cmdlet/API that has genuinely changed** → verify against current Microsoft documentation;
  the Management Activity API, Graph audit APIs, and connector surfaces evolve.
