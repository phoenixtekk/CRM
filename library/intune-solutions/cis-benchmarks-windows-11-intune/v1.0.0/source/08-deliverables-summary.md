# 8. Deliverables Summary — CIS Benchmarks for Windows 11 (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What CIS Benchmarks are, L1 vs L2, how controls map to Intune (settings catalog + ADMX), CIS vs Microsoft baselines, compliance/drift model, version lifecycle |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing, plus the object-naming convention |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide (net-new) | Exact, ordered Intune steps: stage benchmark, build L1/L2, import ADMX, exceptions, compliance, pilot, validate, rollback, expand |
| 4. Maintenance & Update Guide | The CIS benchmark-version lifecycle: Obtain → Diff → Assess/Approve → Update → Re-validate → Record, plus ongoing drift maintenance |
| 5. Testing Guide | Validation procedures with pass/fail gates (including a maintenance dry-run) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CIS11-Discovery.ps1` | Tenant/device CIS-readiness: enrollment, edition/build, and conflicting authority signals (read-only) |
| `CIS11-Validation.ps1` | Per-device CIS-compliance check against the expected baseline values (read-only) |
| `CIS11-Report.ps1` | Fleet CIS posture + drift via Microsoft Graph device configuration states (read-only) |
| `CIS11-Remediation.ps1` | Reapplies drifted settings by forcing policy sync; `-WhatIf` by default |
| `CIS11-Compare-BenchmarkVersion.ps1` | Diffs a NEW CIS benchmark export against the current live baseline to drive the update process |

## Object naming convention (used across docs and scripts)
- Settings-catalog policies: `CIS Win11 – L1 – Pilot` / `CIS Win11 – L1 – Production` (and `– L2 –` variants)
- Imported ADMX policy: `CIS Win11 – ADMX – Pilot` / `CIS Win11 – ADMX – Production`
- Compliance policy: `CIS Win11 – Compliance`
- Device groups: `CIS Win11 – Pilot Devices` / `CIS Win11 – Production Devices`
- Version tag in every policy description: `CIS-Win11-vX.Y.Z`

## What the buyer receives
- These guides as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process for both net-new implementation and ongoing version maintenance:
  **Assess → Configure → Pilot → Validate → Expand** (and **Obtain → Diff → Assess/Approve → Update → Re-validate → Record** for each new benchmark version).

## Outcome
Every Windows 11 device hardened to the CIS Benchmark and provably compliant — with a documented
update lifecycle that keeps the baseline current each time CIS revises it, proven on a pilot before
you scale.
