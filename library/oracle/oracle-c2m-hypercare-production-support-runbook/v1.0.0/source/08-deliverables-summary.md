# 8. Deliverables Summary — Oracle C2M Hypercare & Production Support Runbook

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The hypercare operating model and production-support structure (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites, published once |
| 3. Runbook | The runbook itself: go-live readiness checklist, on-call/escalation model, incident + known-issue handling, day-2 build support in lower environments, and the daily health/monitoring routine — with gates |
| 5. Testing Guide | Validation procedures with pass/fail gates (readiness gated, incidents handled, health stable) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for a smooth stabilization |

## Named objects
| Object | Name |
|---|---|
| Go-live readiness gate | `C2M Runbook - Readiness - Go-Live Checklist` |
| Cutover sequence | `C2M Runbook - Cutover - Plan` |
| On-call schedule | `C2M Runbook - OnCall - Rota` |
| Escalation matrix | `C2M Runbook - Escalation - Matrix` |
| Severity model | `C2M Runbook - Severity - Model` |
| Incident lifecycle | `C2M Runbook - Incident - Procedure` |
| Known-issue register | `C2M Runbook - KnownIssue - Register` |
| Day-2 build lane | `C2M Runbook - Day2 - Build Lane` |
| Daily health snapshot | `C2M Runbook - Health - Daily Routine` |

## Automation scripts (WLST/Jython, shell & SQL — not PowerShell)
| Script | What it does |
|---|---|
| `OC2MHYPER-Discovery.sh` | Captures go-live/health current state — WebLogic servers, batch daemon, JMX batch connector, integrations, backup presence, monitoring signals (read-only) |
| `OC2MHYPER-Validation.sh` | Validates the technical go-live readiness signals behind the checklist and reports PASS/FAIL per signal (read-only) |
| `OC2MHYPER-Report.sh` | Renders the daily health snapshot and the open-incident / known-issue summary from the runbook files and live signals (read-only) |
| `OC2MHYPER-Report.sql` | Renders batch run status/backlog, integration queue depth, and database/space health from the C2M schema (read-only) |
| `OC2MHYPER-Remediation.sh` | Aligns safe operational settings (restart guidance, log/space cleanup targets, health-threshold config) to the standard; dry-run by default, applies only with an explicit flag in a change window |
| `OC2MHYPER-ScopeHelper.sh` | Renders the on-call rota window (`--scope rota`) and the day-2 build lane (`--scope day2`) from the scope file for pilot and hypercare |

*(Five automation scripts as specified — Discovery, Validation, Report, Remediation, ScopeHelper — with the Report delivered in two authentic forms, a shell operational summary and a SQL data report, per the C2M/WLST/SQL toolchain.)*

## What the buyer receives
- This runbook as a branded Word document and PDF.
- All automation scripts (shell / WLST-Jython / SQL) in a single ZIP.
- A repeatable operating model following: Assess, then Configure, then Pilot, then Validate, then
  Expand.

## Outcome
A C2M go-live and hypercare the team can actually run — readiness proven and gated, cutover
reversible, on-call and escalation structured, incidents handled and recorded, known issues worked
around, day-2 builds kept safely in the lower environments, and health measured green every morning —
from cutover through stabilization to a clean steady-state exit.
