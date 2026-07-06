# 8. Deliverables Summary — Oracle C2M Monitoring & Alerting with Dynatrace

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What to monitor across C2M/WebLogic (JVM, services, batch, endpoints) and how Dynatrace instruments and alerts on it (the why) |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: instrument tiers with OneAgent + JMX, build the C2M dashboards, define standardized alerts + notification, validate coverage |
| 5. Testing Guide | Validation procedures with pass/fail gates (instrumented, dashboards live, alerts fire and route) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations for alert tuning and noise reduction |

## Named objects
| Object | Name |
|---|---|
| Management zone | `C2M - Monitoring Zone` |
| Environment host-group tag | `C2M-Env` (`dev` / `test` / `prod`) |
| Service dashboard | `C2M - Service Health` |
| JVM/batch dashboard | `C2M - JVM & Batch` |
| Infrastructure dashboard | `C2M - Infrastructure` |
| Production alerting profile | `C2M - Production Alerts` |
| Alert — JVM heap | `C2M Alert - JVM Heap High` |
| Alert — GC time | `C2M Alert - GC Time High` |
| Alert — connection pool | `C2M Alert - Connection Pool Exhausted` |
| Alert — endpoint failures | `C2M Alert - Endpoint Failure Rate` |
| Alert — batch worker | `C2M Alert - Batch Worker Down` |
| Notification | `C2M - OnCall Notification` |

## Automation scripts (shell & Dynatrace API via curl — not PowerShell)
| Script | What it does |
|---|---|
| `OC2MDYNA-Discovery.sh` | Confirms tenant reachability and reports which in-scope hosts report a running OneAgent and which C2M JVMs Dynatrace already sees (read-only; never prints the token) |
| `OC2MDYNA-Validation.sh` | Confirms every in-scope tier is instrumented and `C2M-Env`-tagged, connection-pool metrics are present, and the named dashboards/alert rules exist (read-only) |
| `OC2MDYNA-Report.sh` | Renders one monitoring coverage/health snapshot (tiers instrumented, tags, dashboards, alert rules, gaps) to attach to a change record and reuse as a baseline (read-only) |
| `OC2MDYNA-Remediation.sh` | Prints the intended fix for a coverage/config gap (OneAgent install command, missing tag, missing alert); dry-run by default, applies only with an explicit flag in a change window |
| `OC2MDYNA-ScopeHelper.sh` | Builds the in-scope C2M host / tier target list for pilot and expansion from a scope file |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five automation scripts (shell / Dynatrace API via curl) in a single ZIP.
- A repeatable configuration following the model: Assess, then Configure, then Pilot, then Validate,
  then Expand.

## Outcome
C2M health visible in Dynatrace — the WebLogic and thread pool worker tiers instrumented, the service /
JVM / infrastructure dashboards live, and a standardized, tuned set of alerts firing and routed to
on-call — so the team responds to problems before users feel them, proven on a non-production pilot
before it is expanded to production under change control.
