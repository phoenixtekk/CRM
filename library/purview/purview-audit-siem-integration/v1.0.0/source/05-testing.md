# 5. Testing & Validation Guide — Purview Audit → SIEM Integration

Run these tests after implementation and on a cadence thereafter. Each test states **what to run**, the
**pass criterion**, and the **fail action**. Tests use the safe-by-default scripts (read-only or `-WhatIf`)
and confirm the pipeline is not just configured but **lossless end to end**. Do not expand coverage until
the pilot content type passes every gate.

## Test 1 — Source is on (precondition)
- **Run:** `AUDSIEM-Discovery.ps1` and read `UnifiedAuditLogIngestionEnabled`.
- **Pass:** ingestion is `True` and the events you intend to export are being generated.
- **Fail:** if `False`, stop — no export path can ship what audit isn't capturing. Enable/configure audit
  first (companion Purview Audit solution). Audit is not retroactive.

## Test 2 — App identity authenticates app-only
- **Run:** `AUDSIEM-Discovery.ps1` (which lists subscriptions with the app certificate).
- **Pass:** the call authenticates and returns the subscription list (empty is acceptable pre-config),
  proving app registration + `ActivityFeed.*` permission + admin consent + certificate all work.
- **Fail:** an auth/permission error means the permission isn't granted/consented, or the certificate/key is
  missing on the host — fix Requirements 2.3/2.4, not the script.

## Test 3 — Pilot subscription is enabled
- **Run:** `AUDSIEM-Discovery.ps1` after Step 4.
- **Pass:** `Audit Export – Entra – Subscription` shows `status = enabled`.
- **Fail:** re-run `AUDSIEM-Configure-Subscription.ps1 ... -Action Start -Commit`; if it errors on
  bandwidth/availability, **verify your licensing/tenant** (Management Activity API limits scale with plan).

## Test 4 — Webhook validation handshake (push delivery only)
- **Run:** start the subscription with `-WebhookAddress`; watch your endpoint's logs.
- **Pass:** your endpoint received and correctly answered the API's **validation POST**, and the subscription
  is `enabled` with the webhook attached.
- **Fail:** if validation failed, the endpoint isn't reachable/answering correctly — fix the receiver, then
  re-start. Remember webhook subscriptions **expire and must be renewed** (Step 8 monitoring catches this).

## Test 5 — Blobs available at the API for benign test activity
- **Run:** generate benign in-scope activity, wait for latency, then
  `AUDSIEM-Validate.ps1 -ContentType Audit.AzureActiveDirectory -Hours 1`.
- **Pass:** the window lists content blobs with a non-zero count covering the test activity.
- **Fail:** if zero after allowing for latency, confirm the activity actually generated audit records
  (Test 1) and that the correct content type was subscribed.

## Test 6 — End-to-end: events land in the SIEM
- **Run:** search the SIEM for the same benign test activity.
- **Pass:** the events are present **in the SIEM**, correctly parsed into the expected fields.
- **Fail:** blobs available at the API but missing in the SIEM ⇒ collection/connector-side issue (webhook
  unreachable, collector not polling, parser dropped them) — fix the ingestion side, not the subscription.

## Test 7 — Reconciliation: no silent loss
- **Run:** `AUDSIEM-Reconcile.ps1 -ContentType Audit.AzureActiveDirectory -Hours 24` and compare the source
  count to the SIEM's ingested count for the same aligned window.
- **Pass:** SIEM ingestion matches the source within the agreed tolerance (allowing for feed latency on the
  newest minutes) — recorded in `Audit Pipeline – Coverage – Report`.
- **Fail:** a material shortfall = silent partial loss; investigate a stopped subscription, expired webhook,
  un-collected blobs, or a connector filter. Do **not** declare the pipeline trusted until it reconciles.

## Test 8 — Detection use-cases fire
- **Run:** trigger a benign test for a mapped use-case (e.g. a test role add for the role-change detection)
  and confirm the SIEM detection fires per `Audit-to-Detection – Use-Case – Map`.
- **Pass:** the detection triggers on the test activity within expected latency.
- **Fail:** confirm the event reached the SIEM (Test 6) before debugging the rule — a missing detection is
  usually a missing event, not a bad rule.

## Test 9 — Full-coverage regression (after Expand)
- **Run:** `AUDSIEM-Report.ps1` for a tenant-wide pipeline scorecard, then `AUDSIEM-Reconcile.ps1` per
  content type.
- **Pass:** every in-scope content type is `enabled`, delivering recent blobs, and reconciling clean; no
  content type is dark.
- **Fail:** any disabled/lagging/short content type is a coverage gap — remediate before relying on it for
  detection or retention.

## Test 10 — Drift check (scheduled)
- **Run:** the scheduled `AUDSIEM-Discovery.ps1 → AUDSIEM-Report.ps1 → AUDSIEM-Reconcile.ps1` chain.
- **Pass:** no change from the validated baseline — subscriptions enabled, webhook current, certificate
  valid, reconciliation within tolerance.
- **Fail:** any drift (a stopped subscription, an expired webhook, a lapsed certificate, a reconciliation
  shortfall) raises an alert and is remediated under change control. **Pipeline health is a first-class
  alert** — a dark feed is a blind SOC.
