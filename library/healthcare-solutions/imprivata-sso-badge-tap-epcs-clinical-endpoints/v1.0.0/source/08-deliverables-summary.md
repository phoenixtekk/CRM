# 8. Deliverables Summary — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

This solution delivers a complete, productized package: implementation documentation, runnable PowerShell tooling, and a hero image. Everything follows the standard deployment model — Intune-delivered agent and reader drivers, a named Entra device group, configuration profiles, and identity integration — with appliance-side policy and EPCS/DEA specifics deferred to your Imprivata administrator and compliance team.

## Documentation

| Document | Purpose |
|----------|---------|
| `01-solution-overview.md` | What the solution delivers, the problem it solves, scope/boundaries, and the phase model. |
| `02-requirements.md` | Solution-specific requirements R1–R10 (OneSign licensing/appliance, Confirm ID for EPCS, readers/drivers, Intune, identity, OS, shared-device model, EPCS proofing/two-factor, audit, compliance sign-off), each with Verify / Implement-if-missing. |
| `global-requirements-healthcare-solutions.md` | Category-wide prerequisites G1–G7 (tenant/roles, Windows/Intune licensing, HIPAA/HITRUST + change control, maintenance windows, network reachability, test device, rollback). |
| `03-implementation.md` | The build, Assess → Expand, with full navigation paths and named objects. |
| `05-testing.md` | Test plan T1–T9 with PASS/FAIL and the acceptance gate. |
| `06-troubleshooting.md` | Symptom-driven fixes for reader, badge, tap speed, Epic SSO, fast user switching, EPCS two-factor, and audit issues. |
| `07-best-practices.md` | Identity, deployment, shared-device, EPCS/compliance, operations, and data-handling guidance. |
| `executive-summary.md` | Business-level summary for decision-makers. |
| `08-deliverables-summary.md` | This document. |

## PowerShell scripts (5)

All scripts are read-only by default and intended to be run by an Intune administrator with appropriate Microsoft Graph permissions. Each has a `.SYNOPSIS` plus PURPOSE / HOW TO RUN / EXPECTED RESULTS header and a neutral `.NOTES` line.

| Script | Purpose |
|--------|---------|
| `IMPRIVATA-Discovery.ps1` | Tenant readiness: confirms the named agent app and reader-driver app exist and are assigned, the `IMPRIVATA – Clinical Endpoints` group exists, and target devices are present. Read-only. |
| `IMPRIVATA-Validation.ps1` | Per-device validation: agent installed, reader driver installed, device in group — outputs PASS/FAIL. |
| `IMPRIVATA-Report.ps1` | Fleet report: agent install state and device-group coverage, exported to CSV. |
| `IMPRIVATA-Remediation.ps1` | Safe re-deploy of the named agent/driver app to a device; runs in `-WhatIf`/read-only by default, acts only with `-Apply`. |
| `IMPRIVATA-Set-ClinicalGroup.ps1` | Creates the `IMPRIVATA – Clinical Endpoints` group and optionally assigns the named apps/profiles; supports `-WhatIf`. |

## Hero image

| Asset | Purpose |
|-------|---------|
| `IMPRIVATA-hero.png` | Listing hero image for the solution. |

## Named objects produced by the solution

These objects are created during implementation and reused verbatim across the docs and scripts:

- Win32 app: `Imprivata Agent – Clinical Endpoints – Deploy` (publisher `Imprivata, Inc.`)
- Win32 app: `Proximity Reader Driver – Clinical Endpoints – Deploy` (publisher = reader hardware vendor)
- Entra device group: `IMPRIVATA – Clinical Endpoints` (pilot subset `IMPRIVATA – Clinical Endpoints – Pilot`)
- Device configuration profile: `Imprivata Endpoint – Clinical Endpoints – Baseline`

## Outcome

A repeatable, validated deployment of Imprivata OneSign tap-and-go badge SSO, fast user switching, Epic/clinical-web SSO, and Confirm ID EPCS two-factor signing across shared clinical endpoints — delivered and monitored through Microsoft Intune, with a clear acceptance gate, rollback, and ongoing reporting.
