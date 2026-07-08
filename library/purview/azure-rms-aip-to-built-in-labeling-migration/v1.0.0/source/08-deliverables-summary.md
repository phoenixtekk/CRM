# 8. Deliverables Summary — Azure RMS / AIP → Built-in Unified Labeling Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The AIP add-in retirement, the migration to built-in unified labeling with policy parity, legacy Azure RMS / departmental-template mapping, the parity dimensions, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell + AIPService + Graph + client-policy steps (inventory, parity map, apply label-policy settings pilot-first, confirm labels/protection, cut the ring over, validate, expand + decommission) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IPRMSMIG-Assess-Migration.ps1` | Read-only estate inventory: sensitivity-labeling SKUs (Graph), all sensitivity labels + whether each encrypts (`Get-Label`), all label policies + key advanced settings (`Get-LabelPolicy`), Azure RMS templates and `FunctionalState` (`Get-AipServiceTemplate`). Writes `AIP/RMS Inventory – Migration – Assess` |
| `IPRMSMIG-Set-LabelPolicy.ps1` | Label-policy advanced-settings helper for behavioural parity: applies the settings from a JSON file to a named label policy via `Set-LabelPolicy -AdvancedSettings`; **`-WhatIf` by default**, `-Commit` to apply; prints the prior value for each key. Writes `Label Policy Config – Configure` |
| `IPRMSMIG-Test-Parity.ps1` | Read-only parity check: resolves the effective label set for a pilot user, flags labels missing from the unified store, and flags parity features that need a newer Office build than the one supplied |
| `IPRMSMIG-Report-Migration.ps1` | Read-only migration/parity report: builds the parity matrix (labels, add-in features, RMS templates → built-in target, with a pass/fail per row) and exports it. Writes `Migration Validation – Report` |
| `IPRMSMIG-Scope-Health.ps1` | Read-only scope/health helper: reports Azure RMS activation (`Get-AipServiceConfiguration`), super-user recovery posture, pilot-scope readiness, and toolchain connectivity; with `-Commit` triggers `Execute-AzureADLabelSync`. Writes `Migration Scope – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything. No credentials or secrets are stored in code; every script uses interactive
modern-auth (`Connect-IPPSSession` / `Connect-AipService` / `Connect-MgGraph`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
Your labeling estate moved off the retiring AIP add-in and off legacy Azure RMS departmental templates
onto **built-in unified labeling** in Microsoft Purview — **with parity**: the same labels, the same
encryption and custom permissions, the same Outlook and mandatory-labeling behaviour, and previously
protected content still opening — piloted on a ring, validated against pass/fail gates, then expanded
tenant-wide with the add-in decommissioned. The capability is in place, defensible, and evidenced.
