# 6. Troubleshooting — Microsoft Purview Executive Dashboard

The failure modes that make an executive dashboard **wrong, empty, or stale**, plus the collection and
scheduling issues you'll hit. Each: **symptom → likely cause → fix.** Most "the dashboard is wrong"
reports are a denominator, a stale portal value, or a licensing gap — this guide separates those from
real faults.

## A KPI shows blank / "no data"
- **Cause A — source not licensed.** DSPM, Insider Risk, Content Explorer, or advanced DLP need **E5 / E5 Compliance** (some preview); the KPI can't populate without the plan. **Fix:** `OPSEXEC-Discovery.ps1` reports which plans are present; assign the license (Requirement 2.1) or leave the KPI shown as *"not licensed / verify tenant"* — do not fabricate it.
- **Cause B — missing read role.** The collector account can't read that source. **Fix:** `OPSEXEC-Scope.ps1` reports the permission error; assign the least-privilege **read** role (Requirement 2.2).
- **Cause C — portal-only value not entered.** Compliance Manager score / Insider-Risk aggregate / DSPM recommendations are portal-read in many tenants and weren't filled in. **Fix:** the named owner reads the value from the portal and enters it (with a read date) in the definition (Requirement 2.6).

## A number doesn't match the Purview portal
- **Cause A — wrong denominator/scope.** Coverage percentages use the in-scope workloads/labels/policies; a different scope gives a different percentage. **Fix:** confirm the in-scope set with `OPSEXEC-Scope.ps1` and align the definition (Requirement 2.5).
- **Cause B — refresh latency.** Activity/Content Explorer and DLP alerts lag; the portal and the snapshot were taken at different times. **Fix:** note the as-of timestamps; re-collect and compare within the same window.
- **Cause C — filter difference.** The portal blade is filtered (date range, severity, workload) differently from the collector query. **Fix:** match the collector's filter to the portal view (severity, time window, record type).

## The compliance score / Insider-Risk aggregate / DSPM count is stale
- **Cause:** these are **portal-only** in many tenants; the owner hasn't re-read them this cycle.
- **Fix:** `OPSEXEC-Validate.ps1` flags any portal-only value older than the refresh window; the owner re-reads it from the portal, updates the value and read date, and re-validates. **Verify whether a supported API is now available in your tenant** before assuming manual is still required.

## `Export-ContentExplorerData` / `Export-ActivityExplorerData` errors or returns nothing
- **Cause A — endpoint/preview.** These are **Security & Compliance PowerShell** (`Connect-IPPSSession`) cmdlets and `Export-ContentExplorerData` is **preview/tenant-dependent**. **Fix:** connect with `Connect-IPPSSession`; confirm the cmdlet is available in your tenant (`Get-Command Export-ContentExplorerData`); if absent, treat that KPI as portal-read.
- **Cause B — role.** Content Explorer needs the **Content Explorer List/Content Viewer** roles. **Fix:** assign the reader roles (Requirement 2.2).
- **Cause C — no classified content yet.** A genuinely empty result means little in-scope content is classified — a **real** finding to show, not a bug. **Fix:** report the low coverage; the remedy is labeling/classification, not the dashboard.

## Trend section is empty or shows a sudden step-change
- **Cause A — insufficient history.** Trend accrues only from your first collection; two points aren't a trend. **Fix:** let the schedule run several cycles; the page honestly shows "insufficient history" until then.
- **Cause B — snapshot overwritten.** The trend store was replaced instead of appended. **Fix:** confirm `OPSEXEC-Report.ps1` **appends** to `Exec Trend – Monthly Snapshot – Baseline`; never overwrite it.
- **Cause C — definition changed mid-stream.** A KPI or threshold changed, so the line jumps. **Fix:** annotate the break so a definition change isn't misread as a real movement (Best Practices).

## The scheduled collection didn't run
- **Cause:** the scheduled task wasn't committed, the account's token expired, or the host was off.
- **Fix:** confirm `OPSEXEC-Configure.ps1 -RegisterSchedule -Commit` created `Exec Collector – Purview Signals – Scheduled`; check the task history and that the collector account can complete a modern-auth/MFA sign-in unattended (or run it interactively on cadence). Re-run `OPSEXEC-Validate.ps1` after any missed cycle.

## Insider Risk detail appears on the page (privacy incident)
- **Cause:** the collector or definition included more than aggregate counts, or an over-privileged role read case detail.
- **Fix:** the executive page must carry **aggregate counts by severity only — no names, no case detail**. Remove any identifying data immediately, confirm **role separation** (the Insider Risk reader is not the dashboard author, Requirement 2.2), and re-render. Insider-risk outcomes are **deferred to HR/legal**.

## Connect-IPPSSession / Connect-MgGraph fails
- **Cause:** module not installed, or MFA/modern-auth not completed.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and `Install-Module Microsoft.Graph -Scope CurrentUser`; complete the interactive modern-auth sign-in (Requirement 2.3). `OPSEXEC-Scope.ps1` reports which endpoints connected.

## Timestamps / percentages look inconsistent across sources
- **Cause:** each Purview source refreshes on its own latency and audit/activity timestamps are **UTC**.
- **Fix:** show a per-KPI as-of timestamp (the collector does), normalize to UTC when correlating, and don't compare two KPIs captured in different windows as if simultaneous.

## When to escalate beyond this solution
- **Whether the reported posture is *adequate*** (score, coverage, risk level), **retention-schedule sufficiency, or any regulatory obligation** → **compliance, records, privacy, and legal** functions (the dashboard measures; it does not judge).
- **Insider-risk case handling** → **HR/legal** under the Insider Risk program's governance, not the dashboard.
- **A source genuinely missing despite correct licensing** → verify against current Microsoft documentation and open a Microsoft support case; Purview capabilities, APIs, and blades evolve.
