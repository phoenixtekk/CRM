# 8. Deliverables Summary — Microsoft Intune First-Time Setup for Windows

## What you receive

### Documentation (both variants)
- **Implementation Solution Guide (PDF + Word)** — the complete, click-by-click solution:
  - Executive Summary
  - Solution Overview (what it is, how Windows enrollment works, scope, objects created)
  - Requirements (licensing, roles, Entra, groups, service-principal ownership, devices, network — each
    with Description · Why · Verify · Implement-if-missing)
  - Implementation Guide (ordered: enable auto-enrollment → pilot groups → user-driven enrollment →
    basic Entra-joined Autopilot → pilot → validate → expand)
  - Testing & Validation (PASS/FAIL gates for both enrollment paths)
  - Troubleshooting
  - Best Practices
  - Intune Solutions category global requirements

### PowerShell scripts (Plus / We-Deploy variant only)
Five Microsoft Graph / Windows scripts, read-only by default and cloud-aware
(`Connect-MgGraph -Environment Global | USGov | USGovDoD`):
- **`INTBASE-Preflight.ps1`** — verify licensing, roles, MDM authority, Windows auto-enrollment scope,
  and that the Intune Provisioning Client owns `INTBASE - Autopilot Devices`.
- **`INTBASE-Get-AutopilotHash.ps1`** — collect/import a device's Autopilot hardware hash (CSV).
- **`INTBASE-Validate-Enrollment.ps1`** — confirm a device is Entra-joined, Intune-enrolled, and
  compliant.
- **`INTBASE-Report-Enrollment.ps1`** — list enrolled Windows devices with enrollment method (user-driven
  vs Autopilot).
- **`INTBASE-Remediation.ps1`** — guarded (`-WhatIf` default) fix for a missing auto-enrollment/CA scope
  or the missing group owner.

### Configuration templates (Plus / We-Deploy variant only)
- **`autopilot-deployment-profile.json`** — sample user-driven, Entra-joined Autopilot profile.
- **`enrollment-status-page.json`** — sample minimal Enrollment Status Page config.
- **`windows-enrollment-restrictions.json`** — sample Windows enrollment platform restriction.
- **`autopilot-hardware-hash.csv`** — hardware-hash CSV column template for import.

## The two ways to buy
| | **Essentials (Self-Deploy)** | **Plus (We-Deploy)** |
|---|---|---|
| Documentation (PDF + Word) | Yes | Yes |
| PowerShell scripts | — | Yes (5) |
| Configuration templates | — | Yes (4) |
| Done-for-you deployment | — | **Yes** — we schedule and run your basic Intune stand-up + first Windows enrollments after checkout |
| Bundle | `INTBASE-Essentials.zip` | `INTBASE-Complete-Solution.zip` |

## Objects this solution creates (for your records)
`INTBASE - Windows Users - Pilot` · `INTBASE - Autopilot Devices` (Assigned; owned by the Intune
Provisioning Client) · `INTBASE - Autopilot - Pilot` · `INTBASE - ESP - Pilot` ·
`INTBASE - Windows Enrollment - Pilot` · `INTBASE - Compliance - Windows Pilot`

## Where to go next
Free **Enable Microsoft Intune Quick-Start** → **this solution** → **Windows Autopilot** and
**Cloud-First Autopilot Zero-Touch** for production-scale depth.
