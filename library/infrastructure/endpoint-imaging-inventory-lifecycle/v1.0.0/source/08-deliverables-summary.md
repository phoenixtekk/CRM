# 8. Deliverables Summary — Endpoint Imaging, Inventory & Hardware Lifecycle Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The lifecycle model, the Autopilot-vs-imaging decision, inventory as source of truth, the procure/deploy/refresh/retire flow with secure wipe |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps for provisioning, inventory, lifecycle stages, and secure retirement |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IMGLIFE-Discovery.ps1` | Reports current provisioning state: Autopilot registration, Intune enrollment, hardware inventory, and any ConfigMgr client (read-only) |
| `IMGLIFE-Validation.ps1` | Confirms a device is provisioned, registered (Autopilot), enrolled, and reporting hardware (read-only) |
| `IMGLIFE-Report.ps1` | Lifecycle and asset-reconciliation report across managed devices and the Autopilot registered-devices list (Microsoft Graph, read-only) |
| `IMGLIFE-Remediation.ps1` | Safe retire/wipe helper; previews by default (WhatIf), triggers the chosen end-of-life action only when explicitly applied |
| `IMGLIFE-Set-LifecycleStageTargeting.ps1` | Creates the lifecycle-stage Entra ID groups (idempotent) and optionally stages members |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: Assess → Configure → Pilot → Validate → Expand.

## Outcome
Every device accounted for across its whole life — provisioned by a defined method, inventoried
accurately, refreshed on criteria, and retired with a secure wipe.
