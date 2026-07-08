# 3. Implementation Guide — Microsoft Purview Executive Dashboard

Follow these steps **in order**. Work uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` —
`Get-Label`, `Get-DlpCompliancePolicy`, `Get-RetentionCompliancePolicy`, `Export-ActivityExplorerData`,
`Export-ContentExplorerData`), and **Microsoft Graph** (licensing, any reporting/security surface). Every
write is gated: scripts run **read-only or `-WhatIf` by default** and only change state (the metric
definition file and the scheduled task) with `-Commit`. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess the available signals, design the metric set/thresholds, configure the definition
> and schedule, **pilot** the one-pager as a draft and check every number against its source, validate
> it reconciles, then expand to scheduled refresh, trend accrual, and distribution. Pattern:
> **Assess → Design → Configure → Pilot → Validate → Expand.** The dashboard is a **reporting layer** —
> it changes no Purview policy; the only artifacts it creates are the definition file, the snapshots,
> and the scheduled collection task.

## Step 1 — Assess the available signals and licensing (Assess)
1. Run `OPSEXEC-Discovery.ps1` (read-only). It connects to S&C PowerShell and Graph and reports, per source:
   - **Compliance posture** — Compliance Manager visible? active assessments count (portal-confirmed if no API);
   - **Data risk** — published labels (`Get-Label`), DLP policies (`Get-DlpCompliancePolicy`), retention policies (`Get-RetentionCompliancePolicy`), Content/Activity Explorer reachable;
   - **Licensing** — whether **DSPM**, **Insider Risk**, **Content Explorer**, advanced **DLP** service plans are present (Graph `subscribedSkus`).
2. Run `OPSEXEC-Scope.ps1` (read-only) to confirm connection/permission health across every source and list the candidate labels/policies/workloads that will form the in-scope set.
3. Record the gaps: sources not licensed, sources with no read role, values that are portal-only in your tenant. **Pass gate:** you have a written source inventory with, for each KPI, *reachable-by-API* vs *portal-read* vs *not licensed*.

## Step 2 — Design the metric set and thresholds (Design)
1. With your compliance/records/security stakeholders (Requirement 2.4), agree the KPIs for the three sections and their green/amber/red thresholds. The standard set:
   - **Posture:** `Compliance Manager Score` (% + points, Δ vs last month); `Improvement Actions Outstanding` (by High/Medium/Low); `Regulatory Assessments Active` (count).
   - **Data risk:** `Sensitivity Label Coverage` (% of in-scope items labeled; labels published); `DLP High-Severity Matches (30d)` (count + Δ); `Sensitive Items Detected` (Content Explorer — items with SITs; oversharing indicator); `Retention Coverage` (% in-scope workloads with a retention policy); and, where licensed, `Insider Risk Active Alerts` (aggregate by severity — **no names**) and `DSPM Recommendations Open` (count).
   - **Trend:** monthly snapshots of `Compliance Score`, `DLP Matches`, `Labeled-Content`, and `Insider-Risk Alerts`.
2. Fix the **in-scope set** (Requirement 2.5): which workloads/labels/DLP policies/assessments count toward coverage.
3. Name the owners and read cadence for the **portal-only** values (Requirement 2.6). **Pass gate:** the metric set, thresholds, in-scope set, and portal-value owners are documented and approved as `Exec Metrics – Compliance Signals – Definition`.

## Step 3 — Configure the definition and collection (Configure)
1. Materialize the agreed design into the definition file, **pilot-first** (`-WhatIf` prints the exact file it would write):
   `OPSEXEC-Configure.ps1 -DefinitionPath .\ExecMetrics.json -Scope <workloads/labels/policies> -Thresholds <bands> -WhatIf` → review → re-run with `-Commit`.
2. Enter (or reference) the **portal-only** values and their read dates in the definition (Compliance Manager score, Insider-Risk aggregate, DSPM recommendations) — keeping Insider Risk **aggregate/de-identified**.
3. Register the scheduled collection **in draft** — `OPSEXEC-Configure.ps1 -RegisterSchedule -Cadence Monthly -WhatIf` prints the scheduled-task command; **do not** `-Commit` the schedule until the pilot passes (Step 6). **Pass gate:** the definition file exists and validates; the schedule command is reviewed but not yet live. **Rollback:** delete the definition file / `-RegisterSchedule -Remove -Commit`.

## Step 4 — Collect and build the pilot one-pager (Configure → Pilot)
1. Run the collector/renderer read-only against the pilot draft:
   `OPSEXEC-Report.ps1 -DefinitionPath .\ExecMetrics.json -OutputPath .\ExecDashboard -Stage Pilot`
   It collects each API-reachable signal, merges the portal-only values from the definition, renders `Exec Dashboard – Pilot – Stage1` (HTML + CSV), and writes a snapshot.
2. The page shows every KPI with its value, its threshold colour, and a **data-source + as-of timestamp** per number — so nothing is unattributed.
3. **Pass gate:** the pilot one-pager renders with all three sections populated (or an explicit *"not licensed / portal-read pending"* where a source is unavailable). **Rollback:** none needed — output files only; delete and re-run.

## Step 5 — Reconcile every number against its Purview source (Pilot)
1. For each KPI, open the source blade in the Purview portal and confirm the dashboard value matches:
   - Compliance score → **Compliance Manager** dashboard; assessments → its assessments list.
   - Label coverage / sensitive items → **Data classification → Content Explorer** (and `Export-ContentExplorerData`).
   - DLP matches → **Data loss prevention → Alerts / Activity Explorer** (`Export-ActivityExplorerData`).
   - Retention coverage → **Data lifecycle management / Records management** policies.
   - Insider Risk aggregate → **Insider Risk Management → Alerts** dashboard (aggregate only).
   - DSPM → **DSPM** recommendations (E5/preview).
2. Fix any mismatch at its cause: wrong scope/denominator, stale portal value, a filter difference, or an unlicensed source being counted. **Pass gate:** every number on the pilot page reconciles to its source, or is honestly labeled *"verify licensing/tenant."*

## Step 6 — Validate the page (Validate)
1. Run `OPSEXEC-Validate.ps1 -DefinitionPath .\ExecMetrics.json -SnapshotPath .\ExecDashboard\snapshot.json` — it confirms every defined KPI is present, cross-checks the counts it can recompute, and flags **stale** portal-only values (older than the refresh window) and **missing** sources.
2. Walk the **Testing Guide** gates end to end. **Pass gate:** validation is green (no missing/stale KPIs) for the pilot.

## Step 7 — Publish, schedule, and accrue trend (Expand)
1. Once the pilot reconciles and validates, produce the C-suite version:
   `OPSEXEC-Report.ps1 -DefinitionPath .\ExecMetrics.json -OutputPath .\ExecDashboard -Stage Publish` → renders `Exec Dashboard – Posture-Risk-Trend – OnePage`.
2. Commit the schedule: `OPSEXEC-Configure.ps1 -RegisterSchedule -Cadence Monthly -Commit` (registers `Exec Collector – Purview Signals – Scheduled`). Each run appends to `Exec Trend – Monthly Snapshot – Baseline`, so the trend section deepens month over month.
3. Deliver via `Exec Dashboard – C-Suite – Distribution` (secured SharePoint location / emailed PDF / Power BI, per Requirement 2.7). **Pass gate:** the published one-pager is delivered, the schedule is live, and the first two snapshots confirm trend is accruing. **Rollback:** `-RegisterSchedule -Remove -Commit` stops collection; the page and history are files you retain or delete.

## Step 8 — Operate and keep it trustworthy (Expand)
1. Each cycle, re-run `OPSEXEC-Validate.ps1` before distribution so a stale portal value, a lapsed license, or a broken source is caught **before** the executive sees it.
2. Refresh the **portal-only** values (Requirement 2.6) on the agreed cadence and update the read dates; review thresholds with stakeholders as posture matures.
3. Re-run `OPSEXEC-Scope.ps1` periodically so scope drift (new labels/policies/workloads) is folded into the coverage denominators. **Pass gate:** validation is green each cycle and trend is unbroken.
