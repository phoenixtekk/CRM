# 8. Deliverables Summary — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | What Entra ID Governance is: PIM, access reviews, entitlement management, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Entra steps (PIM onboarding, activation policy, reviews, catalog, access package) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IGA-Discovery.ps1` | Reports PIM role eligibility/assignments, access reviews, and entitlement-management packages, and flags break-glass exclusion |
| `IGA-Validation.ps1` | Confirms roles are eligible (not standing), activation policy is gated, and break-glass is excluded |
| `IGA-Report.ps1` | Standing-privilege vs eligible summary and governance-coverage report (Microsoft Graph) |
| `IGA-Remediation.ps1` | Safe remediation (default `-WhatIf`); converts standing admin assignments to eligible |
| `IGA-Set-ScopeTargeting.ps1` | Builds the governance-scope and approver groups used by PIM, reviews, and access packages |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the repeatable model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Privileged access made just-in-time and approval-gated, access recertified on a schedule, and
entitlements packaged with expiry — least privilege that is time-bound and provable — proven on a
pilot before you scale.
