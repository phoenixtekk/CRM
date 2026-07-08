# 3. Implementation Guide — Purview Audit → SIEM Integration

Follow these steps **in order**. Configuration uses the **Microsoft Purview / Entra portals**, **Exchange
Online / Security & Compliance PowerShell** (`Connect-ExchangeOnline`, `Connect-IPPSSession` — for the
source-of-truth `Search-UnifiedAuditLog`), **Microsoft Graph** (licensing + the Audit Log Query API), and
the **Office 365 Management Activity API** (`manage.office.com/api/v1.0/{tenant}/activity/feed`). Every
write is gated: scripts run **read-only or `-WhatIf` by default** and only change state with `-Commit`.
Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused
verbatim. **App-only auth is certificate-based — no secrets in code.**

> **Model:** Assess the export surface you have, design the path/identity/coverage, configure the app and
> subscriptions, **pilot** one content type end-to-end into the SIEM, validate by **reconciling** SIEM
> ingestion against the source audit log, then expand. Pattern: **Assess → Design → Configure → Pilot →
> Validate → Expand.** Getting audit into the SIEM *reliably* is the goal — a feed you haven't reconciled
> is a feed you can't trust.

## Step 1 — Assess the current export surface (Assess)
1. Run `AUDSIEM-Discovery.ps1` (read-only). It connects to Exchange Online, Graph, and — with the app
   certificate — the Management Activity API, and reports:
   - `UnifiedAuditLogIngestionEnabled` (is the source on at all? — Requirement 2.1),
   - existing **Management Activity API content subscriptions** and their `status`,
   - whether the app identity (`Audit Feed – Management API – AppReg`) authenticates and carries
     `ActivityFeed.*`,
   - whether a **native connector** is already ingesting (recorded from your SIEM — the script prompts you
     to confirm), so you don't double-subscribe.
2. In the SIEM, note any existing Office 365 / M365 audit ingestion (a native connector may already cover
   part of this). **Do not** stand up a duplicate feed for a content type a connector already ingests.
3. Record the gaps: ingestion off, no app identity, no subscriptions, no connector, partial coverage.
   **Pass gate:** a written current-state for each item.

## Step 2 — Choose the export path and design coverage (Design)
1. Decide the path per Requirement 2.2:
   - **Native connector** (recommended where available) — e.g. Microsoft Sentinel's **Office 365** and
     **Microsoft 365** connectors, or the **Splunk Add-on for Microsoft Office 365**. Lowest effort; the
     connector manages subscriptions/collection for you.
   - **Management Activity API** — when you need control a connector doesn't give, or none exists. Push
     (**webhook**) or **poll** delivery. This solution's helper manages the subscriptions.
   - **Graph Audit Log Query API** (`/security/auditLog/queries`) — newer, query/result model; **verify
     availability/GA in your tenant** before standardizing.
2. Map **content types → detection use-cases** with your SOC (Requirement 2.7) as `Audit-to-Detection –
   Use-Case – Map`, e.g. `Audit.AzureActiveDirectory` → risky sign-in / role-change / app-consent
   detections; `Audit.Exchange` → mailbox-compromise (inbox rules, `MailItemsAccessed`); `Audit.SharePoint`
   → mass download / external sharing; `DLP.All` → policy-match alerting.
3. Define the **pilot** `Audit SIEM Pilot – Entra Feed – Stage1` (one content type, a bounded reconciliation
   window) and the SIEM-side retention target. **Pass gate:** path, use-case map, pilot, and retention are
   documented and approved.

## Step 3 — Stand up the app identity (Configure)
*(Skip if using only a native connector that authenticates itself — go to Step 6.)*
1. Register `Audit Feed – Management API – AppReg` in Entra; add **Office 365 Management APIs →
   Application permissions** `ActivityFeed.Read` (add `ActivityFeed.ReadDlp` if exporting DLP), and **grant
   admin consent** (Requirement 2.3) — under change control.
2. Create/obtain the certificate `Audit Feed – App-Only – Certificate`, upload the `.cer` to the app, and
   install the private key on the collection host; record the **thumbprint** (not the key) — Requirement 2.4.
3. **Pass gate:** `AUDSIEM-Discovery.ps1` authenticates app-only with the certificate and lists
   subscriptions (empty is fine) — proving identity + permission + consent work. **Rollback:** removing the
   app/consent is non-destructive to audit data (the source log is untouched).

