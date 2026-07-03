# 8. Deliverables Summary — Enterprise App & Service Principal Governance (Government / GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box — GCC High edition |
| 1. Solution Overview | The Entra app model, delegated vs. application permissions, consent and consent-phishing, over-permission, secret/certificate lifecycle, plus **Commercial vs GCC High — what's different** |
| GCC High Parity Notes | Cited US Gov endpoints, confirmed GA features, and confirmed parity gaps; "verify for GCC High" items |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, in US Gov terms (GCC High tenant, G-series licensing, USGov Graph) |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps using the `entra.microsoft.us` portals with GCC-High caveats inline (inventory, permission/consent review, user-consent policy, admin-consent workflow, remediate, credential expiry, validate, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a "you are in USGov" gate |
| 6. Troubleshooting Guide | Field issues and remediation, with GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for a sovereign tenant |

## PowerShell scripts (all connect `-Environment USGov` → `graph.microsoft.us`)
| Script | What it does |
|---|---|
| `APPGOVG-Discovery.ps1` | Inventories enterprise apps and service principals with app-role assignments, OAuth2 delegated grants, owners, and credential expiry via US Gov Microsoft Graph (read-only) |
| `APPGOVG-Validation.ps1` | Confirms the user-consent policy, admin-consent workflow, and that remediated apps no longer hold risky grants (read-only) |
| `APPGOVG-Report.ps1` | Over-permission and expiring-secret report — ranks apps by permission risk and lists credentials expiring or with no expiry (read-only) |
| `APPGOVG-Remediation.ps1` | Safely revokes risky OAuth2 grants and app-role assignments; `-WhatIf` by default |
| `APPGOVG-Set-ScopeTargeting.ps1` | Builds and previews the governance consent-scope and reviewer groups |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP, pre-wired for US Gov Graph (`-Environment USGov`).
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Every enterprise app and service principal inventoried and governed on GCC High — right portals,
right endpoints, parity gaps handled — over-permissioned grants and risky consents remediated, user
consent controlled, and app secrets and certs on a managed lifecycle — closing a favorite attacker
foothold, proven on a pilot before you scale.
