# 8. Deliverables Summary — Data-Owner & Steward Framework (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The accountability operating model — roles (Data Owner, Data Steward, Governance Domain Owner, Custodian), the RACI, the review cadence, least-privilege, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell + Graph steps (assess coverage, design RACI, apply assignments pilot-first, establish cadence, validate, expand), each control/asset named, pass/fail gates + rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DGSTEWARD-Assess-Ownership.ps1` | Read-only ownership/coverage discovery: inventories in-scope Purview controls — sensitivity labels, DLP policies, retention policies via S&C PowerShell, and (via Graph, where available) governance domains — and reports for each whether an owner/steward is recorded. Writes `Data Ownership Inventory – Steward – Assess` |
| `DGSTEWARD-Set-Stewardship.ps1` | Stewardship-assignment helper: from a matrix CSV, adds named members to built-in role groups and writes owner/steward + review-date tags to control metadata; **`-WhatIf` by default**, `-Commit` to apply; prints the reverse command for each change. Writes `Stewardship Assignments – Configure` |
| `DGSTEWARD-Test-Framework.ps1` | Read-only validation: confirms every in-scope control/asset has a recorded Data Owner and Data Steward, that named parties resolve, and that separation-of-duties holds; reports any gap |
| `DGSTEWARD-Report-Accountability.ps1` | Read-only accountability/coverage report: coverage percentage, gap list, and identity resolution of every named owner/steward against Graph. Writes `Accountability Coverage – Report` |
| `DGSTEWARD-Check-Cadence.ps1` | Read-only review-cadence health helper: computes each control/asset's last-reviewed / review-by dates and flags due and overdue items against the agreed interval. Writes `Review Cadence – Health` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything. No credentials or secrets are stored in code; every script uses interactive
modern-auth (`Connect-IPPSSession` / `Connect-MgGraph`). Scripts do not invent cmdlets or Data Governance
API versions — where the Unified Catalog data-plane API is not confirmed available in your tenant, the
governance-domain steps are flagged for portal action rather than assumed.

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
A Microsoft Purview data-owner/steward operating framework in place — every in-scope data asset and
governance control assigned a named **Data Owner** and **Data Steward**, responsibility recorded in a
well-formed **RACI** (one Accountable party per activity), and the whole thing on a **review cadence** so
accountability stays current — configured, piloted on a bounded domain, validated against pass/fail gates,
and defensible. Regulatory, records, and legal determinations remain with the organization's compliance,
records, privacy, and legal functions; this framework operates them with accountability, it does not make
them.
