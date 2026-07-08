# 6. Troubleshooting — Risk & Compliance Dashboard (Microsoft Purview)

Common issues, grouped by stage. Each has a **symptom**, the **likely cause**, and a **resolution**.
The dashboard is a **read-only reporting layer**: `CMPDASH-Discovery.ps1`, `CMPDASH-Scope.ps1`,
`CMPDASH-Report.ps1`, and `CMPDASH-Validation.ps1` change no policy; the only write is
`CMPDASH-Set-Configuration.ps1`, which is `-WhatIf` by default and (with `-Commit`) writes local config
plus, only if you ask with `-EnableAuditIngestion`, the one tenant-wide audit setting. Most issues here are
licensing, role, config, or freshness — not damage. A signal reading **"not licensed / verify your
tenant"** or an empty feed reading **0** is a legitimate value, not a failure.

## Connectivity & licensing

**Symptom:** live tiles all read "not licensed / verify your tenant".
**Likely cause:** no active `Connect-IPPSSession`, or the reader role is missing.
**Resolution:** connect as the least-privilege collector identity (Requirement 2.2) and re-run
`CMPDASH-Scope.ps1` to confirm each feed reads OK before rendering.

**Symptom:** a signal you expected is owner-captured, not live.
**Likely cause:** Compliance Manager score, Insider Risk, Communication Compliance, and DSPM have **no
stable public read** — by design they are owner-captured.
**Resolution:** set the `owner` + `capturedOn` fields in `RiskComplianceDashboard.config.json`; the program
owner enters the aggregate figure. Never fabricate a live number for these.

## Roles & separation (CMPDASH-Scope.ps1)

**Symptom:** `CMPDASH-Scope.ps1` reports "role separation is BROKEN".
**Likely cause:** the collector identity is a member of an Insider Risk / Communication Compliance
investigator role group and can read HR-sensitive interfaces.
**Resolution:** remove the collector from those investigator role groups before piloting — the collector must
read only least-privilege aggregate/live feeds. HR-sensitive figures are aggregate-only and owner-captured.

**Symptom:** a live feed shows "read FAILED — likely role/permission".
**Likely cause:** the collector lacks the reader role for that feed.
**Resolution:** grant the least-privilege reader (e.g. Global Reader / View-Only Audit Logs / Compliance
Administrator as appropriate), wait for propagation, and re-run. Do not record the signal as missing until
the read succeeds.

## Audit ingestion & DLP volume

**Symptom:** the DLP tile shows volume `n/a (audit ingestion off or no permission)`.
**Likely cause:** unified audit-log ingestion is disabled, or the account can't run `Search-UnifiedAuditLog`.
**Resolution:** enable ingestion under change control —
`CMPDASH-Set-Configuration.ps1 -EnableAuditIngestion -WhatIf` to preview, then `-Commit`. Audit captures
**from enablement forward**; historical volume before that date is not available.

**Symptom:** DLP volume is lower than expected.
**Likely cause:** the report samples one record type (`ComplianceDLPExchange`) and a bounded `ResultSize`.
**Resolution:** this is a known scoping note — extend the collection per workload if you need multi-workload
volume; the policy counts (not the sampled volume) are the reconciled figure.

## Configuration (CMPDASH-Set-Configuration.ps1)

**Symptom:** nothing was written.
**Likely cause:** `-Commit` was omitted (default is `-WhatIf`).
**Resolution:** re-run with `-Commit`; `RiskComplianceDashboard.config.json` is written locally (no Purview
policy is changed).

**Symptom:** the RAG colours look wrong.
**Likely cause:** the thresholds are **your** policy, not a Microsoft default, and haven't been agreed.
**Resolution:** confirm the RAG thresholds with your compliance stakeholders (Requirement 2.7) and edit the
config's `rag` blocks accordingly.

## Rendering & reconciliation

**Symptom:** `CMPDASH-Report.ps1` says config not found.
**Likely cause:** you rendered before `CMPDASH-Set-Configuration.ps1 -Commit` wrote the config.
**Resolution:** write the config first, then render.

**Symptom:** `CMPDASH-Validation.ps1` reports FAIL for a live tile.
**Likely cause:** the tenant state changed since the last render, or the dataset is stale.
**Resolution:** re-run `CMPDASH-Report.ps1` to refresh `RiskComplianceDashboard.data.json`, then re-validate.
Spot-check the tile against the Purview portal (e.g. DLP policy count in **Data loss prevention → Policies**).

**Symptom:** `CMPDASH-Validation.ps1` reports STALE for an owner-captured tile.
**Likely cause:** the figure is older than `ownerCaptureMaxAgeDays`, or was never captured.
**Resolution:** the program owner re-records the aggregate figure and updates `capturedOn`, then re-validate
before scheduling/distributing.

## Scheduling & distribution

**Symptom:** the scheduled run has no data / auth fails.
**Likely cause:** the service identity lacks the read roles, or a secret was (incorrectly) expected in the script.
**Resolution:** run under a least-privilege modern-auth or managed identity with the Requirement-2.2 read
roles — **no secrets in the script**. Re-run `CMPDASH-Validation.ps1` after the first scheduled run.

## What this dashboard does NOT decide
The dashboard **reports** posture — it makes **no determination**. Whether a score, a policy state, or an
aggregate count is *acceptable* or *satisfies a regulation* is a **compliance / records / legal
determination**. Insider Risk and Communication Compliance figures are **aggregate-only, owner-captured, and
role-separated** — the dashboard never reads or exposes case content, and case outcomes are deferred to HR/legal.
