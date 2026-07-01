# 8. Deliverables Summary — Hybrid Identity with Active Directory & Microsoft Entra Connect

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | Hybrid identity, Connect Sync vs. Cloud Sync, auth methods, Seamless SSO, hybrid join, sync health |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (prepare AD, install Connect, auth method, scope, hybrid join, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `HYBID-Discovery.ps1` | AD/identity readiness: AD health, `.local`/duplicate UPNs, host and TLS readiness (read-only) |
| `HYBID-Validation.ps1` | Confirms the sync ran, objects exported, and a test sign-in works (read-only) |
| `HYBID-Report.ps1` | Sync health + object coverage across AD and Entra ID via ADSync and Microsoft Graph (read-only) |
| `HYBID-Remediation.ps1` | Safely fixes sync errors and duplicate UPN/proxyAddress values; `-WhatIf` by default |
| `HYBID-Set-SyncScopeHelper.ps1` | Helper to review and stage OU/domain sync-scope changes for the wizard |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
One reliable identity spanning Active Directory and Entra ID — synchronized cleanly, authenticated by
the right method, with hybrid join and healthy sync, proven on a pilot before you scale.
