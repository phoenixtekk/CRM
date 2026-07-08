# 8. Deliverables Summary — Classification Reporting & Analytics (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the reporting delivers (coverage via Content Explorer, activity/trend via Activity Explorer), how the signal is produced, the availability/licensing caveat, the reporting-vs-enforcement boundary, the outcome-vs-determination boundary, and the naming convention |
| 2. Requirements Guide | Every reporting prerequisite with Verify / Implement-if-missing (compliance licensing, the two Content Explorer viewer role groups, a named analyst group + role separation, audit ingestion, existing classification signal, pilot scope + change control, PowerShell toolchain) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell steps: baseline readiness, confirm the signal, design the analyst group + dashboard, enable audit + the scoped viewer roles (pilot first), open the explorers, produce pilot reports, validate, expand to the full audience, schedule exports + health checks |
| 5. Testing Guide | Validation procedures with explicit pass/fail, treating empty/baseline estate and ingestion lag as expected states |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for reporting on classification safely and least-privilege |

## PowerShell scripts
All are safe-by-default (read-only, or `-WhatIf` preview unless `-Commit`), use `Connect-IPPSSession` and/or
`Connect-ExchangeOnline`, and store **no** credentials.
| Script | What it does |
|---|---|
| `CLSREPORT-Discovery.ps1` | Read-only readiness baseline: whether unified audit log ingestion is on, current membership of the two Content Explorer viewer role groups, an inventory count of sensitivity/retention labels and SITs available to report on, and whether the export cmdlets resolve in the tenant. Run it first (Implementation Phase 1) |
| `CLSREPORT-Configure.ps1` | Configuration helper for the two governed prerequisites — enables unified audit log ingestion (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`) and grants the scoped viewer roles (`Add-RoleGroupMember` for `Content Explorer List Viewer` / `Content Explorer Content Viewer`). Defaults to preview; writes only with `-Commit`; Content Viewer flagged as sensitive-data grant. Creates no labels/SITs/policies |
| `CLSREPORT-Validate.ps1` | Read-only PASS/FAIL gate: audit ingestion True, expected analysts present in List Viewer, Content Viewer within the minimal threshold with no drift, and the export surfaces resolve (unresolved `Export-ContentExplorerData` reported as VERIFY, not FAIL). Run before expanding to the full audience |
| `CLSREPORT-Report.ps1` | Read-only export of the two dashboard feeds: COVERAGE (items per label/retention label/SIT/classifier via `Export-ContentExplorerData` where available — flagged "verify in your tenant", portal fallback otherwise) to `coverage-by-tag.csv`, and ACTIVITY (label lifecycle + DLP + egress via `Search-UnifiedAuditLog`) to `activity-summary.csv`. Empty-estate and ingestion-lag noted as valid findings |
| `CLSREPORT-ScopeHealth.ps1` | Read-only reporting data-source health: audit ingestion + retention window, per-workload activity presence (is each workload reporting in), the tag inventory to report on, and licensing-readiness flags for the gated surfaces (Content Viewer, Activity Explorer export). Catches audit lag, workload drop-off, and tag drift on a schedule |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot (simulate/limited scope)
  → Validate → Expand**, with explicit pass/fail gates and a documented rollback.

## Outcome
Classification made **visible, measurable, and defensible** in Microsoft Purview: coverage reported across
every sensitivity label, retention label, SIT, and classifier; activity reported across label lifecycle,
DLP matches, and egress; dashboards standing on repeatable CSV exports; and the access model least-privilege
and audited — every step read-only or previewed before commit, changing no content. Standing up label/DLP
*enforcement* is a separate, scoped solution. Regulatory, records, and legal determinations arising from the
reports remain with the organization's governance functions; this solution delivers the technical method and
the evidence.
