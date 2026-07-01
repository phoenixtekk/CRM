# 8. Deliverables Summary — Workspace ONE to Intune iOS/iPadOS Device Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The Apple migration model, ABM re-assignment, wipe-and-re-enroll reality, parity, ringed cutover |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: connect ABM to Intune, build enrollment profiles, re-assign in ABM, re-enroll by ring, parity, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1IOS-Discovery.ps1` | Tenant readiness: APNs cert, ADE token, VPP token, parity profiles/compliance, ring groups (read-only) |
| `WS1IOS-Validation.ps1` | Per-device check: supervised, ADE-enrolled, ring membership, compliance, profiles applied (read-only) |
| `WS1IOS-Report.ps1` | Fleet migration status and app-parity report via Microsoft Graph (read-only) |
| `WS1IOS-Remediation.ps1` | Safe remediation for stuck enrollments (sync managed devices); default `-WhatIf` |
| `WS1IOS-Set-MigrationRingTargeting.ps1` | Builds the pilot/broad migration ring groups; default `-WhatIf` |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: **Assess to Configure to Pilot to Validate to Expand.**

## Outcome
iPhones and iPads moved from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled supervised
with app and profile parity, and cut over by ring with clear user comms — proven on a pilot before the fleet.
