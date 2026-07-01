# 8. Deliverables Summary — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The IdP integration model: SAML SSO, SCIM provisioning, identity-based policy, and how it complements Entra Conditional Access |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, and the named artifacts |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (SAML SSO, SCIM provisioning, identity policy); Entra click-by-click, Netskope deferred |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSSSO-Discovery.ps1` | Reports the Netskope enterprise app, its SAML SSO config, SCIM provisioning status, and group structure (read-only, Microsoft Graph) |
| `NSSSO-Validation.ps1` | Confirms SSO is configured and SCIM provisioning is enabled on the app (read-only, Microsoft Graph) |
| `NSSSO-Report.ps1` | SSO mode, provisioning status, and assigned/target groups coverage report (read-only, Microsoft Graph) |
| `NSSSO-Remediation.ps1` | Safe remediation of provisioning gaps (default `-WhatIf`); ensures the scope groups are assigned to the app (Microsoft Graph) |
| `NSSSO-Set-IdentityScopeTargeting.ps1` | Creates/ensures the pilot and production identity scope groups and their membership (Microsoft Graph) |

> Netskope-side SSO/SCIM specifics (the Netskope SAML screen, the SCIM tenant URL/secret token, and
> Netskope policy) are flagged and deferred to the official Netskope documentation; the scripts act
> on the Entra ID / Microsoft Graph side only.

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Netskope policy that follows the user — Entra ID single sign-on, SCIM-provisioned users and groups,
and identity-based steering and enforcement — proven on a pilot before the fleet.
