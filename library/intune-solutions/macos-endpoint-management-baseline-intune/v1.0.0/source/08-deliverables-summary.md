# 8. Deliverables Summary — macOS Endpoint Management Baseline (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The macOS management model in Intune (MDM/APNs, configuration profiles), settings catalog vs custom `.mobileconfig`, restrictions, compliance policies, macOS software-update management, and the compliance/drift model |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing (incl. APNs, macOS enrollment, groups, baseline decisions), plus the object-naming convention |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps: groups, baseline configuration profile, restrictions, software-update policy, compliance policy, optional custom profile, pilot, validate, rollback, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates (including a safe remediation dry-run) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Naming, settings-catalog-first, conflict avoidance, pilot discipline, update rings, compliance/CA boundaries |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MACBASE-Discovery.ps1` | Tenant/device readiness for a macOS baseline: APNs presence/expiry, enrolled Macs, macOS version spread, and existing macOS configuration/compliance/update policies to review for conflicts (read-only) |
| `MACBASE-Validation.ps1` | Per-device applied-state check — reads Intune device config/compliance states for a named Mac and reports whether the baseline objects applied (read-only) |
| `MACBASE-Report.ps1` | Fleet baseline posture + drift via Microsoft Graph across the baseline configuration policies, custom profiles, and compliance policy; optional per-device CSV (read-only) |
| `MACBASE-Remediation.ps1` | Safely reapplies/repairs drifted baseline objects by issuing a device sync and confirming group assignment; `-WhatIf` by default |
| `MACBASE-Set-ScopeTargeting.ps1` | Adds/stages the pilot or production group assignment on the baseline policies the repeatable way; `-WhatIf` by default |

## Object naming convention (used across docs and scripts)
- Baseline configuration profile: `macOS Baseline – Config – Pilot` / `– Production`
- Restrictions policy: `macOS Baseline – Restrictions – Pilot` / `– Production`
- Software-update policy: `macOS Baseline – Software Update – Pilot` / `– Production`
- Custom `.mobileconfig` profile (if used): `macOS Baseline – Custom – Pilot` / `– Production`
- Compliance policy: `macOS Baseline – Compliance`
- Device groups: `macOS Baseline – Pilot Devices` / `macOS Baseline – Production Devices`
- Version/scope tag in every policy/profile description: `macOS-Baseline-v1.0`

## What the buyer receives
- These guides as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process for building and operating the baseline:
  **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every Mac on a consistent, compliant Intune baseline — configuration profiles, restrictions,
compliance, and managed software updates — provable per device and proven on a pilot before you scale.
