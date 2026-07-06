# 6. Troubleshooting Guide — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

This guide troubleshoots **the toolkit and the method** — the failure modes you hit while running the
diagnostics themselves, and the traps that cause a wrong-layer diagnosis. (The symptom-to-fix content
for C2M incidents is the Diagnostic Playbook, document 3.) Use `OC2MRCA-Discovery.sh` and
`OC2MRCA-Validation.py` for state, `OC2MRCA-Report.sql` for the DB view, and `OC2MRCA-Remediation.sh`
(dry-run by default) for safe restore previews. Source the environment first: `splenviron.sh -e
your-env`. MOS-gated notes are pointed to, not reproduced.

## A. Discovery can't find the domain, logs, or utilities
| Symptom | Cause | Remediation |
|---|---|---|
| "environment not sourced" / empty `SPLEBASE` | `splenviron.sh` not run in this shell | Run `splenviron.sh -e your-env` as the product user, then re-run |
| Log paths don't resolve | `SPLOUTPUT`/domain log path wrong or no read access | Confirm the product and WebLogic domain log directories and grant read to the diagnostic account (Requirement 2.2) |
| Utility not found | Utility name differs by version | Verify the utility name/path in the Server Administration Guide for your version |

## B. WLST validation cannot connect
| Symptom | Cause | Remediation |
|---|---|---|
| `connect()` refused/timeout | Wrong admin URL, Admin Server down, or port blocked | Confirm the `t3://` admin URL and that the Admin Server is `RUNNING`; check the port is reachable (this is itself a network-layer finding) |
| Auth failure | Wrong/insufficient admin credentials | Use a read-capable admin account; confirm credentials (Requirement 2.3) |
| WLST won't launch | Wrong WLST/classpath | Launch from the domain's `oracle_common`/`wlserver` WLST; source the environment first |

## C. Report returns nothing or errors
| Symptom | Cause | Remediation |
|---|---|---|
| No rows / ORA on connect | Wrong service or no SELECT grant | Confirm the service name and grant read on the C2M schema (Requirement 2.4) |
| Table/column not found | Object names differ by version | The queries follow the OUAF/C2M model — verify object/column names for your version (they are cited, not invented) |
| Status codes look wrong | Status-flag values differ by version | Confirm the batch/JMS status flag values for your release before acting on them |

## D. Thread dump / JMX not available
- A stuck-thread branch needs a dump but you cannot get one: confirm `kill -3`/`jstack` access to the
  server JVMs (the dump lands in the server `.out` under the domain log dir), or use the console
  Monitoring → Threads *Dump Thread Stacks*. For live batch threads confirm the batch RMI/JMX port
  (e.g. `BATCH_RMI_PORT`) is populated and `jmxbatchclient.sh -s` connects (Requirement 2.5).

## E. The method points at the wrong layer (the classic traps)
- **Skipping the ladder.** Tuning the application or the DB while an **expired certificate** or a
  **down listener** is the real cause. Always walk Reachable → Up → Authenticated → Resourced →
  Correct in order; do not jump to "Correct".
- **Reading a symptom as its layer.** A data source that "won't connect" is usually a **DB or network**
  cause, not a WebLogic bug; a stuck thread is named by the **top of its stack**, not by the fact that
  it is in WebLogic. Read the evidence, not the surface.
- **No baseline.** Without the healthy `C2M RCA - Diagnostic Snapshot` (Requirement 2.7) every reading
  is ambiguous. Capture the baseline on a good day so "what changed" is answerable.
- **Losing evidence to log roll.** Restarting before capturing the snapshot destroys the RCA. Always
  run `OC2MRCA-Discovery.sh` **before** any restart.

## F. Remediation preview vs apply
- `OC2MRCA-Remediation.sh` with no flag is **dry-run** — it prints the intended restore and changes
  nothing. It never restarts a running server itself; it prints the exact restart/re-sync step for the
  admin to run under change control. Only `--apply`, in a change window with backups taken, performs
  it. If a "safe" restore does not clear the symptom, you diagnosed the wrong layer — go back up the
  ladder.

## G. Diagnostics quick reference
```bash
splenviron.sh -e your-env                          # source the environment first
./OC2MRCA-Discovery.sh                              # snapshot: server states, logs, thread/heap, DB signals (read-only)
java weblogic.WLST OC2MRCA-Validation.py            # per-layer checks: servers, threads, JDBC, JMS, certs (read-only)
sqlplus user@db @OC2MRCA-Report.sql                # DB view: batch/JMS status, blocking, tablespace (read-only)
./OC2MRCA-ScopeHelper.sh --symptom performance      # bound the incident, select the branch
./OC2MRCA-Remediation.sh                            # dry-run by default; add --apply in a change window
```

## H. When to escalate to Oracle
If the failing layer is isolated, the platform is healthy, and the fault persists after the safe
restore — or the evidence points to a product defect (a stack in product code, a known error string) —
capture the `C2M RCA - Diagnostic Snapshot` (discovery + validation + report + the thread dump) and
open a service request. Consult the version's My Oracle Support notes (JRF-in-admin-mode,
IWS-deployment, pending-JMS, and similar are documented there); gated content is pointed to, not
reproduced here. Attach the snapshot so Oracle sees the isolating evidence, not just the symptom.
