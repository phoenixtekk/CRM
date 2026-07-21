# 8. Deliverables Summary — Remote Help — Government (GCC High) Edition

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | The availability-first business case; deploy-vs-alternative branches |
| 1. Solution Overview | The sovereign-cloud problem, the availability-first principle, what this adapts from commercial |
| 2. Requirements Guide | Every prerequisite — starting with the **availability gate** — Verify / Implement-if-missing, per tier |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | **STEP 1 = establish availability (gate)**, then Path A (deploy on GCC) or Path B (compliant alternative for GCC High / DoD) |
| GCC High Parity Notes | Availability finding, endpoint/feature parity table, and the compliant alternative for the gap |
| 5. Testing Guide | Pass/fail gates for both branches |
| 6. Troubleshooting Guide | Sovereign-specific issues and the alternative path |
| 7. Best Practices | Field-proven recommendations for the government context |

## PowerShell scripts (US Gov Graph aware — `-Environment USGov` / `USGovDoD`)
| Script | What it does |
|---|---|
| `RHELPG-Discovery.ps1` | Read-only: sovereign-cloud tenant/endpoint context, Remote Help presence, and Remote Help RBAC roles |
| `RHELPG-Validate.ps1` | PASS/FAIL: correct national-cloud endpoints, Remote Help deployed (if available for the tier), RBAC set |
| `RHELPG-Report.ps1` | Deployment + role status export to CSV |
| `RHELPG-Test-Endpoints.ps1` | Read-only: confirms the tenant resolves the US Gov national-cloud endpoints, not commercial |
| `RHELPG-Set-RoleScope.ps1` | The only state-changer: assigns a Remote Help RBAC role/scope in the sovereign tenant — **defaults to `-WhatIf`** |

## What the buyer receives
- This guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess (incl. availability gate) → Configure → Pilot → Validate → Expand.**

## Outcome
The correct, honest outcome for your government tier — Remote Help deployed on GCC, or a compliant
alternative where it isn't available on GCC High / DoD — governed, least-privilege, consent-based, and
audited, verified against current Microsoft documentation rather than assumed from commercial.
