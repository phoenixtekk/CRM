# 5. Testing & Validation — Microsoft Purview SOX Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use benign, self-generated activity on the pilot scope — no production data is
altered and DLP stays in **simulation** until the pilot passes. Do not declare the program "in place"
until every gate passes for `SOX Pilot – Finance Ring – Stage1`, then re-confirm on expand.

> **Remember:** the audit trail is not retroactive — these gates confirm capture, controls, and
> evidence **from now forward**, and prove the technical configuration operates, **not** that the SOX
> control design or retention schedule is correct (those are management/internal-audit/records/legal
> determinations).

## Gate 1 — Unified audit logging is on (evidence foundation)
- **Method:** `PURVSOX-Discovery.ps1`, or `Get-AdminAuditLogConfig | FL UnifiedAuditLogIngestionEnabled` (Exchange Online PowerShell).
- **Pass:** `UnifiedAuditLogIngestionEnabled = True`.
- **Fail:** enable via `PURVSOX-ConfigureControls.ps1 -EnableUnifiedAudit -Commit` (Implementation Step 3); allow activation time, then retest.

## Gate 2 — Licensing supports the advanced controls
- **Method:** `PURVSOX-Scope.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** E5 / E5-Compliance-bearing plans are present for the users who need advanced DLP, auto-labeling, long-term audit retention, and Compliance Manager templates.
- **Fail:** proceed with the baseline controls (manual labels, Audit Standard, basic retention) and flag the gated controls as "pending licensing" — an unlicensed advanced control is a licensing fact, not a defect.

## Gate 3 — Financial-data label exists and applies on the pilot
- **Method:** `PURVSOX-Validate.ps1` (label section, `Get-Label` / `Get-LabelPolicy`); as a pilot user, apply `Financial – SOX Reporting – Confidential` to a test document.
- **Pass:** the label exists, is published to the pilot ring, and applies to test financial content.
- **Fail:** create/publish with `PURVSOX-ConfigureControls.ps1 -Control Label`/`-Control LabelPolicy` (Step 4); allow label-policy propagation time before concluding.

## Gate 4 — DLP policy is present and in SIMULATION mode
- **Method:** `PURVSOX-Validate.ps1` (DLP section, `Get-DlpCompliancePolicy | FL Name,Mode`).
- **Pass:** `DLP – SOX Financial Data – Simulation` exists with **Mode** = a Test/simulation value (`TestWithNotifications`/`TestWithoutNotifications`) — **not** `Enable` — during the pilot.
- **Fail:** create with `PURVSOX-ConfigureControls.ps1 -Control Dlp` (Step 5); if it is already `Enable` before the pilot passed, set it back to test (`-SetMode TestWithNotifications -Commit`).

## Gate 5 — DLP simulation is registering matches
- **Method:** generate benign test content that matches the rule (a document carrying the financial label / a financial sensitive-info type) in a pilot location; check DLP **simulation/alerts** in the portal, or the audit trail for DLP rule matches.
- **Pass:** the simulation shows matches for the test content (evidence of exposure) without blocking.
- **Fail:** confirm the rule's conditions (label / SIT) actually match the test content and the workloads are in scope; allow processing latency before concluding.

## Gate 6 — SOX records retention policy is scoped and correct
- **Method:** `PURVSOX-Validate.ps1` (retention section, `Get-RetentionCompliancePolicy`/`Get-RetentionComplianceRule`).
- **Pass:** `Retention – SOX Financial Records – Governed` exists on the pilot scope with the **duration/action your records function set**.
- **Fail:** create/correct with `PURVSOX-ConfigureControls.ps1 -Control Retention` (Step 6); confirm the duration came from the records schedule, not a default.

## Gate 7 — Financial-access audit retention policy exists
- **Method:** `PURVSOX-Discovery.ps1` retention section (`Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** `Audit Retention – Financial Data Access – SOX` exists with the agreed record types, duration, and a unique priority.
- **Fail:** create/correct with `PURVSOX-ConfigureControls.ps1 -Control AuditRetention` (Step 7); verify the `RetentionDuration` value and any long-term licensing.

## Gate 8 — Evidence runbooks answer the auditor's questions
- **Method:** walk each runbook (Implementation Step 9) against benign/test activity over the pilot — financial-data access (`FileAccessed`/`FileDownloaded`), control change (`Set-DlpCompliancePolicy`, `New-Label`, role adds), access provisioning (group/role adds, sharing).
- **Pass:** each runbook returns interpretable results — the artifact an auditor would request.
- **Fail:** confirm the operation/record-type names and that logging covers the scope; adjust the runbook and retest (allow ingestion latency).

## Gate 9 — Segregation of duties on the controls themselves
- **Method:** `PURVSOX-Scope.ps1` role section — review who configures vs who reviews evidence for the SOX controls.
- **Pass:** the configuring role and the evidence-reviewing role are held by different parties (documented); Global Admin is not used for routine control work.
- **Fail:** separate the roles under change control; record the separation in the Compliance Manager assessment.

## Gate 10 — Compliance Manager assessment reflects the controls
- **Method:** Purview portal → Compliance Manager → `SOX ICFR – Purview Controls – Assessment`.
- **Pass:** the improvement actions the Purview controls satisfy are marked with linked evidence and reviewer status.
- **Fail:** attach the runbook evidence and update status; if no template is licensed, confirm the custom mapping is maintained (Requirement 2.6).

## Gate 11 — Program scorecard is green (pilot, then tenant-wide)
- **Method:** `PURVSOX-EvidenceReport.ps1` → `SOX Program – Purview Controls – Report`.
- **Pass:** every control gate above is green for the pilot scope (and, on expand, for the full agreed scope with DLP in **enforce**).
- **Fail:** address the specific red control and re-run.

## Evidence to retain
- `PURVSOX-Scope.ps1`, `PURVSOX-Discovery.ps1`, and `PURVSOX-EvidenceReport.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, retention, and audit-retention change.
- The DLP **simulation** results demonstrating exposure before enforcement.
- The runbook results demonstrating each auditor question is answerable, and the change approvals (Requirement 2.5/2.7).

> Control-design adequacy, operating-effectiveness conclusions, materiality, and retention-schedule
> sufficiency are **management, internal-audit, records, and legal determinations** — these gates prove
> the Purview configuration operates and its evidence is producible, not that the SOX program is
> compliant.
