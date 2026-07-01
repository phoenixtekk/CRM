# 8. Deliverables Summary — Windows 11 Healthcare Endpoint Baseline

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | What a baseline is; configuration profile, settings catalog, security baseline, update, power; benefits and limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Healthcare Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps with named objects |
| 5. Testing Guide | Validation procedures with a pilot-gate pass/fail |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `W11HC-Discovery.ps1` | Reports OS build, edition, TPM, Secure Boot, enrollment, and conflicting authority (read-only) |
| `W11HC-Validation.ps1` | Confirms the baseline settings applied on a device (Defender, SmartScreen, update, power) (read-only) |
| `W11HC-Report.ps1` | Fleet-wide baseline status and OS-build inventory via Microsoft Graph (read-only) |
| `W11HC-Remediation.ps1` | Safe remediation; forces an MDM sync so the baseline re-applies (default `-WhatIf`) |
| `W11HC-Set-BaselineTargeting.ps1` | Creates and populates the clinical/corporate and pilot/production device groups via Microsoft Graph |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Every Windows 11 endpoint on one documented, auditable baseline — consistent security, update, and
power behavior for shared clinical and corporate devices — proven on a pilot before fleet rollout.
