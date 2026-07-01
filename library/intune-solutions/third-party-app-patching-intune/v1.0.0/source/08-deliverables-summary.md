# 8. Deliverables Summary — Third-Party Application Patching with Intune

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Why third-party apps are the attack surface; the catalog (auto-update) and packaged (detection + supersedence) paths; the ring model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps for both update paths, assigned by ring |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `TPP-Discovery.ps1` | Inventories installed third-party apps and versions from the registry uninstall keys |
| `TPP-Validation.ps1` | Confirms managed apps on a device meet their target versions (patch-state validation) |
| `TPP-Report.ps1` | Fleet-wide out-of-date exposure across managed devices (Microsoft Graph + targets) |
| `TPP-Remediation.ps1` | Safe remediation (default `-WhatIf`); nudges stuck app updates via sync / re-evaluation |
| `TPP-Set-UpdateRingTargeting.ps1` | Builds the Pilot/Broad update-ring groups and seeds membership (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess -> Configure -> Pilot -> Validate -> Expand.**

## Outcome
The highest-risk third-party apps kept current automatically across the fleet — catalog apps
auto-updating, everything else packaged and superseded, deployed in rings, with a fleet exposure
report — proven on a pilot before you scale.
