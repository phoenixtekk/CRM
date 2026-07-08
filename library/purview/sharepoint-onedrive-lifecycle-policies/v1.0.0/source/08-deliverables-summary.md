# 8. Deliverables Summary — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | SharePoint + OneDrive retention/cleanup policies aligned to the schedule; retain-only first, deletion enabled deliberately; how location policies differ from item labels (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: assess policies, design the schedule, create the policy retain-only on the pilot, pilot + observe the hold library, validate, enable deletion deliberately, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Named artifacts
| Artifact | Name |
|---|---|
| Retention policy | `SPO-OneDrive Retention – Policy` |
| Retain-only rule | `SPO-OneDrive – Retain-Only Rule` |
| Retain-then-delete rule | `SPO-OneDrive – Retain-Then-Delete Rule` |
| Pilot scope | `SPO Lifecycle – Pilot Scope – Stage1` |
| Schedule/design map | `Lifecycle Schedule – Map` |
| Coverage report | `Lifecycle – Coverage Report` |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLCSPO-Discover.ps1` | Reports current state: every retention policy and rule, whether each covers SharePoint/OneDrive, its period and action, and any adaptive scopes — Security & Compliance PowerShell; read-only |
| `DLCSPO-Check-Prereqs.ps1` | Prerequisite/health helper: module, connection, the records/retention role and adaptive-scope signals, and existing policies — PASS/GAP per signal; read-only |
| `DLCSPO-Set-RetentionPolicy.ps1` | Configuration/Remediation: creates `SPO-OneDrive Retention – Policy` and its **retain-only** rule scoped to the pilot (`-Action CreatePolicy`), and — as a deliberate, separate step — switches the rule to **retain-then-delete** (`-Action EnableDelete`); **defaults to `-WhatIf`** (prints the plan + reverse action), applies only with `-Commit`; no secrets in code |
| `DLCSPO-Validate.ps1` | Validation: PASS/FAIL that the policy exists, covers the intended locations, the period matches design, and **no unintended delete action** is enabled — read-only |
| `DLCSPO-Report.ps1` | Coverage report — each policy/rule, its SharePoint/OneDrive locations, period, and action — written to CSV as `Lifecycle – Coverage Report`; read-only |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable method following the model: Assess → Design → Configure → Pilot → Validate → Expand.

## Outcome
SharePoint and OneDrive on a lifecycle from Purview — in-scope content retained for the schedule and
cleaned up when it ages out — proven on a limited pilot in retain-only mode before any deletion is enabled,
with the schedule and the keep/delete determination left to the records, compliance, and legal owners who
make it.
