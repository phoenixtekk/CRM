# 8. Deliverables Summary — CIS Benchmarks for macOS (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What CIS Benchmarks are, L1 vs L2, how controls map to the three Intune macOS surfaces (settings catalog + custom `.mobileconfig` + shell scripts), CIS vs vendor defaults, compliance/drift model, version lifecycle |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing (incl. APNs and macOS enrollment), plus the object-naming convention |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide (net-new) | Exact, ordered Intune steps: stage benchmark, build L1/L2 catalog, add custom profiles and shell scripts, exceptions, compliance, pilot, validate, rollback, expand |
| 4. Maintenance & Update Guide | The CIS benchmark-version lifecycle: Obtain → Diff → Assess/Approve → Update → Re-validate → Record, plus ongoing drift maintenance |
| 5. Testing Guide | Validation procedures with pass/fail gates (including a maintenance dry-run) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CISMAC-Discovery.ps1` | Tenant/device CIS-readiness for macOS: APNs presence, enrolled Macs, macOS version spread, and conflicting/duplicate macOS policy authority (read-only) |
| `CISMAC-Validation.ps1` | Per-device CIS-compliance check against the expected baseline values, by reading Intune device config states for the Mac (read-only) |
| `CISMAC-Report.ps1` | Fleet CIS posture + drift via Microsoft Graph (macOS configuration policies, custom profiles, and shell-script run states) (read-only) |
| `CISMAC-Remediation.ps1` | Reapplies/repairs drifted policy/profile/script assignments by re-syncing and confirming assignment; `-WhatIf` by default |
| `CISMAC-Compare-BenchmarkVersion.ps1` | Diffs a NEW CIS benchmark export against the current live baseline to drive the update process |

## Object naming convention (used across docs and scripts)
- Settings-catalog policies: `CIS macOS – L1 – Pilot` / `CIS macOS – L1 – Production` (and `– L2 –` variants)
- Custom `.mobileconfig` profile: `CIS macOS – Custom – Pilot` / `CIS macOS – Custom – Production`
- macOS shell script: `CIS macOS – Shell – Pilot` / `CIS macOS – Shell – Production`
- Compliance policy: `CIS macOS – Compliance`
- Device groups: `CIS macOS – Pilot Devices` / `CIS macOS – Production Devices`
- Version tag in every policy/profile/script description: `CIS-macOS-vX.Y.Z`

## What the buyer receives
- These guides as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process for both net-new implementation and ongoing version maintenance:
  **Assess → Configure → Pilot → Validate → Expand** (and **Obtain → Diff → Assess/Approve → Update → Re-validate → Record** for each new benchmark version).

## Outcome
Every Mac hardened to the CIS Benchmark and provably compliant — with a documented update lifecycle
that keeps the baseline current each time CIS revises it (or you move to a new macOS major), proven
on a pilot before you scale.
