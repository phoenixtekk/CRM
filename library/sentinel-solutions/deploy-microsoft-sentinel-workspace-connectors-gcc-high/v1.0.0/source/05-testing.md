# Testing & Validation — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

Work these gates **in order**. Each is **pass/fail**: do not advance a phase until its gate passes. The
delivered scripts automate most checks; the KQL queries can be run in Sentinel → **Logs**. Run
**`SENTDEPG-Validate.ps1`** for a consolidated pass/fail summary and **`SENTDEPG-Report.ps1`** for
volume/cost/health.

---

## Gate 1 — Workspace exists in the correct region

- **Check:** `portal.azure.us` → **Log Analytics workspaces** → `Security Telemetry - Tenant -
  Workspace` exists, in the region agreed in **R1**, inside `RG-Security-Sentinel`.
- **Automated:** `SENTDEPG-Discovery.ps1` / `SENTDEPG-Validate.ps1` report the workspace name, region, and
  resource group.
- **Pass:** workspace present, correct region, correct resource group. **Fail:** missing or wrong region
  → rebuild in the correct region (region cannot be changed).

## Gate 2 — Microsoft Sentinel enabled

- **Check:** `portal.azure.us` → **Microsoft Sentinel** → the workspace is listed.
- **Automated:** `SENTDEPG-Validate.ps1` confirms the Sentinel `SecurityInsights` solution/onboarding
  state on the workspace.
- **Pass:** Sentinel enabled. **Fail:** enable it (implementation Phase 1, Step 2).

## Gate 3 — Least-privilege RBAC is correct

- **Check:** Workspace / `RG-Security-Sentinel` → **Access control (IAM) → Role assignments** — the
  three groups hold **Reader / Responder / Contributor** at resource-group scope; **no** broad
  subscription Contributor is used for routine SOC work.
- **Automated:** `SENTDEPG-Validate.ps1` lists the Sentinel role assignments and flags any subscription-
  scope Owner/Contributor granting Sentinel access.
- **Pass:** roles mapped to the named groups at RG/workspace scope; no over-broad grants. **Fail:**
  correct the assignments (implementation Phase 1, Step 3).

## Gate 4 — Azure Activity is ingesting (first source proven)

- **Check (KQL):** `AzureActivity | where TimeGenerated > ago(1h) | count` → non-zero.
- **Automated:** `SENTDEPG-Report.ps1` shows `AzureActivity` with a bounded GB/day figure; the DCR
  `DCR-AzureActivity-Subscription-Pilot` is present.
- **Pass:** rows arriving, volume bounded. **Fail:** re-check the connector/DCR and source-side rights
  (**R5**); see troubleshooting.

## Gate 5 — Syslog/CEF arrives AND the DCR filter is working

- **Check (KQL):**
  - `Syslog | where TimeGenerated > ago(1h) | summarize count() by SeverityLevel` — **only** the
    severities you allowed appear (no `Debug`/`Info` flood).
  - `CommonSecurityLog | where TimeGenerated > ago(1h) | count` — non-zero from the pilot appliance.
- **Automated:** `SENTDEPG-Validate.ps1` confirms `DCR-Syslog-Linux-Pilot` and `DCR-CEF-Appliances-Pilot`
  exist and that facility/severity filtering is configured (not "all facilities / all severities").
- **Pass:** filtered syslog/CEF arriving at a controlled volume. **Fail:** the filter is missing or the
  forwarder path is broken → see troubleshooting (this is the top cost risk).

## Gate 6 — Ingestion volume is within the cost budget

- **Check:** `SENTDEPG-Report.ps1` totals GB/day per table and projects the monthly cost; compare to the
  **G5** budget.
- **KQL cross-check:**
  `Usage | where TimeGenerated > ago(24h) | summarize GB=sum(Quantity)/1024 by DataType | sort by GB desc`
- **Pass:** projected cost ≤ budget (or an accepted, signed-off variance). **Fail:** move high-volume
  low-signal tables to Basic/Auxiliary, tighten DCR filters, or drop non-detection categories, then
  re-measure.

## Gate 7 — Table plan and retention applied

- **Check:** Sentinel/Log Analytics → **Tables** — each in-scope table shows the intended **tier**
  (Analytics vs Basic/Auxiliary) and **retention/archive** per the **R7** plan.
- **Automated:** `SENTDEPG-Set-Retention.ps1` `-WhatIf` shows no remaining drift between plan and live
  state after you have run it with `-Commit`.
- **Pass:** tiers and retention match the plan. **Fail:** apply with `SENTDEPG-Set-Retention.ps1
  -Commit`.

## Gate 8 — Connector / ingestion health is monitored

- **Check (KQL):**
  - `SentinelHealth | where TimeGenerated > ago(24h) | summarize by SentinelResourceName, Status` —
    connectors report healthy.
  - Drift probe: `union withsource=Tbl * | where TimeGenerated > ago(24h) | summarize LastSeen=max(TimeGenerated) by Tbl`
    — every expected table has a recent `LastSeen`.
- **Automated:** `SENTDEPG-Report.ps1` flags any expected source with **zero rows** in the last N hours
  (ingestion drift) and summarizes `SentinelHealth`.
- **Pass:** health monitoring enabled, no unexplained silent source. **Fail:** enable health monitoring
  and deploy `Workbook-IngestionHealth-Tenant`; investigate any silent source.

## Gate 9 — Rollback is documented and reversible

- **Check:** The change record (**G7**) lists every object created — the workspace, Sentinel, the three
  role assignments, `Diag-EntraID-SignInAudit-Pilot`, `DCR-AzureActivity-Subscription-Pilot`,
  `DCR-Syslog-Linux-Pilot`, `DCR-CEF-Appliances-Pilot` — so each can be removed cleanly.
- **Pass:** a named, complete rollback list exists. **Fail:** complete it before expanding further.

---

### Consolidated pass criteria

The foundation is **validated and ready for detections** when **Gates 1–9 pass**: a governed workspace
in the right region with least-privilege RBAC, high-value sources ingesting, the noisy syslog/CEF path
filtered at the DCR, total volume within budget, tiers/retention applied, health monitored, and a clean
rollback documented.
