# 8. Deliverables Summary — Software Discovery & Entitlement Reconciliation

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What discovery/reconciliation is, the named artifacts, the pipeline, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Asset Mgt) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: discover, normalize, import entitlements, reconcile, route exceptions, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SWDISC-Discovery.ps1` | Reads installed software from Intune detected apps (Graph) and Configuration Manager (Get-CM / WMI), or ingests a Flexera export, into the discovery inventory. Read-only |
| `SWDISC-Validation.ps1` | Confirms every raw row resolves through the normalization map to a SKU and that the entitlement register shares the SKU vocabulary. Read-only |
| `SWDISC-Report.ps1` | Builds the reconciliation ledger (installed vs entitled per SKU) and the exception register. Read-only |
| `SWDISC-Remediation.ps1` | Applies queued normalization-map fixes for unmatched titles; defaults to -WhatIf |
| `SWDISC-Set-ScopeTargeting.ps1` | Creates/confirms the pilot discovery-scope group (one source / one product family) |

## The named artifacts
| Artifact | Stage |
|---|---|
| `Installed-Software Inventory – All Sources – Discovery` | Discovery |
| `Normalization Map – SKU Vocabulary – Configure` | Configure |
| `Entitlement Register – Systems of Record – Configure` | Configure |
| `Reconciliation Ledger – SKU vs Entitlement – Validate` | Validate |
| `Exception Register – Unmatched & Edge Cases – Validate` | Validate |
| `Discovery Scope Group – Pilot Source – Pilot` | Pilot |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Raw software discovery turned into a clean, reconciled license position — normalized, mapped to
entitlements, exceptions flagged — proven on a pilot before you scale.
