# 8. Deliverables Summary — CASB & Cloud App Control with Netskope

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What CASB is, inline vs API, discovery and risk scoring, control levers, govern-without-blocking |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: discover, decide, inline + API controls, pilot, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSCASB-Discovery.ps1` | Read-only. Enumerates Entra enterprise applications as a cloud-app inventory signal and confirms Graph + group readiness; Netskope REST inventory flagged/deferred |
| `NSCASB-Validation.ps1` | Read-only. Confirms steering/inspection readiness signals and that the named CASB policies are scoped to the pilot group |
| `NSCASB-Report.ps1` | Read-only. Produces the cloud-app usage and risk report (sanctioned vs shadow IT, risk score, coverage gaps) |
| `NSCASB-Remediation.ps1` | Safe remediation of policy gaps; defaults to `-WhatIf`, applies only with `-Execute` |
| `NSCASB-Set-ScopeTargeting.ps1` | Builds/maintains the CASB scope groups (pilot and broad) in Entra ID |

## Named artifacts (reused verbatim across the package)
- app risk register — All cloud apps – Discovery stage
- Sanctioned apps policy – In-scope apps – Configure
- Unsanctioned apps policy – Shadow IT – Configure
- activity controls — Inline – Configure profile
- API connections — Sanctioned apps – Configure
- `CASB Pilot – Pilot users – Pilot` and `CASB Broad – All users – Expand`

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Every cloud app visible and governed — shadow IT discovered and risk-scored, with inline and API
controls that protect data without blocking the business — proven on a pilot before you scale.
