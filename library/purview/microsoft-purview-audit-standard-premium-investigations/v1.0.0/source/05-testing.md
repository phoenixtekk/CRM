# 5. Testing & Validation — Microsoft Purview Audit (Standard & Premium)

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use benign, self-generated activity — no production data is altered. Do not
declare "investigation-ready" until every gate passes for the pilot scope, then re-confirm on expand.

> **Remember:** audit is not retroactive. These tests confirm capture and retention **from now
> forward**; they cannot recover events from before logging/Premium was enabled.

## Gate 1 — Unified audit logging is on
- **Method:** `PURVAUDIT-Discovery.ps1`, or `Get-AdminAuditLogConfig | FL UnifiedAuditLogIngestionEnabled` (Exchange Online PowerShell).
- **Pass:** `UnifiedAuditLogIngestionEnabled = True`.
- **Fail:** enable via `PURVAUDIT-Set-RetentionPolicy.ps1 -EnableUnifiedAudit -Commit` (Implementation Step 3); allow activation time, then retest.

## Gate 2 — Mailbox auditing on, no unexpected bypass
- **Method:** `PURVAUDIT-Discovery.ps1` — org `AuditDisabled` and the enumerated audit-bypass associations.
- **Pass:** `AuditDisabled = False`; no in-scope mailbox has `AuditBypassEnabled = True` unintentionally.
- **Fail:** correct org config; remove unintended bypass (`Set-MailboxAuditBypassAssociation -AuditBypassEnabled $false`) under change control; retest.

## Gate 3 — Audit Premium licensing where expected
- **Method:** `PURVAUDIT-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** an Audit Premium-bearing plan (E5 / Audit add-on) is present and assigned to the users who must have high-value events.
- **Fail:** assign the license (Requirement 2.1); unlicensed users will not produce `MailItemsAccessed` — that is expected, not a defect.

## Gate 4 — High-value events are being captured
- **Method:** for a **licensed** pilot mailbox, generate benign activity (open a message, send a test mail), wait for latency, then `PURVAUDIT-Search.ps1 -Operations MailItemsAccessed,Send -UserIds pilot.user@contoso.com -Start (Get-Date).AddDays(-1) -End (Get-Date)`.
- **Pass:** `MailItemsAccessed` and/or `Send` records return for the licensed pilot user.
- **Fail:** re-check license (Gate 3), mailbox auditing (Gate 2), and bypass; allow for ingestion latency before concluding.

## Gate 5 — Retention policies exist and are correct
- **Method:** `PURVAUDIT-Discovery.ps1` retention section (`Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** the three policies (`Audit Retention – Mailbox High-Value – Premium`, `… Privileged Actions – LongTerm`, `… Sign-in Events – Standard+`) exist with the agreed durations and unique priorities.
- **Fail:** create/correct with `PURVAUDIT-Set-RetentionPolicy.ps1` (Step 4); verify the `RetentionDuration` value and ten-year licensing.

## Gate 6 — Search returns complete (non-truncated) results
- **Method:** run `PURVAUDIT-Search.ps1` over a window with more than a few hundred events and confirm it pages (`ReturnLargeSet`) rather than stopping at the first block.
- **Pass:** the result count matches expectation and the script reports it paged to completion (no silent truncation).
- **Fail:** narrow the time window and re-run; confirm paging is engaged. Very large windows should be split.

## Gate 7 — Investigation runbooks answer their questions
- **Method:** walk each runbook (Implementation Step 6) against benign/test activity for a licensed user — mailbox compromise (`MailItemsAccessed`, inbox rules, sign-ins), data exfiltration (`FileDownloaded`, search operations, sharing), privilege escalation (role/group adds, app consent).
- **Pass:** each runbook returns interpretable results for its test activity.
- **Fail:** confirm the operation/record-type names and licensing for that scenario; adjust the runbook and retest.

## Gate 8 — Export/SIEM is flowing (if configured)
- **Method:** `PURVAUDIT-Export.ps1 -Action ListSubscriptions` and confirm the SIEM is receiving content.
- **Pass:** the scoped content subscriptions show `enabled`; the SIEM ingests recent audit blobs.
- **Fail:** (re)start the subscription (`-Action StartSubscription -Commit`); verify the app's `ActivityFeed.*` permissions and certificate.

## Gate 9 — Readiness scorecard is green
- **Method:** `PURVAUDIT-Report.ps1` → `Audit Readiness – Tenant – Report`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, tenant-wide).
- **Fail:** address the specific red item and re-run.

## Evidence to retain
- `PURVAUDIT-Discovery.ps1` and `PURVAUDIT-Report.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every retention-policy and export change.
- The runbook results demonstrating each incident question is answerable.
- The list of pilot users and the change approvals (Requirement 2.6/2.8).

> Retention-duration adequacy and legal-hold sufficiency are **compliance/records/legal determinations**
> — these gates prove the technical configuration works, not that the retention schedule is correct.
