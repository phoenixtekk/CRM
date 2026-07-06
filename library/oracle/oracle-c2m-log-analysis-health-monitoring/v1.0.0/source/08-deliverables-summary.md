# 8. Deliverables Summary — Oracle C2M Log Analysis & Health Monitoring (SLO Assurance)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The C2M log landscape (OUAF / WebLogic / batch), the health signals, and the SLO model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: locate/standardize logs, define health checks and early-warning signals, track against SLOs, validate |
| 5. Testing Guide | Validation procedures with pass/fail gates (logs accessible, health tracked, SLOs measured) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for log hygiene, early detection, and SLO tracking |

## Named objects
| Object | Name |
|---|---|
| Log inventory (all layers) | `C2M Log - Inventory - All Layers` |
| Health-check set | `C2M Health - Checks - Standard` |
| Early-warning signal set | `C2M Health - Signals - EarlyWarning` |
| SLO set | `C2M SLO - Uptime - Standard` |
| Daily health/SLO report | `C2M Health - Report - Daily` |

## Log landscape covered
| Layer | Location | Carries |
|---|---|---|
| OUAF application | `$SPLEBASE/logs/system/spl*.log` (+ `spl_service.log`) | Application errors, warnings, service timings |
| WebLogic server | `$DOMAIN_HOME/servers/<server>/logs/<server>.log` | JVM/OOM, JDBC pool, JMS, stuck threads |
| WebLogic domain | `$DOMAIN_HOME/servers/<AdminServer>/logs/<domain>.log` | Aggregated domain-level messages |
| Batch / background | `$SPLOUTPUT/threadpoolworker.<pool>.<datetime>-tech.log` / `-user.log` | Batch technical + business output |

## Automation scripts (WLST/Jython, shell & SQL — not PowerShell)
| Script | What it does |
|---|---|
| `OC2MLOG-Discovery.sh` | Inventories the OUAF, WebLogic, and batch logs from `SPLEBASE`/`SPLOUTPUT`/`DOMAIN_HOME` with file lists, sizes, and currency; read-only health/log discovery |
| `OC2MLOG-Validation.sh` | Runs the standard health checks and reports whether each early-warning signal fires or is cleanly absent; read-only |
| `OC2MLOG-Report.sh` | Renders the daily health/SLO view — check results, signals fired, and each SLO's status and error budget; read-only |
| `OC2MLOG-Remediation.sh` | Previews safe log rotation/cleanup (and rotation-config) to align a log location to policy; dry-run by default, applies only with an explicit flag in a change window |
| `OC2MLOG-ScopeHelper.sh` | Builds the in-scope log-source / host / signal target list for the pilot and each expansion wave |

*(An optional WLST helper `OC2MLOG-Validation.py` reads the WebLogic logging configuration read-only
where WLST access is granted — referenced from the shell validation.)*

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five automation scripts (shell / WLST-Jython / SQL) in a single ZIP.
- A repeatable monitoring practice following the model: Assess, then Configure, then Pilot, then
  Validate, then Expand.

## Outcome
C2M logs turned into provable health and uptime — every log across the three layers inventoried and
current, the early-warning signals watched, and health tracked against SLOs with error budgets —
proven on a non-production pilot before it is expanded to production under change control.
