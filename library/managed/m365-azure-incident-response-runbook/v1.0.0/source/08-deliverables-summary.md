# 8. Deliverables Summary — M365 & Azure Incident Response & Escalation Runbook

This package is a complete, enterprise-grade incident & problem management kit for leading high-priority and escalated incidents across Microsoft 365 and Azure. It contains the documentation runbook, five PowerShell tools, and a hero image.

## Documentation

| File | What it covers |
|---|---|
| `01-solution-overview.md` | What the runbook is, the **Detect → Triage → Communicate → Diagnose → Resolve → RCA → Permanent Fix** phase model, the named artifacts, the per-workload diagnostic playbooks, how it works, benefits, and honest limitations. |
| `02-requirements.md` | R1–R12 prerequisites (Description / Why / Verify / Implement-if-missing): responder roles + reader access, Service Health access, Entra/Exchange/Azure log access, a Microsoft support plan, a PSA, comms channels, SLAs, and change control. |
| `global-requirements-managed.md` | Baseline requirements common to every Managed-category engagement (tenant/subscriptions, roles, licensing, monitoring + system of record, change control, backup/rollback). |
| `03-implementation.md` | Part A stands up the matrix, templates, playbooks, escalation sheet, RCA, and responder access; Part B is the per-incident runbook with full Microsoft console navigation paths for diagnosis and escalation. |
| `05-testing.md` | Numbered tests (T1–T9) with PASS/FAIL gates, validated through a tabletop/simulated incident: triage correct, comms on cadence, diagnosis reaching root cause, RCA produced, permanent fix logged. |
| `06-troubleshooting.md` | Common failure modes across access/visibility, Service Health discrimination, per-workload diagnosis, escalation, remediation, comms, and the RCA loop — with fixes. |
| `07-best-practices.md` | The operating disciplines: Service-Health-first triage, role coordination, client comms, evidence-led diagnosis and escalation, remediation safety, and the RCA→permanent-fix loop. |
| `executive-summary.md` | One-page business case and outcomes for sponsors/leadership. |

## PowerShell scripts

All scripts carry a `.SYNOPSIS` header with PURPOSE / HOW TO RUN / EXPECTED RESULTS and a NEUTRAL white-label `.NOTES`. Read-only and discovery scripts make no changes; the remediation script defaults to `-WhatIf` and requires `-Apply` to act, on **named objects only**.

| Script | What it does |
|---|---|
| `scripts\INCIDENT-Discovery.ps1` | **Live incident snapshot (read-only).** Pulls current Microsoft 365 + Azure **Service Health**, recent **high-severity sign-ins / risk detections** from Entra, and an **Azure Resource Health** snapshot into one CSV to seed diagnosis. |
| `scripts\INCIDENT-Validation.ps1` | **Responder readiness (PASS/FAIL).** Verifies responders hold the required roles, can read the key logs (Service Health, sign-in, message trace, Azure Monitor), and that a Microsoft support plan is in place; emits PASS/FAIL per check for the §05 readiness gates. |
| `scripts\INCIDENT-Report.ps1` | **Incident metrics report.** Reads incident timeline data and computes **MTTA/MTTR** and per-severity counts/trends to CSV — the program dashboard that proves the runbook is working. |
| `scripts\INCIDENT-Remediation.ps1` | **Safe common fixes.** Performs scoped, well-understood remediations for a **named object** (e.g. revoke a user's sessions, re-enable a disabled mail-flow connector). Runs read-only / `-WhatIf` by default; requires `-Apply` to change anything. |
| `scripts\INCIDENT-Set-ResponderRoles.ps1` | **Responder access setup.** Creates the `Responder Access Group – Identity – Response` Entra group and assigns the reader/scoped-admin roles responders need; supports `-WhatIf` preview before `-Apply`. |

## Hero image

| File | Purpose |
|---|---|
| `INCIDENT-hero.png` | Listing/marketing hero image for the solution. |

> **Naming convention reminder:** the scripts and runbook share the object-naming standard `<Purpose> – <Scope> – <Stage>` (e.g. `Responder Access Group – Identity – Response`, `Microsoft Escalation Sheet – Incident – Escalate`) so outputs cross-reference cleanly across discovery, validation, remediation, and reporting.
