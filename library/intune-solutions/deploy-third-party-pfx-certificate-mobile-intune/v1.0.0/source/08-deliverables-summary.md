# 8. Deliverables Summary — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Why a static third-party PFX is NOT SCEP/PKCS; Path A vs Path B decision guide; app-keychain nuance |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps — chain, import, imported-PFX profile, custom PKCS12 profile, app validation |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | "PFX exists in Graph but won't deploy" diagnostic tree, connector health, intended-purpose mismatch, missing chain, app can't access keychain |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `PFXMOB-Discovery.ps1` | Inventories imported PFX objects, Certificate Connector status, and existing certificate profiles (read-only) |
| `PFXMOB-Validation.ps1` | Per-device: confirms the trusted chain + identity are present and the profile applied (read-only) |
| `PFXMOB-Report.ps1` | Fleet-wide certificate-deployment status (read-only) |
| `PFXMOB-Remediation.ps1` | Safe remediation (`-WhatIf` default): re-assign/repair the profile and re-trigger device sync |
| `PFXMOB-Import-Pfx.ps1` | Helper that imports a third-party PFX to Intune via Microsoft Graph (encrypts to the Certificate Connector public key; sets thumbprint + intended purpose; secure password input) |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
A third-party PFX correctly imported into Intune and delivered to iOS devices through the right profile
type — with the app able to consume it — instead of stalling on the wrong SCEP/PKCS template, proven
on a pilot before scaling.
