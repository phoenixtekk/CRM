# Deliverables Summary — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page business framing: the drown-in-noise-and-cost problem, the right-order foundation, and the boundary (foundation, not detections). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how the technology works (workspace, Sentinel, connector shapes, DCRs, table tiers, retention, health), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (region/residency, RBAC groups, resource group, Content hub connectors, source-side rights, Linux forwarder, table/retention plan, toolchain) — layered on the shared `global-requirements-sentinel-solutions.md` (G1–G7). |
| **Implementation** (`03-implementation.md`) | Exact, ordered, click-by-click build: workspace + Sentinel + RBAC, pilot Azure Activity, pilot the noisy syslog/CEF path behind a filtering DCR, validate, then expand Entra/Defender/O365 — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates from workspace/region and RBAC through source ingestion, DCR-filter proof, cost-within-budget, tier/retention, and health monitoring, referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (connector connected but no data, syslog/CEF cost blowout, missing Entra logs, RBAC visibility, retention not applied, PowerShell/context errors, ingestion drift, duplicate billing) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Design-once workspace, collect-what-detections-consume, use the tiers on purpose, least-privilege access, prove-data-is-arriving, change safely — plus where to go next in the catalog. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf` by default**, authenticate **interactively** (no credentials in
code), and use the **Az** modules (`Az.Accounts`, `Az.OperationalInsights`, `Az.Monitor`,
`Az.SecurityInsights`), **Microsoft.Graph** where needed, and **KQL** (via
`Invoke-AzOperationalInsightsQuery`) for reporting. Government-cloud tenants pass the matching
environment — *verify endpoints for your cloud*.

| Script | Type | What it does |
| --- | --- | --- |
| **`SENTDEP-Discovery.ps1`** | Read-only | Discovers the current state: whether `Security Telemetry - Tenant - Workspace` exists (name/region/RG), whether Sentinel is enabled, which data connectors and DCRs are present, per-table tier and retention, and existing diagnostic settings — so you build on reality and can spot duplicate-ingestion paths. Changes nothing. |
| **`SENTDEP-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as pass/fail lines: workspace/region, Sentinel enabled, least-privilege RBAC (flags over-broad grants), Azure Activity DCR ingesting, syslog/CEF DCRs present **with filtering applied**, and table tiers/retention set. |
| **`SENTDEP-Report.ps1`** | Read-only | Ingestion + health rollup via KQL: GB/day per table (`Usage`), projected monthly cost against the budget, `SentinelHealth` connector status, and an **ingestion-drift** flag for any expected source with zero rows in the last N hours. Exports to CSV. |
| **`SENTDEP-Set-Diagnostics.ps1`** | `-WhatIf` default | Diagnostic-setting helper: previews (and, with `-Commit`, applies) the Entra ID diagnostic setting `Diag-EntraID-SignInAudit-Pilot` and the Azure Activity routing to the workspace with only the in-scope categories — preview-first, fully reversible. |
| **`SENTDEP-Set-Retention.ps1`** | `-WhatIf` default | Table-plan / retention helper: prints the intended per-table **tier** (Analytics vs Basic/Auxiliary) and **interactive retention + archive** plan; its `-Commit` path applies it. Notes where Basic/Auxiliary eligibility must be verified per table. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Resource group:** `RG-Security-Sentinel`
- **Workspace:** `Security Telemetry - Tenant - Workspace`
- **RBAC groups:** `SG-Sentinel-Reader-Tenant` (Reader), `SG-Sentinel-Responder-Tenant` (Responder),
  `SG-Sentinel-Contributor-Tenant` (Contributor)
- **Entra ID diagnostic setting:** `Diag-EntraID-SignInAudit-Pilot`
- **Azure Activity DCR:** `DCR-AzureActivity-Subscription-Pilot`
- **Linux log forwarder VM:** `Log Forwarder - Perimeter - Pilot`
- **Syslog DCR (filtered):** `DCR-Syslog-Linux-Pilot`
- **CEF DCR (filtered):** `DCR-CEF-Appliances-Pilot`
- **Ingestion-health workbook:** `Workbook-IngestionHealth-Tenant`

## What this solution deliberately does NOT do

- It does **not** author analytics rules or MITRE ATT&CK coverage — that is the companion *Sentinel
  Analytics Rules & MITRE ATT&CK Coverage* solution, which this foundation feeds.
- It does **not** connect a source before the ingestion/cost plan (G5) is agreed, or remove a DCR filter
  without measuring the cost impact.
- It does **not** grant blanket subscription Contributor for SOC work — access is least-privilege and
  role-scoped.
- It does **not** decide **data residency or retention duration** — those are compliance determinations;
  the solution implements the control you choose.
- It does **not** invent pricing, tier, or connector-capability facts — where Basic/Auxiliary
  eligibility, pricing, or a capability may differ by tenant/region/cloud, it says **verify in your
  tenant**.

## How it is delivered

This solution is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation
as a formatted Word document and PDF, plus all five PowerShell scripts, in a single ZIP
(`SENTDEP-Complete-Solution.zip`) — yours to keep and reuse on every rollout.
