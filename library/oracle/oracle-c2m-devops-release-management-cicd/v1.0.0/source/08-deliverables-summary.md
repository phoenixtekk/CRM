# 8. Deliverables Summary — Oracle C2M DevOps Release Management & CI/CD Automation

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The C2M DevOps model: source control for OUAF config/code, the build → promote → deploy pipeline, and automation of routine admin (the why and the moving parts) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites (entitlement, certified stack, WLST/shell/SQL, change control), published once |
| 3. Implementation Guide | Exact, ordered steps to define the pipeline (build → migrate config → deploy → validate), wire routine-admin automation, add gates/rollback, and validate — Dev → QA → Prod |
| 5. Testing Guide | Validation procedures with per-environment pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for governed, automated releases |

## Pipeline stages and artifacts
| Stage | Artifact | Gate |
|---|---|---|
| Build | Versioned code build + reviewed CMA configuration bundle | Build compiles clean; bundle exports without error |
| Migrate config | Imported configuration in the target (CMA import, reviewed) | Import applied; review showed only the intended scope |
| Deploy | Running target: installed build + deployed IWS, routine-admin run | Build level matched; IWS current; servers up |
| Validate | The parity + health report | Full parity for the scope; environment healthy |

## Automation scripts (shell / WLST / SQL — not PowerShell)
| Script | What it does |
|---|---|
| `OC2MDEVOPS-Discovery.sh` | Read-only inventory of an environment/pipeline: reachability, OUAF release/patch level, utilities present, and release-artifact locations (build, bundle, settings) |
| `OC2MDEVOPS-Validation.py` | Read-only WLST parity/health check on a target: C2M servers running and in-scope Inbound Web Service modules active (vs stale/not-deployed) |
| `OC2MDEVOPS-Report.sql` | Read-only source-vs-target compare report for a promoted scope (build level, CMA import history, IWS revisions, batch controls); run against source and target and diff |
| `OC2MDEVOPS-Remediation.sh` | Corrective helper for parity/health gaps (re-import bundle, re-install build, re-deploy IWS, resume batch); **dry-run by default**, prints intended actions before any apply |
| `OC2MDEVOPS-ScopeHelper.sh` | Resolves and prints a release's scope (build artifact, config request, IWS list) so you promote exactly what you intend |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All automation scripts (shell / WLST / SQL) in a single ZIP.
- A repeatable release pipeline following the model: Assess, then Configure, then Pilot, then Validate,
  then Expand.

## Outcome
C2M releases that are repeatable, governed, and fast — a CI/CD pipeline (build → migrate config → deploy →
validate) plus automation of the routine admin around each release — so what you tested is exactly what
goes live, pilot-first and rollback-ready, instead of slow, error-prone manual work.
