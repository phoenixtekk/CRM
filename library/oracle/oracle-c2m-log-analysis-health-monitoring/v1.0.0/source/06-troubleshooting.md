# 6. Troubleshooting Guide — Oracle C2M Log Analysis & Health Monitoring (SLO Assurance)

Use `OC2MLOG-Discovery.sh` for the log inventory and currency, `OC2MLOG-Validation.sh` for the health
checks and whether each early-warning signal fires, `OC2MLOG-Report.sh` for the health/SLO view, and
`OC2MLOG-Remediation.sh` (dry-run by default) for safe log rotation/cleanup. Source the environment
first: `splenviron.sh -e your-env`. MOS-gated notes are pointed to, not reproduced.

## A. A log layer cannot be found or read
| Symptom | Cause | Remediation |
|---|---|---|
| OUAF logs not found | `SPLEBASE` not set / wrong env | Re-source `splenviron.sh -e your-env`; confirm `$SPLEBASE/logs/system` exists and is readable; re-run `OC2MLOG-Discovery.sh` |
| Batch logs not found | `SPLOUTPUT` not set / no recent runs | Confirm `SPLOUTPUT` resolves and recent `threadpoolworker.*` files exist; if no runs, that is a batch gap, not a log gap |
| WebLogic logs not found | `DOMAIN_HOME` unknown / no read grant | Set/confirm `DOMAIN_HOME`; grant read on `$DOMAIN_HOME/servers/*/logs`; the domain log is under the Administration Server's log dir |

## B. A log is stale (stopped being written)
- A log's newest entry is old — collection is not live for that layer. Confirm the owning process is
  running (online server, thread pool worker, or Admin/managed server), that the process is writing to
  the expected path (custom log-file names can redirect it via user exits — verify for your version),
  and that the filesystem is not full (a full volume silently stops writes). A stale log is a blind
  spot and fails the collection-health check in `OC2MLOG-Validation.sh`.

## C. A signal never fires (false all-clear)
| Symptom | Cause | Remediation |
|---|---|---|
| Known error not detected | Threshold set too high, or wrong log | Re-baseline (Implementation Step 4) and lower the trip point; confirm the signal reads the correct log; re-test with a known trigger |
| Signal pattern never matches | Log format/level differs for your version | Verify the OUAF log format and the exact `ERROR`/`FATAL` wording for your version; adjust the pattern; re-run `OC2MLOG-Validation.sh` |
| Batch failure missed | Reading `-user.log` only, not `-tech.log` | Include both `threadpoolworker.*-tech.log` and `-user.log` — technical failures show in the tech log |

## D. A signal fires constantly (alert fatigue)
- A signal trips on every healthy run. Its threshold is below the environment's baseline. Measure
  normal first, then set the trip point above it (Implementation Step 4). A signal that always fires is
  as useless as one that never does — re-tune, do not silence it.

## E. Cross-layer correlation does not line up
- An application error and its WebLogic entry will not correlate. Confirm **NTP** keeps the hosts'
  clocks in step (skew breaks time-based matching) and that the log lines carry the **ECID** field
  (`<userid> <transactionid> <ECID> <date/time> ...`). If the ECID is absent, verify the log format for
  your version; correlate on ECID first, time second. `OC2MLOG-Validation.sh` reports whether the ECID
  field is populated.

## F. `OutOfMemoryError` or connection-pool exhaustion in the WebLogic log
- The container is at risk. An `OutOfMemoryError` means a JVM is (or is about to be) down; "no
  resources currently available" means the JDBC pool is exhausted and the application is degrading.
  These are top-priority signals: capture the server log around the event, engage the middleware/DBA
  teams on heap sizing or pool sizing, and treat as an incident. This solution *detects* early — the
  fix (heap/pool tuning) is applied under change control, proven on non-production first.

## G. Log filesystem filling / logs growing too fast
- A log directory is near full or growing faster than rotation. Confirm WebLogic rotation
  (`LogFileMBean` file min size / file count) is set, and that `$SPLOUTPUT` and `logs/system` have a
  rotation/retention policy. Preview a safe rotation/cleanup with `OC2MLOG-Remediation.sh` (dry-run),
  then apply in a change window. Never delete or truncate an active log by hand — that is its own
  incident.

## H. An SLO is breaching or its error budget is burning
- The health report shows an SLO at or past its budget. Read which signal is driving it (availability
  ← OOM/pool/stuck; batch-completion ← batch failures; error-rate ← error signal; coverage ← a stale
  log) and address the underlying signal. A budget burning faster than the window allows is the early
  warning — act on the burn rate before the SLO is missed.

## I. Diagnostics quick reference
```bash
splenviron.sh -e your-env                        # source the environment first
./OC2MLOG-Discovery.sh                            # inventory OUAF/WebLogic/batch logs, sizes, currency (read-only)
./OC2MLOG-Validation.sh                           # health checks + which early-warning signals fire (read-only)
./OC2MLOG-Report.sh                               # daily health/SLO view with error budgets (read-only)
./OC2MLOG-ScopeHelper.sh --scope pilot            # resolve the pilot log-source/host/signal scope
./OC2MLOG-Remediation.sh                          # dry-run log rotation/cleanup; add --apply in a change window
```

## J. When to escalate
If every log is inventoried and current, the signals are tuned to baseline, and a signal keeps firing
(or an SLO keeps breaching) after the configuration is sound, the cause is below monitoring — a code,
data, capacity, or infrastructure problem. Capture `OC2MLOG-Validation.sh`, `OC2MLOG-Report.sh`, and
the relevant log excerpts (by ECID) and review with the middleware, DBA, and application teams. For
product defects, consult the version's My Oracle Support notes and open a service request — gated
content is pointed to, not reproduced here.
