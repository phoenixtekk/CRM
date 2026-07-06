# 8. Deliverables Summary — Oracle C2M Batch Scheduling & Thread-Pool Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The C2M batch architecture: thread pool workers, batch controls, scheduling, dependencies, monitoring (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: named pools, configure workers, scheduler mapping, schedule, dependencies, validate |
| 5. Testing Guide | Validation procedures with pass/fail gates (pools up, jobs complete, no backlog) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for batch sizing and scheduling |

## Named objects
| Object | Name |
|---|---|
| Default thread pool | `C2M Pool - Default - Batch` (`DEFAULT`) |
| Online thread pool | `C2M Pool - Online - Batch` (`ONLINE`) |
| Heavy/billing thread pool | `C2M Pool - Billing - Batch` (`BILLING`) |
| Worker pool set | `C2M Worker - Node - Threadpools` |
| Nightly schedule | `C2M Schedule - Nightly - Batch Cycle` |
| Dependency chain | `C2M Chain - Nightly - Dependencies` |
| Monitoring view | `C2M Monitor - Batch - Run Status` |

## Automation scripts (WLST/Jython, shell & SQL — not PowerShell)
| Script | What it does |
|---|---|
| `OC2MBATCH-Discovery.sh` | Reports batch controls and defaults, configured thread pools/counts per worker node, and recent run history from the C2M schema (read-only) |
| `OC2MBATCH-Validation.sh` | Confirms each worker advertises the standard pools, scheduler reachability, and run-status/JMX signals (read-only) |
| `OC2MBATCH-Report.sql` | Renders batch run status, durations, failures, throughput, and Batch Job Submission backlog from the schema (read-only) |
| `OC2MBATCH-Remediation.sh` | Aligns pool config / submission gaps to the standard; dry-run by default, applies only with an explicit flag in a change window |
| `OC2MBATCH-ScopeHelper.sh` | Builds the in-scope batch-control / worker-node target list for pilot and expansion |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five automation scripts (shell / WLST-Jython / SQL) in a single ZIP.
- A repeatable configuration following the model: Assess, then Configure, then Pilot, then Validate,
  then Expand.

## Outcome
C2M batch that runs on time and completes — thread pools sized and named, the schedule and its
dependencies correct, backlog and completion visible — proven on a non-production pilot before it is
expanded to production under change control.
