# 8. Deliverables Summary — Privileged Access Workstation (PAW) for Cloud Administration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | What a PAW is; how hardening, isolation, device filters, and PIM fit together; benefits and limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing (Intune, P2 flagged to verify) |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune + Entra steps — build, mark, enforce report-only first, staged enforcement, break-glass excluded |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (and KQL)
| Script | What it does |
|---|---|
| `ENTPAW-Discovery.ps1` | Read-only inventory of privileged roles/holders, device compliance policies, Conditional Access device-filter policies, and current use of the device-marker attribute (Microsoft Graph) |
| `ENTPAW-Validate.ps1` | Confirms the PAW compliance policy, device marker, and the device-filter enforcement policy are in place, report-only, pilot-scoped, and break-glass excluded; checks PIM eligibility |
| `ENTPAW-Report.ps1` | Privileged-access-from-non-PAW report — surfaces admin sign-ins from unmarked/non-compliant devices, plus coverage gaps (KQL against exported sign-in logs with a Graph fallback) |
| `ENTPAW-Set-CAState.ps1` | Safe change script (default `-WhatIf`, break-glass guard); flips the PAW device-filter policy between report-only and enabled for staged enforcement/rollback |
| `ENTPAW-DeviceTag.ps1` | Safe change script (default `-WhatIf`); sets the `extensionAttribute1 = PAW` marker on named pilot PAW devices so the Conditional Access device filter recognises them |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts (with embedded KQL) in a single ZIP.
- Delivered as a Complete Solution Package (PDF + Word + scripts).
- A repeatable process following the standard model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Administrators working from clean, isolated, hardened workstations — with privileged access
impossible from a general-purpose or compromised device, enforced by Conditional Access device
filters and granted just-in-time by PIM — proven on a pilot before you enforce.
