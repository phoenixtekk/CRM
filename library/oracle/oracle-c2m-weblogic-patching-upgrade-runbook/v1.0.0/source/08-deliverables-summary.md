# 8. Deliverables Summary — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The C2M/OUAF + WebLogic patch/upgrade model, supportability, the certified-version matrix, OPatch/OUAF tooling, and the environment progression (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites, published once |
| 3. Upgrade & Patch Runbook | Exact, ordered steps: readiness + backup, apply patches / perform upgrade, post-apply validation, rollback — per environment with go/no-go gates |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## Automation scripts (WLST/Jython, shell & SQL — not PowerShell)
| Script | What it does |
|---|---|
| `OC2MPATCH-Discovery.sh` | Read-only baseline of current patch/version state: C2M/OUAF fix inventory, WebLogic `opatch lsinventory`, OS/JDK/DB/WebLogic versions, domain/server layout |
| `OC2MPATCH-Validation.sh` | Read-only post-patch validation: expected patch/version present, managed servers RUNNING, DB level, health checks; `--pre-check` confirms backups before apply |
| `OC2MPATCH-Report.sh` | Read-only patch/version coverage report per environment/node (baseline vs post-apply) for the change record |
| `OC2MPATCH-Remediation.sh` | Safe remediation helper for common gaps; **dry-run by default**, never applies a patch itself |
| `OC2MPATCH-ScopeHelper.sh` | Builds the environment/target list and confirms the lower-first progression for this change |

## Named runbook artifacts
| Artifact | Name / description |
|---|---|
| Readiness gate | `Gate A` — verified backups + certified stack + cleared prerequisites before any apply |
| Promote gate | `Gate C` — inventories/health/tests pass before promoting the change to the next environment up |
| Backup set | DB restore point/RMAN + Oracle Home + WebLogic domain + OUAF product/config archives |
| Rollback | OPatch rollback / OUAF back-out (patch) or restore-from-backup (upgrade) |

## What the buyer receives
- This runbook as a branded Word document and PDF.
- All five automation scripts (shell / WLST-Jython / SQL) in a single ZIP.
- A repeatable patch/upgrade method following the model: Assess, then Configure, then Pilot, then
  Validate, then Expand — proven in lower environments before production.

## Outcome
C2M and WebLogic kept current and supportable — patches and version upgrades (toward 25.4) applied with
readiness, backup, validation, and a documented rollback — proven in lower environments before
production, closing support gaps without unplanned outages.
