# 8. Deliverables Summary — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

This package is a complete, enterprise-grade program kit for migrating a commercial Microsoft 365 + Azure estate into a GCC High sovereign tenant. It contains the documentation playbook, five PowerShell tools, and a hero image.

## Documentation

| File | What it covers |
|---|---|
| `01-solution-overview.md` | What the program is, the seven workstreams, the GCC-High-is-a-separate-cloud reality, how it works, tooling, benefits, honest limitations, and the standard program model. |
| `02-requirements.md` | R1–R15 prerequisites (Description / Why / Verify / Implement-if-missing), including the GATING eligibility, AOS-G reseller, and provisioned-tenant requirements. |
| `global-requirements-azure-solutions.md` | Baseline requirements common to every Azure Solutions engagement (tenant, roles, licensing, network, change control, backup/rollback). |
| `03-implementation.md` | The full program runbook: Discover → Assess → Plan → Provision → Identity → Pilot → seven workstream runbooks → Domain cutover → Validate → Decommission, with named objects and full `.us` navigation paths. |
| `05-testing.md` | Numbered tests with PASS/FAIL gates and a per-workstream acceptance gate (mail flow, content parity, Teams, server failover, AVD/profile, identity/DNS). |
| `06-troubleshooting.md` | Cross-cloud/endpoint, tooling, ASR, AVD/FSLogix, identity, throttling, domain, and compliance failure modes with fixes. |
| `07-best-practices.md` | Program best practices: waves, comms, ITAR handling, pilots, rollback, ASR test failovers, FSLogix, throttling, decommission discipline, CMMC documentation. |
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |

## PowerShell scripts

All scripts carry a `.SYNOPSIS` header with PURPOSE / HOW TO RUN / EXPECTED RESULTS, and a NEUTRAL white-label `.NOTES`. Cmdlets use the sovereign endpoints where needed (`Connect-AzAccount -Environment AzureUSGovernment`, `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`, Graph `-Environment USGov`).

| Script | What it does |
|---|---|
| `scripts\GCCHIGH-Discovery.ps1` | **Read-only estate inventory.** Connects to the commercial M365 (mailboxes, SharePoint sites, Teams) and Azure (subscriptions, VMs, App Services) and exports a per-object CSV with sizing — the Discovery baseline (R14) that drives licensing, bandwidth, and wave planning. |
| `scripts\GCCHIGH-Validation.ps1` | **Target readiness + per-workstream cutover validation.** Checks the GCC High tenant/licensing, the Azure Gov subscription, sample content parity, and server failover state; emits PASS/FAIL per check for the acceptance gates. |
| `scripts\GCCHIGH-Report.ps1` | **Program/workstream status report.** Reads a status CSV and produces per-workstream % complete, wave progress, and GB moved as a CSV plus a console summary — the program dashboard. |
| `scripts\GCCHIGH-Remediation.ps1` | **Safe remediation helpers.** Re-stamp proxy addresses, re-permission content, and re-trigger ASR replication. Runs read-only / `-WhatIf` by default; requires `-Apply` to make any change. |
| `scripts\GCCHIGH-Set-WavePlan.ps1` | **Wave + workstream planner.** Reads the Discovery CSV and groups users/sites/servers into balanced migration waves, emitting a wave-plan CSV; supports `-WhatIf`. |

## Hero image

| File | Purpose |
|---|---|
| `GCCHIGH-hero.png` | Listing/marketing hero image for the solution. |

> **Naming convention reminder:** the scripts and runbooks share the object-naming standard `<Purpose> – <Scope> – <Stage>` (e.g. `Mailbox Wave – Exchange – Wave 03`) so outputs cross-reference cleanly across discovery, planning, validation, and reporting.
