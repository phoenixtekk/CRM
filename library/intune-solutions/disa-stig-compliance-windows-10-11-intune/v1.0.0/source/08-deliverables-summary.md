# 8. Deliverables Summary — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the DISA STIG is, CAT I/II/III severities, how rules map to Intune (settings catalog + ADMX), STIG vs Microsoft baselines, SCAP/STIG Viewer authority, POA&M exceptions, compliance/drift model, release lifecycle |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing, plus the object-naming convention and POA&M register |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide (net-new) | Exact, ordered Intune steps: stage STIG, build CAT I/II/III, import ADMX, POA&M exceptions, compliance, pilot, validate, rollback, expand |
| 4. Maintenance & Update Guide | The DISA STIG-release lifecycle: Obtain → Diff → Assess/Approve → Update → Re-validate → Record, plus ongoing drift maintenance |
| 5. Testing Guide | Validation procedures with pass/fail gates (including SCAP reconciliation and a maintenance dry-run) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `STIG-Discovery.ps1` | Tenant/device STIG-readiness: enrollment, edition/build, BitLocker/Defender/Secure Boot, and conflicting authority signals (read-only) |
| `STIG-Validation.ps1` | Per-device STIG-compliance check against the expected baseline values (read-only) |
| `STIG-Report.ps1` | Fleet STIG posture + drift via Microsoft Graph device configuration states (read-only) |
| `STIG-Remediation.ps1` | Reapplies drifted settings by forcing policy sync; `-WhatIf` by default |
| `STIG-Compare-StigVersion.ps1` | Diffs a NEW DISA STIG export against the current live baseline to drive the update process |

## Object naming convention (used across docs and scripts)
- Settings-catalog policies by severity: `STIG Win10/11 – CAT I – Pilot` / `– Production` (and `– CAT II –`, `– CAT III –` variants)
- Imported ADMX policy: `STIG Win10/11 – ADMX – Pilot` / `STIG Win10/11 – ADMX – Production`
- Compliance policy: `STIG Win10/11 – Compliance`
- Device groups: `STIG Win10/11 – Pilot Devices` / `STIG Win10/11 – Production Devices`
- Version tag in every policy description: `STIG-Win-vYYYY.MM`

## What the buyer receives
- These guides as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process for both net-new implementation and ongoing release maintenance:
  Assess → Configure → Pilot → Validate → Expand (and Obtain → Diff → Assess/Approve → Update → Re-validate → Record for each new STIG release).

## Outcome
Every Windows 10/11 device hardened to the DISA STIG and provably compliant — with a documented
release lifecycle that keeps the baseline current each time DISA revises it and exceptions tracked as
POA&M, proven on a pilot before you scale.
