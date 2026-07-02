# 8. Deliverables Summary — Cloud-First Autopilot Zero-Touch Provisioning

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The cloud-first model (Entra join + Autopilot), the ESP, provisioning-time apps, the zero-touch experience, and the later-domain-join decision criteria |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps: register, profile, ESP, apps/baseline, validate, expand, plus the domain-join exception path |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CFAP-Discovery.ps1` | Reports Autopilot/enrollment readiness — OS build/edition, OOBE/registration state, hardware-hash export, and tenant registration status (read-only) |
| `CFAP-Validation.ps1` | Per-device provisioning/enrollment validation — Autopilot registration, Entra join, Intune enrollment, assigned apps/baseline present (read-only) |
| `CFAP-Report.ps1` | Provisioning-success and technician-touch report across the Autopilot group (Microsoft Graph, read-only) |
| `CFAP-Remediation.ps1` | Safe remediation of failed provisioning; default `-WhatIf` (re-sync, re-trigger enrollment/app install) |
| `CFAP-Set-AutopilotTargeting.ps1` | Builds/maintains the dynamic Autopilot target group and confirms profile/ESP assignment (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the repeatable model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Windows devices that provision themselves on power-on — Entra-joined via Autopilot with apps and policy
applied at enrollment, domain join only where truly required — cutting technician effort to almost
nothing, proven on a pilot before you scale.
