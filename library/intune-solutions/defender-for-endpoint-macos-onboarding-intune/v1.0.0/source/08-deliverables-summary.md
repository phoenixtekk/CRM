# 8. Deliverables Summary — Microsoft Defender for Endpoint for macOS (Deployment & Onboarding via Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The MDE-for-macOS deployment model: system extensions, Full Disk Access (PPPC/TCC), network filter, background services, notifications, and the onboarding blob delivered via Intune — and why order matters |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing (MDE licensing, APNs, macOS enrollment, onboarding package, extension identifiers, pilot), plus the object-naming convention |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps: build the five capability profiles first, gate, deploy the Defender app, deploy the onboarding profile, validate `mdatp` health on a pilot, roll back if needed, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates — capability-before-onboarding gate, agent-health gate, portal-activity and EDR-detection tests |
| 6. Troubleshooting Guide | Field issues and remediation — starting with the classic "onboarded but not protecting" failure |
| 7. Best Practices | Field-proven recommendations, centered on the extension-approval order |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MACMDE-Discovery.ps1` | Tenant/device MDE-for-macOS readiness: APNs presence, enrolled Macs, macOS version spread, and existing Defender/security macOS profiles to review for conflicts (read-only) |
| `MACMDE-Validation.ps1` | Per-device check that a Mac has the five capability profiles, the Defender app, and the onboarding profile in a good state via Intune device config/app states (read-only) |
| `MACMDE-Report.ps1` | Fleet MDE-for-macOS posture + drift via Microsoft Graph across the five profiles, the app, and the onboarding profile (read-only) |
| `MACMDE-Remediation.ps1` | Reapplies/repairs drifted MDE objects by re-syncing the affected Macs and confirming assignment; `-WhatIf` by default |
| `MACMDE-Set-ScopeTargeting.ps1` | Safely widens the target group membership during Expand; `-WhatIf` by default |

## Object naming convention (used across docs and scripts)
- System Extensions profile: `MDE macOS – System Extensions`
- Full Disk Access (PPPC/TCC) profile: `MDE macOS – Full Disk Access`
- Network filter profile: `MDE macOS – Network Filter`
- Background services profile: `MDE macOS – Background Services`
- Notifications profile: `MDE macOS – Notifications`
- Onboarding profile (custom `.mobileconfig`): `MDE macOS – Onboarding`
- Microsoft Defender app: `MDE macOS – Defender App`
- Device groups: `MDE macOS – Pilot Devices` / `MDE macOS – Production Devices`
- Tag in every profile/app description: `MDE-macOS`

## What the buyer receives
- These guides as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable, order-safe method: deliver the capability profiles first, then the app and onboarding,
  then prove health — **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every Mac onboarded to Microsoft Defender for Endpoint **correctly** — the required system-extension,
Full Disk Access, network-filter, background-service, and notification approvals in place *before* the
onboarding blob — with the agent proven healthy (extensions running, real-time protection on, active
in the Defender portal), validated on a pilot before you scale.
