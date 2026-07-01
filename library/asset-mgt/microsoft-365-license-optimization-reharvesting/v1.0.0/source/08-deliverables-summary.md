# 8. Deliverables Summary — Microsoft 365 License Optimization & Reharvesting

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The Microsoft 365 licensing model, how usage is measured, the reclaim / de-dupe / right-size levers, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered admin center + Microsoft Graph steps (inventory, usage, classify, target, dry-run, reclaim, validate, expand, recurring) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `M365LIC-Discovery.ps1` | Read-only inventory of subscriptions (`subscribedSkus`) and per-user assignments via Graph; flags group-assigned seats. Writes `License Inventory – M365 – Discovery` |
| `M365LIC-Validation.ps1` | Read-only classification of seats into unused / duplicate / over-tier; applies the exclusion group. Writes `Reclaim Candidates – M365 – Validation` |
| `M365LIC-Report.ps1` | Read-only usage + savings report from Graph usage reports and sign-in data. Writes `Usage Activity – M365 – Discovery` and `Savings Report – M365 – Report` |
| `M365LIC-Remediation.ps1` | Safe reclamation (remove unused/duplicate license, right-size over-tier); `-WhatIf` by default, `-Execute` to apply; excludes protected accounts |
| `M365LIC-Set-ScopeTargeting.ps1` | Builds/populates the Entra groups (exclusions, pilot, broad) and tags the recurring savings campaign |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Microsoft 365 license spend cut to what is actually used — unused, duplicate, and over-tier seats
reclaimed safely, savings quantified in `Savings Report – M365 – Report`, and a recurring campaign
keeping the tenant right-sized.
