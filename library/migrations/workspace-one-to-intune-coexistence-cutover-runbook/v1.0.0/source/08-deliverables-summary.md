# 8. Deliverables Summary — Workspace ONE to Intune Coexistence & Cutover Runbook

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The coexistence model, the risks (double management, Conditional Access, app conflicts), the cutover sequence, go/no-go gates, and rollback — and *why* |
| 2. Requirements Guide | Every coexistence/cutover prerequisite with Verify / Implement-if-missing |
| Global Requirements (Migrations) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: guardrails, cohorts, per-cohort cutover sequence, validate, rollback, expand |
| 5. Testing Guide | The `Go/No-Go Checklist – Cohort – Validate` with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for the assign-once, repeat-everywhere model |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WS1COEX-Discovery.ps1` | Read-only. Inventories target managed devices, flags dual-managed devices, and snapshots Conditional Access policies and cohort groups |
| `WS1COEX-Validation.ps1` | Read-only. Per-device cutover-readiness gate: enrollment channel, Conditional Access scope, double-targeting, reachability |
| `WS1COEX-Report.ps1` | Read-only. Coexistence/cutover status report: Workspace ONE-only / Intune-only / dual-managed / compliant per device |
| `WS1COEX-Remediation.ps1` | Safe remediation and rollback helper (default `-WhatIf`); removes a cohort from cohort-scoped Conditional Access and Intune assignments to revert a cutover |
| `WS1COEX-Set-CohortTargeting.ps1` | Builds a cohort Entra security group and sets its membership (default `-WhatIf`) |

## Named artifacts (reuse verbatim)
| Artifact | Scope · Stage |
|---|---|
| `Coexistence Guardrails – Tenant – Configure` | One compliance authority, scoped Conditional Access, no-double-targeting |
| `Cohort Cutover Order – Fleet – Pilot` | The risk-ordered cohort sequence |
| `Go/No-Go Checklist – Cohort – Validate` | The per-cohort gate (Testing Guide) |
| `Cutover Sequence – Cohort – Validate` | The ordered per-cohort cutover steps |
| `Rollback Plan – Cohort – Validate` | The tested per-cohort rollback |

## What the buyer receives
- This runbook as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP (read-only discovery/validation/report; `-WhatIf`-default remediation and cohort builder).
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand**, with a per-cohort go/no-go gate and a tested rollback.

## Outcome
A controlled transition while both MDMs run in parallel — guardrails against double management,
go/no-go gates, a per-cohort cutover sequence, and a tested rollback — proven on a pilot cohort before
you scale.
