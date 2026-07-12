# 8. Deliverables Summary — Entra External Identities (B2B) & Cross-Tenant Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, outcome, scope boundary, and what is in the box |
| 1. Solution Overview | What External Identities is: cross-tenant access settings, guest onboarding, guest governance, benefits, limitations, and how it plugs into `ENTIGA` / `ENTZTCA` (gap-only) |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing, including licensing/preview items flagged *verify* |
| Global Requirements (Entra ID Solutions) | Category-wide prerequisites (tenant, base licensing, admin roles, break-glass, network), published once |
| 3. Implementation Guide | Exact, ordered steps in the Entra admin center — conservative defaults, one trusted partner, governed access package, report-only guest CA policy, and a guest access review — with every object named |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Symptom -> cause -> fix for the common failures |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Microsoft Graph)
| Script | What it does |
|---|---|
| `ENTB2B-Discovery.ps1` | Reports default and organizational cross-tenant access settings, guest count, guest-scoped Conditional Access policies, and access packages/reviews (read-only) |
| `ENTB2B-Validate.ps1` | Confirms defaults are conservative, the pilot partner is trusted deliberately, the guest CA policy exists and excludes break-glass, and the access package/review are in place (read-only) |
| `ENTB2B-Report.ps1` | Guest-lifecycle report — guests by last sign-in, never-signed-in, and inactive; flags stale/no-sponsor candidates (read-only) |
| `ENTB2B-Set-CrossTenantAccess.ps1` | Safely creates/adjusts the organizational cross-tenant access configuration and trust settings for a named partner (default `-WhatIf`) |
| `ENTB2B-CleanupStaleGuests.ps1` | Safely disables (then, on a later pass, removes) stale guest accounts; never touches break-glass/internal accounts (default `-WhatIf`) |

All scripts connect to Microsoft Graph (`graph.microsoft.com`). Discovery, Validate, and Report are
read-only; Set-CrossTenantAccess and CleanupStaleGuests change state and default to a safe `-WhatIf`
preview.

## What the buyer receives
Delivered as a **Complete Solution Package (PDF + Word + scripts)**:
- This implementation guide as a Word document and PDF (white-label).
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
External access that is deliberate, scoped, and time-bound — partners trusted through named
cross-tenant settings, guests onboarded through packaged access with MFA and expiry, and stale guests
removed on review — proven on a pilot before you scale.
