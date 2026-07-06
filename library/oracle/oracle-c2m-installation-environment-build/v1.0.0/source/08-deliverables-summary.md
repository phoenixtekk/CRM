# 8. Deliverables Summary — Oracle Customer to Meter (C2M) Installation & Multi-Environment Build

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what is in the box |
| 1. Solution Overview | The C2M/OUAF architecture (product home, WebLogic domain, database schema), the certified stack, the standard build model, benefits and limitations |
| 2. Requirements Guide | Every C2M-specific prerequisite with Verify and Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites, published once |
| 3. Installation Guide | Exact ordered steps per environment: assess + backup, framework install, product install, database schema load, WebLogic domain, configure + validate, expand to Test then Prod |
| 5. Testing Guide | Validation procedures with pass/fail gates, per environment |
| 6. Troubleshooting Guide | Field issues at each build stage and safe remediation |
| 7. Best Practices | Field-proven recommendations for repeatable multi-environment builds |

## Named objects (reused across the documents and scripts)
| Object | Name | Scope |
|---|---|---|
| Environments (`$SPLENVIRON`) | `C2MDEV`, `C2MTST`, `C2MPRD` | Dev / Test / Prod |
| Product OS user | `cissys` | Owns `$SPLEBASE`, runs OUAF utilities |
| Product home / output | `$SPLEBASE` (`/opt/oracle/spl/your-env`) / `$SPLOUTPUT` | Per environment |
| WebLogic domain | `c2m_domain` | Native WebLogic 14c domain |
| WebLogic servers | `AdminServer`, `c2m_server1` | Admin + Managed server |
| DB accounts | `CISADM` (owner), `CISUSER` (app), `CISREAD` (read-only) | C2M schema |
| Security role | `cisusers` | Online application access |

## Automation scripts (WLST / shell / SQL) — five roles
| Script | Language | What it does |
|---|---|---|
| `OC2MINST-Discovery.sh` | shell | Read-only discovery of the host/prereq state before a build: OS user, Java, WebLogic Home/version, mount points and free space, DB listener reachability, and whether the chosen WebLogic ports are free |
| `OC2MINST-Validation.py` | WLST/Jython | Read-only validation against `c2m_domain`: confirms `AdminServer` and `c2m_server1` are RUNNING and the C2M application/IWS are ACTIVE |
| `OC2MINST-Report.sql` | SQL | Read-only build/schema report: confirms `CISADM` owns the expected C2M objects, `CISUSER`/`CISREAD` exist, and the installed release matches the intended level |
| `OC2MINST-Remediation.sh` | shell | Safe remediation for common build issues (ownership/permissions on `$SPLEBASE`, template rebuild via `initialSetup.sh -t`, non-RUNNING server restart); **dry-run by default**, changes only with `-apply` |
| `OC2MINST-ScopeHelper.sh` | shell | Targeting/env helper: resolves `$SPLENVIRON`/`$SPLEBASE`/domain/DB for a named environment so commands run against the intended tier |

> The five roles are Discovery, Validation, Report, Remediation, and ScopeHelper, each authored in the
> language native to the layer it works on — shell for the OUAF file system and OS, WLST/Jython for the
> WebLogic domain, and SQL for the database schema.

## What the buyer receives
- This installation and multi-environment build guide as a Word document and PDF.
- The automation scripts (WLST/Jython, shell, and SQL) in a single ZIP.
- A repeatable, per-environment process following the standard model: Assess → Configure → Pilot →
  Validate → Expand, with explicit pass/fail gates and a documented rollback.

## Outcome
Oracle C2M installed and configured consistently in Dev, Test, and Production — certified stack, OUAF
product home, healthy WebLogic `c2m_domain`, and a valid `CISADM` schema — validated against pass/fail
gates and reproducible from recorded inputs, proven on non-production before Production is built.
