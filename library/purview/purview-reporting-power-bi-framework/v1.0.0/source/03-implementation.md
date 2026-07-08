# 3. Implementation Guide — Microsoft Purview Reporting & Power BI Framework

This is the exact, ordered build. It follows the house model **Assess → Design → Configure → Pilot
(validate) → Validate → Expand**. Every artifact is named per the convention in the overview and reused
verbatim. Reporting is **read-only** against Purview/Graph; the only writes are creating your export
storage, Power BI workspaces, and a refresh schedule — those are gated behind `-Commit` in the scripts
and behind an explicit change window here. **Build and validate in the pilot workspace before any
leadership audience sees a number.** Each stage has a **pass/fail gate** and a **rollback**.

> Purview portal paths and cmdlets below are current as of authoring; the portal evolves and sources
> are licensing-gated — **verify each path and each source's availability in your tenant**. Do not
> populate a page whose source is not licensed; mark it "not licensed — verify tenant".

---

## Stage 0 — Assess (read-only discovery)

**0.1** On the admin workstation, connect read-only:
```
Connect-IPPSSession
Connect-MgGraph -Scopes 'SecurityEvents.Read.All','AuditLog.Read.All'
```
**0.2** Run `OPSREPORT-Discovery.ps1`. It inventories, without changing anything:
- which reporting sources are reachable for the reporting identity (Activity Explorer via
  `Export-ActivityExplorerData`, alerts via `Get-ProtectionAlert`, audit via `Search-UnifiedAuditLog`,
  secure score via Graph `security/secureScores`);
- which Graph scopes are consented vs missing;
- a licensing/role readiness note per source (available / not licensed / access denied).

**0.3** Run `OPSREPORT-Set-ScopeHealth.ps1 -ShowScope` to record the intended **reporting scope** —
in-scope capabilities, workloads (Exchange, SharePoint, OneDrive, Teams, endpoints), and the reporting
date window — as `Reporting Scope – Purview – Config`.

**Gate 0 (pass/fail):** PASS when every intended source reports **available** (or is explicitly marked
*not licensed — verify tenant*), scopes are consented, and the scope definition is recorded. FAIL →
resolve licensing/roles (Requirements 2.1–2.4) before proceeding.
**Rollback:** none — read-only.

---

## Stage 1 — Design the dataset contract

**1.1** Record the **dataset contract** `Purview Compliance Dataset – Report`: the fixed columns each
source contributes, so the Power BI model binds to a stable shape. Author it exactly as:

| Source table | Key columns |
|---|---|
| `DLP_LabelActivity` (Activity Explorer) | `Date, Workload, Activity, SensitivityLabel, RetentionLabel, DlpPolicy, Count` |
| `Alerts` (`Get-ProtectionAlert` / Graph) | `CreatedTime, PolicyName, Category, Severity, Status, Count` |
| `AuditActivity` (`Search-UnifiedAuditLog`) | `Date, Workload, Operation, RecordType, Count` |
| `Posture` (secure score) | `Date, ControlCategory, CurrentScore, MaxScore, Percent` |
| `RiskAggregate` (aggregate-only) | `Date, Source, Severity, Count` *(counts only — no subjects/content)* |

**1.2** Design the **dashboard pages** (one per capability + an executive page):
`Executive Summary`, `DLP & Labels`, `Retention & Records`, `Audit Activity`, `Compliance Posture`,
`Risk (Aggregate)`. Record the intended visual per page (trend line, severity bar, coverage gauge).

**Gate 1:** PASS when the column contract and page list are documented and reviewed with the compliance
stakeholder (Requirement 2.8). **Rollback:** none — design only.

---

## Stage 2 — Configure the export pipeline and pilot workspace

> This stage writes. Run each configuration step with `-WhatIf` first (the default), review the planned
> action, then re-run with `-Commit` inside the agreed change window.

**2.1 Export storage.** Create the storage location and the dated export set:
```
.\OPSREPORT-Configuration.ps1 -CreateStorage -StoragePath '<secured path or library>' -WhatIf
.\OPSREPORT-Configuration.ps1 -CreateStorage -StoragePath '<secured path or library>' -Commit
```
This provisions `Purview Exports – <yyyyMM> – Report` under least-privilege access.

**2.2 Pilot Power BI workspace.** Create `Purview Reporting – Pilot – Stage1`:
```
.\OPSREPORT-Configuration.ps1 -CreateWorkspace -WorkspaceName 'Purview Reporting - Pilot - Stage1' -WhatIf
.\OPSREPORT-Configuration.ps1 -CreateWorkspace -WorkspaceName 'Purview Reporting - Pilot - Stage1' -Commit
```
(Uses `MicrosoftPowerBIMgmt`; if absent, create the workspace in the Power BI service and skip
`-CreateWorkspace`.)

