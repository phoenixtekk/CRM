# 8. Deliverables Summary — Application Packaging & Deployment Standards

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case: why an app catalog decays without a standard, and what this fixes |
| 1. Solution Overview | The standards layer above per-app packaging; four control points; the three app formats; what the standard produces |
| 2. Requirements Guide | Every prerequisite (owner, two reviewers, Graph SDK/scopes, RBAC, evidence store, pilot population, Government Store position, taxonomy, baseline) with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Create the tenant objects; the format decision matrix + tree; the packaging specification (naming, versioning, metadata); detection-rule standards + banned patterns; command/return-code/reboot standards; the intake template; the acceptance checklist; peer review & sign-off; ring/assignment hygiene; enforcement & audit |
| 5. Testing Guide | Validates the standard is in place (Part A) and that a package passes through it (Part B), with pass/fail gates |
| 6. Troubleshooting Guide | Field issues with the standard, the scripts, and packages that fail their gates |
| 7. Best Practices | Field-proven rules that keep the catalog clean at scale |

## PowerShell scripts (Microsoft Graph, read-only by default)

| Script | What it does |
|---|---|
| `APPSTD-Invoke-PackageStandardAudit.ps1` | Scans every app for naming-convention, banned-word, publisher, version-stamp, description-standard, and legacy-LOB violations; console summary + optional CSV baseline (read-only) |
| `APPSTD-Test-DetectionRuleQuality.ps1` | Reads Win32 detection rules and flags the banned patterns B1–B10 (folder-only, no-version, shared runtime, per-user path in system context, multi-rule, acting/`Win32_Product`/`Write-Host` scripts); the automated half of acceptance Gate 3 (read-only) |
| `APPSTD-Get-AssignmentHygieneReport.ps1` | Reports assignment violations: All Devices/All Users targeting, Required+Uninstall conflicts, duplicate same-intent assignments, missing standard exclusion group, and orphan apps (read-only) |
| `APPSTD-Get-PackageMetadataCompleteness.ps1` | Scores each app 0–100 on publisher, category, the three-line standardised description, developer/owner, info URL, and logo; lists apps below threshold (read-only) |
| `APPSTD-Set-AppMetadataStandard.ps1` | Normalises publisher, category, and the standardised description block from a CSV; **preview by default**, supports `-WhatIf`, changes nothing until `-Apply`; never touches detection, commands, or assignments |

## Reusable templates (inside the Implementation Guide)

- **Package Intake & Specification Template** (Step 7) — the per-app, per-version form completed
  before packaging.
- **Package Acceptance Checklist** (Step 8) — the five-gate quality gate every package must pass.
- **Package Sign-off Record** (Step 9) — the retained evidence of peer review and release approval.
- **Exceptions Register** (Step 10e) — the honest log of accepted waivers with expiry dates.

## What the buyer receives

- This specification as a **Word** document and a **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable standard following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome

An organisation-wide packaging standard that keeps the app catalog consistent, auditable, and clean
as it grows — every app correctly named and version-stamped, every detection rule provably correct,
every release peer-reviewed and evidenced, every assignment hygienic, and the whole catalog audited on
a cadence by the included scripts. This is the specification layer **above** per-app packaging; it
governs how every application is delivered, not how any single one is wrapped.
