# 8. Deliverables Summary — Microsoft Fabric & Power BI Governance & Administration

Everything included in this solution package.

## Documentation (source guides)
- `executive-summary.md` — what the solution is, the outcome, the boundary, and the effort.
- `01-solution-overview.md` — what it is, how the Fabric/Power BI admin surface works, the standard
  deployment model (Assess → Configure → Pilot → Validate → Expand), scope, out-of-scope, and the
  auth/connections used.
- `02-requirements.md` — solution-specific prerequisites (Verify / Implement-if-missing); the category-
  wide prerequisites are in `global-requirements-data.md`.
- `03-implementation.md` — exact, ordered, click-by-click steps that name and reuse every object
  (baseline, groups, capacity, workspaces, pipeline).
- `05-testing.md` — validation procedures with pass/fail gates, referencing the scripts by name.
- `06-troubleshooting.md` — symptom → cause → fix for the common failures.
- `07-best-practices.md` — keep-it-clean guidance and where to go next in the catalog.
- `08-deliverables-summary.md` — this file.
- `global-requirements-data.md` — the category-level prerequisites shared by all Data solutions.

## Scripts (PowerShell — read-only or preview-first)
- `FABGOV-Discovery.ps1` — read-only platform inventory: tenant settings of interest, capacities,
  workspaces (orphaned/personal flagged), and a sharing/export summary from the activity log.
- `FABGOV-Validate.ps1` — validates the governance baseline against the intended model: tenant-setting
  scope, workspace roles (groups only), capacity assignment, and pipeline stage pairing; reports
  pass/fail per check. Read-only.
- `FABGOV-Report.ps1` — capacity utilization and activity-log summary report (top sharers, exports,
  publish-to-web attempts) for the weekly governance review. Read-only.
- `FABGOV-TenantSettings-Baseline.ps1` — exports current tenant settings and compares them to a desired-
  state baseline file, producing a diff; any apply is preview-first and explicitly gated (`-Apply` off
  by default).
- `FABGOV-Workspace-Provision.ps1` — provisions the `Sales BI – Content – Dev/Test/Prod` workspaces,
  assigns them to the capacity, and adds group-based roles; runs `-WhatIf` by default and only makes
  changes when explicitly confirmed.

## Naming convention
All objects follow `<Purpose> – <Scope> – <Stage>` and are reused by exact name across the guide,
testing, troubleshooting, and scripts (for example `Tenant Governance Baseline – Fabric/Power BI – v1`,
`Deployment Pipeline – Sales BI – DevTestProd`).

## Format
Delivered as a Complete Solution Package (PDF + Word + scripts) in a single ZIP —
`FABGOV-Complete-Solution.zip` — yours to keep and reuse on every rollout.
