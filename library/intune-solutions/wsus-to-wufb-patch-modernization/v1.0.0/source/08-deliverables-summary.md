# 8. Deliverables Summary — WSUS to Windows Update for Business Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case for retiring WSUS and what's in the box |
| 1. Solution Overview | Why WSUS is a liability, the target WUfB state, the coexistence-then-cutover plan, the conflicting settings removed |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory WSUS, build rings, remove WSUS/GPO, validate, expand, decommission |
| 5. Testing Guide | Validation procedures with pass/fail and decommission gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WSUSM-Discovery.ps1` | Read-only: detects the WSUS server pointer and conflicting GPO/registry update policy (`WUServer`, `UseWUServer`, `DoNotConnectToWindowsUpdateInternetLocations`) plus OS build |
| `WSUSM-Validation.ps1` | Read-only: confirms a device scans Microsoft/WUfB (not WSUS) and the ring policy applied |
| `WSUSM-Report.ps1` | Read-only: fleet patch-status + ring report (Microsoft Graph) |
| `WSUSM-Remediation.ps1` | Default `-WhatIf`: clears residual WSUS pointers / conflicting policy |
| `WSUSM-Set-UpdateRingTargeting.ps1` | Builds the update-ring device groups (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable migration following the model: **Assess → Configure → Pilot → Validate → Expand**,
  with a pilot gate before WSUS decommission.

## Outcome
Windows patching modernized off WSUS — devices scanning Microsoft via Intune update rings wherever
they are, the conflicting WSUS/GPO policy removed, and the WSUS servers decommissioned — proven on a
pilot before scale.
