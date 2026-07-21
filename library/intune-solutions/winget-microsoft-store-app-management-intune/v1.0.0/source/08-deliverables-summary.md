# 8. Deliverables Summary — Winget & Microsoft Store App Management with Microsoft Intune

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Microsoft Store (new, winget-backed) apps, winget for the long tail, Required vs. Available self-service, updates, and the choose-the-lane guidance (vs. Enterprise App Catalog and custom Win32) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, including winget prerequisites and Company Portal |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps: add a Store app + assign, add a winget app, Required vs. Available + uninstall behavior, updates, pilot ring, expand |
| 5. Testing Guide | Validation procedures with PASS/FAIL gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WINGETSTORE-Discovery.ps1` | Read-only inventory of Store/winget apps deployed, their assignments, and self-service availability (Microsoft Graph) |
| `WINGETSTORE-Validate.ps1` | PASS/FAIL check that the pilot Store app + winget app are deployed, assigned, and self-service is configured (read-only) |
| `WINGETSTORE-Report.ps1` | Install/update status export to CSV across the fleet (read-only) |
| `WINGETSTORE-Test-Install.ps1` | Read-only confirmation of a pilot install and its detection on-device |
| `WINGETSTORE-Set-Assignment.ps1` | The only state-changer: assigns a Store/winget app Required-or-Available to a pilot group; **defaults to `-WhatIf`** |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Mainstream Windows apps — Microsoft Store (winget-backed) apps and winget packages — that deploy and
stay current through Intune, with Required baseline installs, Company Portal self-service for the long
tail, and a pilot-first rollout so a bad assignment never reaches production.
