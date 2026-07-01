# 8. Deliverables Summary — Workspace ONE to Intune: macOS Device Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The macOS migration model, why ABM reassignment + re-enrollment + parity rebuild, the three config surfaces, limitations |
| 2. Requirements Guide | Every macOS-specific prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: connect ABM to Intune, enrollment profile, ring groups, parity rebuild, reassign + re-enroll, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1MAC-Discovery.ps1` | Migration-readiness: APNs certificate, ADE/enrollment token + synced Macs, enrolled macOS count/version spread, existing macOS config policies (read-only, Graph) |
| `WS1MAC-Validation.ps1` | Per-device enrollment + parity check: managed by Intune, settings-catalog/custom/shell objects applied (read-only, Graph) |
| `WS1MAC-Report.ps1` | Fleet/ring migration status + per-object parity (succeeded vs drift) with optional CSV (read-only, Graph) |
| `WS1MAC-Remediation.ps1` | Safe remediation of stuck enrollments/drift — issues a device sync so parity objects re-apply (defaults to -WhatIf) |
| `WS1MAC-Set-MigrationRingTargeting.ps1` | Builds/populates the migration ring groups (`WS1MAC Migration - Pilot Ring` / `... - Production Ring`) from a device list (defaults to -WhatIf) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess to Configure to Pilot to Validate to Expand.

## Outcome
Macs moved from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled, and
rebuilt to full macOS profile and shell-script parity — proven on a pilot ring before you scale.
