# 8. Deliverables Summary — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The migration model (inventory SCCM/GPO delivery → rebuild in Intune → coexist → retire legacy) and how to avoid double-deployment conflicts |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory, rebuild client + VPN profile + certificate in Intune, coexistence, pilot, validate parity, wave cutover, retire SCCM package + unlink GPO |
| 5. Testing Guide | Per-wave parity + no-conflict + legacy-gone gates |
| 6. Troubleshooting Guide | Field issues and remediation (double-managed device, profile conflict, reinstall loops, leftover GPO) |
| 7. Best Practices | Wave-based cutover and rollback recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CVPNMIG-Discovery.ps1` | Current-state discovery: detects the SCCM/GPO-delivered Cisco VPN client + profile + cert on a device and the Intune-side apps/profiles (Graph + local). Read-only |
| `CVPNMIG-Validation.ps1` | Confirms the Intune-delivered client + VPN profile + certificate are present and the tunnel connects on this device. Read-only |
| `CVPNMIG-Report.ps1` | Fleet migration-progress / coexistence report — legacy vs Intune-managed (Microsoft Graph). Read-only |
| `CVPNMIG-Remediation.ps1` | Safely cleans up legacy artifacts / fixes conflicts; default `-WhatIf` |
| `CVPNMIG-Set-ScopeTargeting.ps1` | Creates/populates the migration-wave Entra group(s) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand → Retire legacy.**

## Outcome
The Cisco Secure Client and its VPN profile and certificate delivered from Intune instead of SCCM/GPO —
rebuilt with parity, validated wave by wave with the legacy path live for coexistence, and one delivery
authority per device throughout — so the VPN never drops during the move and the SCCM package and GPOs
are retired only once Intune is proven.
