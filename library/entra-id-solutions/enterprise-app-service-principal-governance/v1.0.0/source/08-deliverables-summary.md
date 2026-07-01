# 8. Deliverables Summary — Enterprise App & Service Principal Governance

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The Entra app model, delegated vs. application permissions, consent and consent-phishing, over-permission, secret/certificate lifecycle |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (inventory, permission/consent review, user-consent policy, admin-consent workflow, remediate, credential expiry, validate, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `APPGOV-Discovery.ps1` | Inventories enterprise apps and service principals with app-role assignments, OAuth2 delegated grants, owners, and credential expiry via Microsoft Graph (read-only) |
| `APPGOV-Validation.ps1` | Confirms the user-consent policy, admin-consent workflow, and that remediated apps no longer hold risky grants (read-only) |
| `APPGOV-Report.ps1` | Over-permission and expiring-secret report — ranks apps by permission risk and lists credentials expiring or with no expiry (read-only) |
| `APPGOV-Remediation.ps1` | Safely revokes risky OAuth2 grants and app-role assignments; `-WhatIf` by default |
| `APPGOV-Set-ScopeTargeting.ps1` | Builds and previews the governance consent-scope and reviewer groups |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Every enterprise app and service principal inventoried and governed — over-permissioned grants and
risky consents remediated, user consent controlled, and app secrets and certs on a managed lifecycle
— closing a favorite attacker foothold, proven on a pilot before you scale.
