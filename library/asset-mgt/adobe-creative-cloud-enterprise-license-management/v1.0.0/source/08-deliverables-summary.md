# 8. Deliverables Summary — Adobe Creative Cloud for Enterprise License Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The Creative Cloud for Enterprise licensing model (named-user, product profiles, identity types), assignment, right-sizing, reclamation, benefits, limitations |
| 2. Requirements Guide | Every Adobe-specific prerequisite with Verify and Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: confirm identity and profiles, inventory, classify, reclaim and reassign, recurring review, expand |
| 5. Testing Guide | Validation procedures with pass and fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts (reused across the documents)
| Artifact | Scope and stage |
|---|---|
| `Product-Profile Map – All Adobe Products – Configure` | Which profile grants which product, seat quota, per-seat cost |
| `Seat Inventory – Pilot Scope – Assess` | Named users assigned through each profile |
| `Right-Sizing Register – Pilot Scope – Validate` | Per-user keep, downsize, or reclaim decision with evidence and owner |
| `Reclaim-Review Group – Pilot Scope – Validate` | Candidates routed to confirmation owners |
| `Review Cadence – Adobe Estate – Expand` | Schedule, owner, idle threshold, refresh artifacts |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ADOBELIC-Discovery.ps1` | Reads users and product assignments via the Adobe User Management API where available, else an Admin Console CSV export (read-only) |
| `ADOBELIC-Validation.ps1` | Classifies seats active, idle, or over-provisioned against an activity signal (read-only) |
| `ADOBELIC-Report.ps1` | Seat-and-cost summary: assigned versus active per profile and idle/over-provisioned cost (read-only) |
| `ADOBELIC-Remediation.ps1` | Safe remediation that flags reclaim and downsize candidates; defaults to -WhatIf and makes no change without explicit confirmation |
| `ADOBELIC-Set-ScopeTargeting.ps1` | Builds the reclaim-review group from the right-sizing register |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the standard model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Adobe Creative Cloud for Enterprise spend matched to real need — clean seat assignment, unused seats
reclaimed, over-provisioned seats downsized, and a recurring review — proven on a pilot before you scale.
