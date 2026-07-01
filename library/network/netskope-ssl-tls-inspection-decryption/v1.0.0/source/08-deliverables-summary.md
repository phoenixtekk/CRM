# 8. Deliverables Summary — SSL/TLS Inspection & Decryption Rollout (Netskope)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Why decryption matters, the inspection certificate trust chain, decryption policy, do-not-decrypt bypasses, privacy/compliance |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Ordered steps: deploy the inspection certificate via Intune, build decryption policy + bypass list, pilot, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSSSL-Discovery.ps1` | Reports OS/store state and whether an inspection root is already trusted (certificate/decryption readiness). Read-only |
| `NSSSL-Validation.ps1` | Confirms the inspection root is in the trusted root store and the chain validates. Read-only |
| `NSSSL-Report.ps1` | Fleet certificate-trust + decryption-readiness inventory via Microsoft Graph. Read-only |
| `NSSSL-Remediation.ps1` | Safe remediation (default `-WhatIf`); requests an MDM sync so the trusted-certificate profile re-applies |
| `NSSSL-Set-ScopeTargeting.ps1` | Builds/populates the pilot and production Entra scope groups via Microsoft Graph |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Encrypted traffic made inspectable — the inspection certificate trusted on every device, decryption
policy enforced with the right do-not-decrypt bypasses for pinned and sensitive apps, proven on a
pilot before scaling.

## Vendor note
Netskope console internals are deferred to the official Netskope documentation and your tenant.
Intune certificate-profile navigation and the PowerShell scripts are exact; Netskope decryption-policy
and bypass-list menu paths are named at the procedural level and confirmed in your Netskope console.
