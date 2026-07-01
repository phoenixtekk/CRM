# 8. Deliverables Summary — SaaS Application Discovery & License Right-Sizing

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | SaaS sprawl, discovery via Entra ID sign-ins/telemetry, right-sizing levers, the named artifacts, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: discover, map owners/spend, build the register, flag reclaims, validate, expand, recur |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SAASLIC-Discovery.ps1` | Read-only. Lists Entra ID enterprise (SaaS) apps with per-app sign-in activity (Microsoft Graph) |
| `SAASLIC-Validation.ps1` | Read-only. Confirms Graph connectivity and the read scopes/telemetry needed to run the solution |
| `SAASLIC-Report.ps1` | Read-only. Per-app entitled-seats vs active-users, wasted seats, and estimated savings (Microsoft Graph) |
| `SAASLIC-Remediation.ps1` | Default `-WhatIf`. Flags dormant-seat reclaim candidates; writes a candidate file, changes nothing by default |
| `SAASLIC-Set-ScopeTargeting.ps1` | Builds/refreshes the `Review Scope – SaaS` Entra ID group that bounds each review pass |

## Named artifacts produced
- `App Inventory – SaaS – Discovered`
- `Owner Map – SaaS – Mapped`
- `Right-Sizing Register – SaaS – Pilot` / `Right-Sizing Register – SaaS – Expanded`
- `Review Cadence – SaaS – Recurring`
- `Review Scope – SaaS – Pilot` / `Review Scope – SaaS – Expanded`

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand.

## Outcome
SaaS spend under control — apps discovered, unused and duplicate seats reclaimed, overlapping tools
consolidated — with a recurring review to keep it that way, proven on a pilot before you scale.