**2.3 First data pull.** Generate the export set into storage (read-only against Purview/Graph):
```
.\OPSREPORT-Report.ps1 -StoragePath '<...>' -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date)
```
This produces `Purview Data Export – AllSources – Report` — one CSV/JSON per source table matching the
dataset contract.

**2.4 Build the model in Power BI Desktop.** Connect Power BI Desktop to the export set, load each
source table with the contracted columns, set relationships on `Date`, and build the six pages from
Stage 1.2. Publish to `Purview Reporting – Pilot – Stage1`.

**Gate 2:** PASS when the export set exists with all licensed source tables populated, and the pilot
report renders all six pages. **Rollback:** delete the pilot workspace and the export set (no
production impact — nothing is shared yet).

---

## Stage 3 — Pilot (validate every number against the portal)

This is the mandatory validation ring — the reporting equivalent of "pilot in simulation before
enforce." **No leadership audience yet.**

**3.1** Run `OPSREPORT-Validation.ps1 -StoragePath '<...>'` (read-only). It reconciles each dashboard
figure against its Purview source for the same window:
- DLP/label activity counts vs Activity Explorer in the portal;
- alert counts by severity vs the Purview **Alerts** page;
- audit operation counts vs a matching `Search-UnifiedAuditLog` query;
- secure-score percentages vs the Graph `security/secureScores` value.

**3.2** Record any variance and its explanation (aggregation/latency differences are expected and
documented, not silently accepted).

**3.3** Have the pilot audience (Requirement 2.8) review the dashboards for clarity and correctness.

**Gate 3 (pass/fail):** PASS when every figure reconciles to its portal source within the documented
tolerance and the pilot audience signs off. FAIL → correct the export/model (usually a scope, date
window, or column mapping issue) and re-validate. **Rollback:** the dashboards remain pilot-only; nothing
is promoted until this gate passes.

---

## Stage 4 — Validate the pipeline health

**4.1** Run `OPSREPORT-Set-ScopeHealth.ps1 -HealthCheck -StoragePath '<...>'`. It confirms: connections
succeed, the export set is **fresh** (within the expected age), each source table has a sane row count,
and no source silently returned empty when it should have data. Output is logged as
`Purview Pipeline Health – Report`.

**Gate 4:** PASS when the health check is green (fresh, populated, connections OK). FAIL → fix the
failing source before scheduling a refresh (a scheduled stale dashboard is worse than none).

---

## Stage 5 — Expand to production with a scheduled refresh

> Writes — perform inside the change window; `-WhatIf` first.

**5.1 Production workspace.** Create `Purview Reporting – Prod – Stage2`:
```
.\OPSREPORT-Configuration.ps1 -CreateWorkspace -WorkspaceName 'Purview Reporting - Prod - Stage2' -WhatIf
.\OPSREPORT-Configuration.ps1 -CreateWorkspace -WorkspaceName 'Purview Reporting - Prod - Stage2' -Commit
```

**5.2 Promote** the validated report from pilot to production (publish the same `.pbix` to the prod
workspace, or use a deployment pipeline if on Premium/Fabric).

**5.3 Schedule the data pull + refresh.** Configure the daily export + dataset refresh
`Purview Refresh – Daily – Recurring`:
```
.\OPSREPORT-Configuration.ps1 -ScheduleRefresh -Cadence Daily -WhatIf
.\OPSREPORT-Configuration.ps1 -ScheduleRefresh -Cadence Daily -Commit
```
(A scheduled task runs `OPSREPORT-Report.ps1` to refresh the export set, then Power BI service refreshes
the dataset from it.)

**5.4 Grant the leadership audience** read access to the production workspace/app (least-privilege
viewer role).

**Gate 5 (pass/fail):** PASS when production renders all pages from the scheduled export, the refresh
runs on cadence, and the audience can view it. FAIL → roll back to pilot-only.
**Rollback:** remove audience access, disable `Purview Refresh – Daily – Recurring`, and revert to the
pilot workspace; production changes are additive (a new workspace + schedule), so removing them restores
the prior state with no data loss.

---

## Post-implementation
- The recurring value is the **cadence**: the export runs daily, the dataset refreshes, and leadership
  reads a current trend — re-run `OPSREPORT-Validation.ps1` periodically to keep the reconciliation
  evidence current.
- Keep the **dataset contract** authoritative: if a new source is added or a portal report changes,
  update `Purview Compliance Dataset – Report` first, then the export and model — never let the model
  drift from the contract.
- Interpretation and any action on the numbers remain with compliance/records/privacy/legal.
