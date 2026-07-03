# 8. Deliverables Summary — Conditional Access Integration (Government / GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (Government edition) |
| 1. Solution Overview | What Conditional Access is, how it integrates with Intune, **Commercial vs GCC High — what's different**, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, on the `*.us` sovereign endpoints |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps on the GCC High portals — Report-only first, break-glass safety, parity caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a sovereign-cloud check |
| 6. Troubleshooting Guide | Field issues, lockout recovery, and GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for the sovereign cloud |
| GCC High Parity Notes | Cited reference of Commercial-vs-GCC-High capability gaps |

## PowerShell scripts (all connect to US Gov Graph — `-Environment USGov`)
| Script | What it does |
|---|---|
| `CAIG-Discovery.ps1` | Confirms the US Gov Graph environment, local device Entra join/PRT state, and current CA policy inventory |
| `CAIG-Validation.ps1` | Confirms the device satisfies device-based controls **and** verifies break-glass accounts are excluded from every policy |
| `CAIG-Report.ps1` | Lists CA policies + state and summarizes recent sign-in CA results (read-only, US Gov Graph) |
| `CAIG-Remediation.ps1` | Safe fixes — ensures break-glass exclusions and reverts a runaway policy to Report-only; **defaults to `-WhatIf`** |
| `CAIG-Set-ScopeTargeting.ps1` | Builds pilot→production scope (include/exclude groups) on a policy; **defaults to `-WhatIf`** |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP, all targeting **`graph.microsoft.us`**.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Zero Trust access enforcement deployed **correctly on GCC High** — right portals, right endpoints,
parity gaps handled — with only healthy, authenticated devices and users getting in, proven on a
pilot before scale, with break-glass accounts and Report-only piloting preventing lockouts.
