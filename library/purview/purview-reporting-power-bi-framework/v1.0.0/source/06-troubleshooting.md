# 6. Troubleshooting — Microsoft Purview Reporting & Power BI Framework

The failure modes you'll hit building and running the reporting pipeline. Each: **symptom → likely
cause → fix.** Most "the dashboard is wrong" reports are a scope/date/window mismatch, a lapsed license
on a source, or a stale export — not a real data fault. Reporting is **read-only** against Purview/Graph
(`Connect-IPPSSession`, `Connect-MgGraph`); the only writes are storage/workspace/schedule, all gated.

## `OPSREPORT-Discovery.ps1` marks a source "not licensed" or "access denied"
- **Cause A — licensing.** Activity Explorer / Audit (Premium) / secure score are licensing-gated
  (E5 / E5 Compliance). **Fix:** confirm the entitlement (Requirements 2.1–2.4); until then mark the
  page **"not licensed — verify tenant"** and do not populate it. **Do not invent a source.**
- **Cause B — missing Graph scope.** `security/secureScores` needs `SecurityEvents.Read.All`; audit
  needs `AuditLog.Read.All`. **Fix:** re-consent `Connect-MgGraph -Scopes ...`; re-run discovery.
- **Cause C — role.** The reporting identity lacks the read role. **Fix:** grant the least-privilege
  reader role for that source.

## An export table is empty when you expect data
- **Cause A — window/scope.** The date window or workload scope excludes the activity. **Fix:** confirm
  `Reporting Scope – Purview – Config` (`-ShowScope`) and the `-StartDate`/`-EndDate` on
  `OPSREPORT-Report.ps1`.
- **Cause B — latency.** Activity Explorer / audit data has ingestion latency; a very recent window may
  be sparse. **Fix:** widen the window or allow ingestion time.
- **Cause C — lapsed license.** A source that worked now returns empty. **Fix:** the pipeline-health
  note flags this — verify the source's licensing hasn't lapsed (Requirement 2.1).

## Dashboard figures don't match the portal (T5–T8)
- **Cause — aggregation/latency/grouping differences.** Portal aggregation and export aggregation can
  differ slightly by grouping and refresh timing. **Fix:** this is expected **only when explained** —
  run `OPSREPORT-Validation.ps1`, record the dashboard value, portal value, variance, and reason
  (latency/grouping/scope) as the reconciliation evidence. An **unexplained** variance is a real
  mismatch: align the RecordType/date/scope filters to the portal query and re-validate.

## `Export-ActivityExplorerData` / `Search-UnifiedAuditLog` "term is not recognized"
- **Cause:** wrong endpoint/module. `Export-ActivityExplorerData`, `Get-ProtectionAlert` are **S&C
  PowerShell** (`Connect-IPPSSession`); `Search-UnifiedAuditLog` is **Exchange Online**
  (`Connect-ExchangeOnline`); secure score is **Graph** (`Connect-MgGraph`). **Fix:** connect the right
  endpoint for each source before running the report.

## The export set is stale / pipeline health is red
- **Cause:** the scheduled export didn't run, or ran under an account that couldn't reach a source.
  **Fix:** `OPSREPORT-Set-ScopeHealth.ps1 -HealthCheck` shows the age/row-count per table; check the
  `Purview Refresh – Daily – Recurring` scheduled task ran and its account has the read roles. **A
  scheduled stale dashboard is worse than none** — fix the source before relying on it.

## `-CreateWorkspace` does nothing / MicrosoftPowerBIMgmt missing
- **Cause:** the `MicrosoftPowerBIMgmt` module isn't installed, or you're not connected. **Fix:**
  `Install-Module MicrosoftPowerBIMgmt` then `Connect-PowerBIServiceAccount`, or create the workspace in
  the Power BI service and **skip** `-CreateWorkspace`. The framework doesn't require the module — it's
  a convenience.

## Scheduled refresh registered but the dataset in Power BI doesn't update
- **Cause:** two refreshes are involved — the **export set** (local scheduled task running
  `OPSREPORT-Report.ps1`) and the **Power BI dataset** (refreshed by the Power BI service from the
  export). Registering the task only handles the first. **Fix:** configure the dataset's scheduled
  refresh (and gateway, if the source is on-prem) in the Power BI service so it pulls the refreshed
  export.

## A change was applied without `-WhatIf` review
- **Cause:** `-Commit` was passed before reviewing the dry-run. **Fix:** all writes are additive —
  delete the export folder/workspace or `Unregister-ScheduledTask "Purview Refresh – Daily –
  Recurring"` to roll back; then re-run with `-WhatIf` first, review, and `-Commit`.

## The RiskAggregate export contains subject or content fields (privacy, T11)
- **Cause:** a non-aggregate field leaked into the risk source. **Fix (immediate):** remove the
  offending field — insider-risk/communication-compliance sources are **aggregate-only** (counts, no
  subjects, no case content) by design. Re-run T11 before anyone sees the page. Case detail is out of
  scope; only aggregate counts are reported.

## When to escalate beyond this solution
- **Whether a number is "good" (DLP rate, retention coverage, risk count acceptable)** →
  **compliance / records / privacy / legal** (this solution proves the number is *accurate*, not
  *acceptable* — deferred).
- **Whether the reported posture satisfies a regulation** → a **legal/compliance** determination, not a
  reporting output.
- **A source genuinely unavailable despite correct licensing** → verify against current Microsoft
  documentation and open a Microsoft support case; Purview reporting surfaces and Graph endpoints evolve.
