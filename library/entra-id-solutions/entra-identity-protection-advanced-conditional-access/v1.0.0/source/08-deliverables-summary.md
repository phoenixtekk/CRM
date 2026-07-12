# 8. Deliverables Summary — Entra Identity Protection & Advanced Conditional Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | What Identity Protection + advanced Conditional Access are; how risk, contexts, token protection, CAE, and strengths work; benefits and limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing (P2 flagged to verify) |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Entra steps — report-only first, staged enforcement, break-glass excluded |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (and KQL)
| Script | What it does |
|---|---|
| `ENTIDP-Discovery.ps1` | Read-only inventory of Conditional Access policies, Identity Protection availability, named locations, authentication strengths, and authentication contexts (Microsoft Graph) |
| `ENTIDP-Validate.ps1` | Confirms the four pilot policies exist, are report-only, target the pilot scope, and exclude break-glass; checks CAE/token-protection prerequisites |
| `ENTIDP-Report.ps1` | Risk-and-coverage report — risky users/sign-ins summary, risk-policy coverage, legacy-auth and registration gaps (Microsoft Graph) |
| `ENTIDP-Set-PolicyState.ps1` | Safe change script (default `-WhatIf`); flips a named Conditional Access policy between report-only and enabled for staged enforcement/rollback; never touches break-glass exclusions |
| `ENTIDP-RiskHunt.ps1` | Risk hunting via KQL against exported sign-in/risk logs (Log Analytics / Sentinel) with a Graph-based fallback when no workspace is available |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts (with embedded KQL) in a single ZIP.
- Delivered as a Complete Solution Package (PDF + Word + scripts).
- A repeatable process following the standard model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
An adaptive identity perimeter that reacts to risk in real time — risk-based challenges, step-up on
sensitive actions, token protection, and CAE layered over your Conditional Access baseline — proven
on a pilot in report-only before you enforce.
