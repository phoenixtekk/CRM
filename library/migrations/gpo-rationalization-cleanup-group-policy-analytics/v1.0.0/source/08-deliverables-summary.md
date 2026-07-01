# 8. Deliverables Summary — GPO Rationalization & Cleanup with Group Policy Analytics

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | Why rationalize first, how Group Policy analytics scores readiness, the keep/retire/consolidate/replace workflow |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: export and inventory, analytics import, classify, resolve conflicts/redundant audit, document intent, sequenced backlog |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GPORAT-Discovery.ps1` | Exports every GPO to XML (`Get-GPO` / `Get-GPOReport`) and produces the inventory that seeds the rationalization register (read-only) |
| `GPORAT-Validation.ps1` | Reports rationalization coverage — confirms every GPO has a keep/retire/consolidate/replace disposition (read-only) |
| `GPORAT-Report.ps1` | Redundancy/conflict + readiness report: duplicated audit settings, conflicting values, and Group Policy analytics readiness via Graph (read-only) |
| `GPORAT-Remediation.ps1` | Safely unlinks/removes the dead and duplicate GPOs marked in the register (-WhatIf by default; -Apply to change) |
| `GPORAT-Set-MigrationBacklogTargeting.ps1` | Builds the sequenced migration backlog and the Entra pilot/broad scope groups |

## Named artifacts (reuse verbatim)
- `GPO Analytics Import – All GPOs – Assess`
- `Rationalization Register – All GPOs – Assess`
- `Conflict Resolution Log – Audit & Overlaps – Configure`
- `Migration Backlog – Sequenced – Configure`
- `Rationalization Scope – Devices – Pilot`
- `Rationalization Scope – Devices – Broad`

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess to Configure to Pilot to Validate to Expand.

## Outcome
A clean, rationalized GPO estate with a documented, sequenced migration backlog — the dead and
duplicate policies gone, conflicts and redundant audit resolved, and intent captured — so the Intune
migration is built on solid ground, proven on a pilot scope before you scale.
