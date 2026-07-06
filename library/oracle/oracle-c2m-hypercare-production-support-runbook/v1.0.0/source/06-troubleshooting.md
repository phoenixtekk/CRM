# 6. Troubleshooting Guide — Oracle C2M Hypercare & Production Support Runbook

Use `OC2MHYPER-Discovery.sh` and `OC2MHYPER-Validation.sh` for readiness/config state,
`OC2MHYPER-Report.sh` for the daily health snapshot and the open-incident/known-issue summary,
`OC2MHYPER-Report.sql` for batch/integration/database detail, and `OC2MHYPER-Remediation.sh` (dry-run
by default) for safe operational alignments. Source the environment first:
`splenviron.sh -e your-env`. MOS-gated go-live checklists, patches, and known-issue notes are pointed
to, not reproduced.

## A. Readiness checklist stays red
| Symptom | Cause | Remediation |
|---|---|---|
| Validation fails on WebLogic | A managed server or the Admin server not RUNNING | Confirm server state via WLST; start the server in the change window; re-run `OC2MHYPER-Validation.sh` |
| Validation fails on batch | `threadpoolworker`/batch daemon not started on the designated node | Start the worker/daemon (`threadpoolworker`/`starttpw` — verify for your version); confirm the JMX batch connector responds |
| Validation fails on integration | An inbound/outbound endpoint unreachable or disabled | Confirm the endpoint URL/queue with the integration team; enable it; re-check |
| Checklist item red, no owner | Ownership not assigned | Assign an accountable owner per line before go/no-go; a red item needs a signed exception or a fix |

## B. Cutover go/no-go fails
- The smoke checks do not pass at the go/no-go point. **Do not press on.** Execute the documented
  rollback from `C2M Runbook - Cutover - Plan` — restore the pre-cutover backups and revert config —
  with the named authorizer's approval. Then diagnose on the restored environment, fix, and reschedule
  the cutover; a forced cutover past a failed go/no-go is how a bad night becomes a bad week.

## C. An incident has no clear owner
- An issue arrives and the bridge spends its first hour deciding who owns it. The rota was not staffed
  for the window or not published. Render the current window with
  `OC2MHYPER-ScopeHelper.sh --scope rota`; if a layer has no primary/secondary, fix the
  `C2M Runbook - OnCall - Rota` and publish it. Escalation order comes from
  `C2M Runbook - Escalation - Matrix` keyed to the severity — set the severity first (Step 3) so the
  matrix routes it.

## D. The same problem keeps being re-diagnosed
- A recurring symptom is investigated from scratch each time. It is not in the known-issue register,
  or the register is not consulted. Add it to `C2M Runbook - KnownIssue - Register` with its
  workaround and tracking reference (a MOS note/patch or internal ticket — point to gated notes, do
  not copy them); make consulting `OC2MHYPER-Report.sh` / the register the first triage step.

## E. Day-2 change destabilized production
- A configuration or code change went straight into the stabilizing production system and caused an
  incident. Day-2 work must run through `C2M Runbook - Day2 - Build Lane`: built and tested in a lower
  environment, promoted only through change control with a rollback. Roll the change back, rebuild it
  in a lower environment, and re-promote through the lane; list the lane with
  `OC2MHYPER-ScopeHelper.sh --scope day2`.

## F. Daily health shows amber/red
| Symptom | Cause | Remediation |
|---|---|---|
| Batch amber/red | Last night's cycle did not complete, or backlog did not drain | Inspect run status and backlog with `OC2MHYPER-Report.sql`; check live threads via the JMX batch connector; open an incident at the right severity |
| Integration amber/red | A queue over threshold or a stuck message | Confirm the queue depth with the integration team; clear/replay per their runbook; track as an incident |
| Database/disk amber/red | Tablespace or log/filesystem space near threshold | `OC2MHYPER-Report.sql` shows space; engage the DBA; `OC2MHYPER-Remediation.sh` (dry-run) prints safe log/space cleanup targets — apply only in a change window |
| Error-log delta spikes | New ERROR/FATAL lines since yesterday | Review the delta; correlate with any incident; add a recurring signature to the known-issue register |

## G. JMX batch connector cannot connect
- `OC2MHYPER-Discovery.sh`/`OC2MHYPER-Validation.sh` cannot reach the batch JMX interface. Confirm the
  RMI/JMX port is populated on the worker and the connector URL is right —
  `service:jmx:rmi:///jndi/rmi://your-host:your-jmx-port/oracle/ouaf/batchConnector` (verify the exact
  form for your version) — and that the port is reachable. Restart the worker in a change window if the
  port was not set; then the daily batch health check can read live threads.

## H. Health will not stabilize / hypercare will not exit
- Health keeps producing amber/red or Sev-1/Sev-2 incidents recur, so the steady-state exit gate is
  never met. Do not exit on the calendar. Work the top recurring signatures from the known-issue
  register to root cause (day-2 lane fixes promoted under change control), re-measure with the daily
  routine, and exit only when health is green for the agreed consecutive days with no open Sev-1/Sev-2
  and a controlled day-2 backlog.

## I. Diagnostics quick reference
```bash
splenviron.sh -e your-env                         # source the environment first
./OC2MHYPER-Discovery.sh                           # readiness/health current state (read-only)
./OC2MHYPER-Validation.sh                          # go-live readiness signals PASS/FAIL (read-only)
./OC2MHYPER-Report.sh                              # daily health snapshot + open incidents/known issues (read-only)
sqlplus user@db @OC2MHYPER-Report.sql              # batch/integration/database health detail (read-only)
./OC2MHYPER-ScopeHelper.sh --scope rota            # current on-call window contacts
./OC2MHYPER-ScopeHelper.sh --scope day2            # day-2 build lane environments/controls
./OC2MHYPER-Remediation.sh                         # dry-run by default; add the apply flag in a change window
```

## J. When to escalate
If readiness is green, the rota and escalation matrix are staffed, incidents are being handled through
the procedure, and a symptom still recurs or health will not stabilize after remediation and day-2
fixes, capture `OC2MHYPER-Validation.sh`, `OC2MHYPER-Report.sh`, and `OC2MHYPER-Report.sql` output and
review with the DBA, middleware, and integration teams. For a suspected product defect, use the
My Oracle Support Service Request path in the escalation matrix and reference the version's
known-issue notes — gated content is pointed to, not reproduced here.
