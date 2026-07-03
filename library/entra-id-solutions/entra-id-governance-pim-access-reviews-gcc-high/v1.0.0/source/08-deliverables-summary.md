# 8. Deliverables Summary — Entra ID Governance (PIM, Access Reviews & Entitlement Management) — Government (GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box (GCC High edition) |
| 1. Solution Overview | What Entra ID Governance is on GCC High: PIM, access reviews, entitlement management, benefits, limitations, and a *Commercial vs GCC High — what's different* section |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, including the sovereign endpoint table and Government licensing SKUs |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps in the US Gov Entra admin center (`entra.microsoft.us`) with GCC-High caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a sovereign-connectivity test |
| 6. Troubleshooting Guide | Field issues and remediation, with GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations, sovereign-aware |
| GCC High Parity Notes | Cited Commercial-vs-GCC-High feature parity reference |

## PowerShell scripts (US Gov Graph, `-Environment USGov`)
| Script | What it does |
|---|---|
| `IGAG-Discovery.ps1` | Reports PIM role eligibility/assignments, access reviews, and entitlement-management packages, and flags break-glass exclusion (read-only) |
| `IGAG-Validation.ps1` | Confirms roles are eligible (not standing), activation policy is gated, and break-glass is excluded (read-only) |
| `IGAG-Report.ps1` | Standing-privilege vs eligible summary and governance-coverage report (read-only) |
| `IGAG-Remediation.ps1` | Safe remediation (default `-WhatIf`); converts standing admin assignments to eligible |
| `IGAG-Set-ScopeTargeting.ps1` | Builds the governance-scope and approver groups used by PIM, reviews, and access packages |

All scripts connect to the US Government Graph endpoint with `-Environment USGov` (use `USGovDoD` on
the DoD cloud). Discovery, Validation, and Report are read-only; Remediation and Set-ScopeTargeting
change state (Remediation defaults to `-WhatIf`).

## What the buyer receives
- This implementation guide as a Word document and PDF (white-label).
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the repeatable model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Privileged access made just-in-time and approval-gated, access recertified on a schedule, and
entitlements packaged with expiry — least privilege that is time-bound and provable — configured
correctly on the **US sovereign cloud** and proven on a pilot before you scale.
