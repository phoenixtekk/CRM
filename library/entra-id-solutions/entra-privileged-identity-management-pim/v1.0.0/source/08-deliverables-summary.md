# 8. Deliverables Summary — Entra Privileged Identity Management (PIM)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The PIM model — eligible vs. active, activation policy, Entra vs. Azure resource roles, access reviews, break-glass |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (including Entra ID P2) |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (break-glass, discover, activation policy, eligible assignments, remove standing, validate, access reviews, Azure roles, expand + alerts) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations + where to go next |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ENTPIM-Discovery.ps1` | Inventories standing (active) privileged role assignments for Entra roles and, optionally, Azure resource roles — account, role, scope, permanent-or-not (read-only) |
| `ENTPIM-Validate.ps1` | Confirms each onboarded role's activation policy (MFA, justification, approval + approvers, max duration) matches the tiering (read-only) |
| `ENTPIM-Report.ps1` | Activation/audit and access-review report — who activated what, when, with what justification and approval; access-review status (read-only) |
| `ENTPIM-Set-EligibleAssignments.ps1` | Safely removes standing (active) assignments once an eligible assignment exists; `-WhatIf` by default; always excludes break-glass accounts |
| `ENTPIM-Alerting.ps1` | Checks break-glass protection (permanent, not PIM-eligible, excluded, alerted) and reports PIM alert state (read-only) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Zero standing privilege — privileged roles eligible-not-active, every admin action activated
just-in-time with MFA, justification, and approval, time-bound and fully audited, reviewed on a
schedule, and protected end-to-end by break-glass accounts — proven on a pilot before you scale.
