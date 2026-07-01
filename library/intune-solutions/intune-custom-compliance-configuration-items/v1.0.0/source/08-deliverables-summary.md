# 8. Deliverables Summary — Intune Custom Compliance & Configuration Items (Scripted)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How custom compliance works (detection script + JSON rule + settings mapping), scripted config items, and the Conditional Access link |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps with a worked detection-script + JSON-rule example |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CUSTCOMP-Discovery.ps1` | Reports OS build and the device-side values a detection script reads (registry value, app version) as JSON; read-only |
| `CUSTCOMP-Validation.ps1` | Validates a detection script + JSON rule pairing (valid JSON, setting names match); read-only |
| `CUSTCOMP-Report.ps1` | Fleet-wide custom-compliance status per device (Microsoft Graph); read-only |
| `CUSTCOMP-Remediation.ps1` | Safe remediation; forces an MDM sync and re-evaluation (default `-WhatIf`) |
| `CUSTCOMP-Set-ScopeTargeting.ps1` | Creates/populates the custom-compliance pilot/broad device groups (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the Phoenixtekk model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Device state measured and enforced to your standards — scripted detection + JSON rules and config
items covering what the built-in settings can't, wired into Conditional Access, and proven on a pilot.
