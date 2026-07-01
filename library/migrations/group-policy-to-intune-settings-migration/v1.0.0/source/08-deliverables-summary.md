# 8. Deliverables Summary — Group Policy to Intune Settings Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How GPO and Intune policy differ, Group Policy analytics, settings catalog + imported ADMX, coexistence/precedence, ringed cutover, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, plus the naming convention |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: export GPOs, analytics, settings catalog, imported ADMX, handle unsupported, coexistence, ringed cutover |
| 5. Testing Guide | Parity validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `GPOM-Discovery.ps1` | Exports/inventories every GPO via the GroupPolicy module (`Get-GPO` / `Get-GPOReport` to XML); flags settings still owned by a live GPO. Read-only. |
| `GPOM-Validation.ps1` | Settings parity — compares source GPO settings against the applied Intune policy and reports `MDMWinsOverGP`. Read-only. |
| `GPOM-Report.ps1` | Migration coverage + gap report (supported vs unsupported, what was migrated, what remains). Read-only. |
| `GPOM-Remediation.ps1` | Safe conflict remediation (`-WhatIf` by default) — resolves conflicting policy / sets MDM-wins precedence. |
| `GPOM-Set-MigrationRingTargeting.ps1` | Builds the migration ring groups (pilot/broad) via Microsoft Graph and seeds membership. |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
A Group Policy estate translated into Intune — supported settings preserved, unsupported settings
handled by design, coexistence managed, and a parity-checked ringed cutover that follows devices on
or off the corporate network.
