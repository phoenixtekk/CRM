# 8. Deliverables Summary — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

This package is a complete, enterprise-grade program kit for migrating an organization's entire endpoint estate off VMware Workspace ONE UEM and onto Microsoft Intune — Windows, iOS/iPadOS, Android, and macOS. It contains the documentation playbook, five PowerShell tools, and a hero image.

## Documentation

| File | What it covers |
|---|---|
| `01-solution-overview.md` | What the program is, the four platform workstreams, the single-MDM-per-device reality, why it's high-risk, how it works, the per-platform approach, benefits, honest limitations, and the standard program model. |
| `02-requirements.md` | R1–R14 prerequisites (Description / Why / Verify / Implement-if-missing), including the GATING identity/licensing, Workspace ONE access, per-platform enrollment plumbing, and identity-readiness requirements; introduces the `<Purpose> – <Scope> – <Stage>` naming convention. |
| `global-requirements-migrations.md` | Category-level baseline requirements common to every Migrations engagement (target tenant, licensing, source access, inventory, enrollment prerequisites, pilot/waves, change control & rollback). |
| `03-implementation.md` | The full program runbook: Discover → Assess → Plan → Configure → Pilot → Validate (pilot-wave gate) → Expand (coexistence → cutover → validate, per platform) → Decommission, with named objects, exact Intune/Entra/ABM navigation, and per-platform cutover runbooks. |
| `05-testing.md` | Numbered tests with PASS/FAIL gates and a per-platform acceptance gate (enrollment, parity, compliance, apps, access, coexistence integrity, rollback rehearsal). |
| `06-troubleshooting.md` | Enrollment, coexistence/dual-MDM, ADE/ABM, parity-profile, app-delivery, Conditional Access, and rollback failure modes with fixes. |
| `07-best-practices.md` | Program best practices: enrollment-plumbing-first, pilot every platform, parity discipline, do-no-harm Conditional Access, cutover mechanics, comms, rollback, decommission discipline, evidence. |
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |

## PowerShell scripts

All scripts carry a header with PURPOSE / HOW TO RUN / EXPECTED RESULTS and a neutral, white-label note. The Intune/Entra target side uses **Microsoft Graph PowerShell** (`Connect-MgGraph`, `Get-MgDeviceManagementManagedDevice`, groups). Any Workspace ONE source-side call is a **generic `Invoke-RestMethod`** against the Workspace ONE REST API, clearly flagged and deferred to current VMware documentation (no invented endpoints).

| Script | What it does |
|---|---|
| `scripts\WS1PROG-Discovery.ps1` | **Read-only baseline.** Captures the Intune/Entra target side (managed devices by platform, enrollment-channel status, groups, licensing readiness) via Microsoft Graph, and provides a flagged optional Workspace ONE REST inventory hook — the Discovery baseline (R5) reconciled against the source export. |
| `scripts\WS1PROG-Validation.ps1` | **Per-device / per-wave migration validation.** Checks each wave device's Intune enrollment state, single-MDM status, compliance, and assigned-app/profile state via Graph; emits PASS/FAIL per check for the acceptance gates. Read-only. |
| `scripts\WS1PROG-Report.ps1` | **Program/wave status report.** Reads the wave plan + live Graph state and produces per-platform and per-wave % migrated, compliant, and app-success as a CSV plus a console summary — the program dashboard. Read-only. |
| `scripts\WS1PROG-Remediation.ps1` | **Safe remediation helpers.** Retry enrollment sync, (re-)add devices to the correct wave group, and re-evaluate compliance for failed migrations. Runs `-WhatIf` by default; requires `-Apply` to make any change. |
| `scripts\WS1PROG-Set-WaveTargeting.ps1` | **Wave + targeting builder.** Reads the Discovery/source CSV, groups devices/users into balanced waves (cohort-aware), and creates/populates the Entra security groups (`Wave 00 Devices – All – Pilot`, `Wave NN Devices – <Scope> – Wave NN`) that drive Intune assignment. Supports `-WhatIf`. |

## Hero image

| File | Purpose |
|---|---|
| `WS1PROG-hero.png` | Listing/marketing hero image for the solution. |

> **Naming convention reminder:** the scripts and runbooks share the object-naming standard `<Purpose> – <Scope> – <Stage>` (e.g. `Wave NN Devices – Windows – Wave 03`, `Parity Policy Set – iOS – Target`) so outputs cross-reference cleanly across discovery, planning, validation, and reporting.
