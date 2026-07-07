# 8. Deliverables Summary — Microsoft Teams Apps & Integration Governance

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The app-governance model: permission + setup policies, org-wide allow/block + pinning, custom/LOB vs third-party, consent/permission review, and vetting; limitations and the naming convention |
| 2. Requirements Guide | App-governance-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Teams) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered admin center + MicrosoftTeams PowerShell + Graph steps (read posture, review consent, triage, org-wide settings, build policies, assign to pilot, validate, expand, rollback, recurring review) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `TEAMSAPPS-Discovery.ps1` | Read-only inventory of app permission/setup policies, the full Teams app catalog with each app's distribution method (`store`/`organization`/`sideloaded`), and per-team installed apps; risk-flags sideloaded/LOB apps. MicrosoftTeams + Graph |
| `TEAMSAPPS-Configure.ps1` | Creates/updates app permission and app setup policies from a definition (vetted allow list, pinned apps); **`-WhatIf` by default**, `-Commit` to apply. Uses `New-/Set-CsTeamsAppPermissionPolicy` and `New-/Set-CsTeamsAppSetupPolicy` |
| `TEAMSAPPS-Validation.ps1` | Read-only check that a user population is assigned the intended permission/setup policies and that those policies allow only the vetted set |
| `TEAMSAPPS-ConsentReport.ps1` | Read-only consent/permission review: each app's service principal with its delegated (`oauth2PermissionGrants`) and application (`appRoleAssignments`) Graph permissions, risk-flagged. Writes `Consent Review – Teams Apps – Report` |
| `TEAMSAPPS-Set-ScopeTargeting.ps1` | Scope/health helper: assigns (or resets to Global) the permission + setup policies for a pilot group/users via `Grant-Cs*`; **`-WhatIf` by default**, `-Commit` to apply |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP (read-only or `-WhatIf` by default; no credentials in code).
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
Only trusted, useful apps run in Microsoft Teams — app permission and setup policies set, risky apps
blocked org-wide, custom/LOB uploads governed, consented Graph permissions reviewed in
`Consent Review – Teams Apps – Report`, and new apps vetted through
`App Vetting Register – Apps – AllStages` — with the collaboration supply chain governed on a recurring
review.
