# 8. Deliverables Summary — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The C2M fault domains (WebLogic / database / network / application-OUAF) and the layered root-cause model (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites, published once |
| 3. Diagnostic Playbook | The symptom-driven decision tree: won't start / can't log in; batch fails; JMS backs up; IWS/integration errors; performance stall; outage — exact checks per branch and the layer each isolates |
| 5. Testing Guide | Toolkit-ready and restore-complete procedures with pass/fail gates |
| 6. Troubleshooting Guide | Failure modes of the diagnostics themselves and the wrong-layer traps |
| 7. Best Practices | Defensible RCA, layer-isolation discipline, and escalation to Oracle |

## Named diagnostic artifacts
| Artifact | Name |
|---|---|
| Four-layer fault model | `C2M RCA - Fault Domain Map` |
| Symptom-to-branch tree | `C2M RCA - Symptom Decision Tree` |
| Per-layer isolation checks | `C2M RCA - Layer Isolation Checklist` |
| Point-in-time evidence bundle | `C2M RCA - Diagnostic Snapshot` |
| Defensible root-cause write-up | `C2M RCA - Root-Cause Record` |

## Automation scripts (WLST/Jython, shell & SQL — not PowerShell; all read-only, remediation dry-run by default)
| Script | What it does |
|---|---|
| `OC2MRCA-Discovery.sh` | Collects the `C2M RCA - Diagnostic Snapshot`: environment/domain/log resolution, server states, thread/heap and log tails, and DB signal pointers (read-only) |
| `OC2MRCA-Validation.py` | WLST per-layer checks: server states/health, execute-thread pool (stuck/hogging), JDBC data-source/pool state, JMS consumer/pending counts, and certificate expiry (read-only) |
| `OC2MRCA-Report.sql` | Consolidated database diagnostics: batch/JMS run status, in-flight/overdue threads, blocking sessions, tablespace/temp pressure, error rows (read-only) |
| `OC2MRCA-Remediation.sh` | Previews the smallest safe restore (orderly restart / data-source re-sync / JMS re-sync); **dry-run by default**, applies only with an explicit flag in a change window |
| `OC2MRCA-ScopeHelper.sh` | Bounds the incident to tier/servers, selects the matching Diagnostic Playbook branch, and emits the target set the other scripts run against |

## What the buyer receives
- This Diagnostic Playbook and its guides as a branded Word document and PDF.
- All five automation scripts (shell / WLST-Jython / SQL) in a single ZIP.
- A repeatable diagnostic method following the model: Assess (scope + snapshot), then Configure (the
  checks), then Pilot (non-production or a captured snapshot), then Validate (restore gate), then
  Expand.

## Outcome
The failing layer of a C2M problem isolated fast — service restored with the smallest safe action and a
defensible root-cause analysis produced — with a repeatable playbook and read-only scripts the buyer
keeps and reuses on every future incident.