## Step 4 — Start the pilot content subscription (Configure → Pilot)
1. Preview the pilot subscription (no change made):
   `AUDSIEM-Configure-Subscription.ps1 -TenantId <guid> -AppId <guid> -CertificateThumbprint <thumb>
   -ContentType Audit.AzureActiveDirectory -Action Start -WhatIf`
   — prints the exact `POST .../subscriptions/start?contentType=Audit.AzureActiveDirectory` it would run.
2. **If push delivery:** re-run with `-WebhookAddress https://<your-endpoint>` — the script includes the
   webhook body (`address`, `authId`, `expiration`) so the API performs its **validation handshake** against
   your endpoint (`Audit Feed – Blob Notification – Webhook`). Your endpoint MUST answer the validation POST.
   **If poll delivery:** omit the webhook; your collector will call `subscriptions/content` on a cadence.
3. Commit the pilot: re-run with `-Commit`. Name it `Audit Export – Entra – Subscription`.
4. **Pass gate:** `AUDSIEM-Discovery.ps1` shows the Entra subscription `enabled`; if webhook, your endpoint
   logged the validation handshake. **Rollback:** `AUDSIEM-Configure-Subscription.ps1 ... -Action Stop
   -Commit` (stops the subscription; the source audit log is unaffected).

## Step 5 — Confirm blobs are flowing to the SIEM (Pilot)
1. Generate benign in-scope activity (e.g. a test sign-in / role change for `Audit.AzureActiveDirectory`),
   wait for feed latency (minutes), then run `AUDSIEM-Validate.ps1 -TenantId <guid> -AppId <guid>
   -CertificateThumbprint <thumb> -ContentType Audit.AzureActiveDirectory -Hours 1` — it lists **available
   content blobs** for the window and their counts (read-only).
2. Confirm the **SIEM ingested** those same events (search the SIEM for the test activity). If blobs are
   available at the API but absent in the SIEM, the gap is **collection/connector-side** (webhook not
   reachable, collector not polling, parsing dropped them) — not the subscription.
3. **Pass gate:** the pilot content type's events are visible **in the SIEM**, end to end.

## Step 6 — Reconcile SIEM ingestion against the source (Validate)
1. Run `AUDSIEM-Reconcile.ps1 -ContentType Audit.AzureActiveDirectory -Hours 24` — it counts source records
   for the window via `Search-UnifiedAuditLog` (and/or the Graph Audit Log Query API) by workload and prints
   the expected volume to compare against your SIEM's ingested count for the same window
   (`Audit Pipeline – Coverage – Report`).
2. Compare: source count vs. SIEM count for the window, within an agreed tolerance (feed latency means the
   very newest minutes may lag — align the window to allow for it). A material shortfall = **silent loss** to
   investigate (stopped subscription, expired webhook, un-collected blobs, connector filter).
3. **Pass gate:** SIEM ingestion matches the source within tolerance for the pilot content type. Complete the
   **Testing Guide** before expanding.

## Step 7 — Expand to full workload coverage (Expand)
1. With the pilot reconciled clean, start the remaining designed content types, each previewed then
   committed — `Audit Export – Exchange – Subscription`, `Audit Export – SharePoint – Subscription`,
   `Audit Export – General – Subscription`, and (if licensed/needed) `Audit Export – DLP – Subscription`
   (`ActivityFeed.ReadDlp`):
   `AUDSIEM-Configure-Subscription.ps1 ... -ContentType Audit.Exchange -Action Start -WhatIf` → review →
   `-Commit`. Repeat per content type. Reconcile each (Step 6) before treating it as trusted.
2. Confirm the SIEM parses each workload's schema and the `Audit-to-Detection – Use-Case – Map` detections
   fire on test activity. Set the SIEM-side retention to the target from Requirement 2.7.
3. **Pass gate:** every in-scope content type is `enabled`, ingested, and reconciled clean; detections
   validated on test activity.

## Step 8 — Operationalize and monitor the pipeline (Expand)
1. Schedule the read-only chain (`AUDSIEM-Discovery.ps1` → `AUDSIEM-Report.ps1`) on a cadence so drift is
   caught early: a subscription flipping to disabled, a **webhook expiring** (Management Activity API webhook
   subscriptions expire and must be renewed), a content type with no recent blobs, a lapsed certificate.
2. Run `AUDSIEM-Reconcile.ps1` periodically (e.g. daily) as a standing **coverage check** so partial loss
   surfaces as an alert, not as a missing detection later.
3. Hand `Audit Pipeline – Coverage – Report` and the monitoring cadence to your SOC as the standing
   procedure. **Pass gate:** all content types enabled tenant-wide, reconciliation scheduled and green, and
   the pipeline itself is monitored (feed health is a first-class alert).
