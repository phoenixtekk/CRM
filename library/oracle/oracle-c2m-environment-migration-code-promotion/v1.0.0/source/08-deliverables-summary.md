# 8. Deliverables Summary — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The C2M promotion model: OUAF config migration (CMA/bundles), code/IWS promotion, and environment comparison (the why and the moving parts) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites (entitlement, certified stack, WLST/shell/SQL, change control), published once |
| 3. Implementation Guide | Exact, ordered steps to export/import the bundle, promote code, deploy IWS, compare, and validate — Dev → QA → Prod with gates |
| 5. Testing Guide | Validation procedures with per-environment pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for repeatable promotion |

## Named migration objects
| Object | Role |
|---|---|
| Migration Assistant Configuration | System-wide CMA master record; enables export/import on each environment |
| Migration Plan | Defines what a record type looks like to CMA (MO + business object + related records); one per custom object type |
| Migration Request | The reusable unit of promotion — defines exactly which configuration a release bundles |
| Binary export file (bundle) | The self-contained CMA export, retained in version control and promoted onward |

## Automation scripts (shell / WLST / SQL — not PowerShell)
| Script | What it does |
|---|---|
| `OC2MMIG-Discovery.sh` | Read-only inventory of C2M/OUAF release and patch level, CMA readiness, and Migration Plans/Requests present on an environment |
| `OC2MMIG-Validation.sh` | Read-only parity validation on a target: CMA import applied, IWS deployment current, code build level matched |
| `OC2MMIG-Report.sh` | Read-only source-vs-target compare report for a promoted scope (config objects, IWS status, build level) |
| `OC2MMIG-Remediation.sh` | Corrective helper for parity gaps; **dry-run by default**, prints intended actions before any apply |
| `OC2MMIG-ScopeHelper.sh` | Resolves and prints a Migration Request's declared scope so you promote exactly what you intend |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five automation scripts (shell / WLST / SQL) in a single ZIP.
- A repeatable promotion method following the model: Assess, then Configure, then Pilot, then Validate,
  then Expand.

## Outcome
C2M configuration and code promoted cleanly from Dev to QA to Production — parity confirmed, no drift — so
what you tested is exactly what goes live, pilot-first and rollback-ready.
