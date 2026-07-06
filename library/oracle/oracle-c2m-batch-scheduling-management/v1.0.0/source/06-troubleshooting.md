# 6. Troubleshooting Guide — Oracle C2M Batch Scheduling & Thread-Pool Management

Use `OC2MBATCH-Discovery.sh` and `OC2MBATCH-Validation.sh` for configuration and coverage state,
`OC2MBATCH-Report.sql` for the run-status/backlog view, `jmxbatchclient.sh` for live threads, and
`OC2MBATCH-Remediation.sh` (dry-run by default) for safe fixes to pool/submission gaps. Source the
environment first: `splenviron.sh -e your-env`. MOS-gated notes are pointed to, not reproduced.

## A. A batch control does not run
| Symptom | Cause | Remediation |
|---|---|---|
| Control never starts | Scheduler program/job missing | Confirm the DBMS Program/Job (or enterprise job) exists for the control; re-check with `OC2MBATCH-Validation.sh` |
| Control queued, never picked up | Batch daemon not running / wrong node | Confirm the daemon node is up and polling the Batch Job Submission table; `OC2MBATCH-Report.sql` shows the backlog growing |
| REST submission fails | `submitbatchREST.sh` args or REST service | Verify `-b your-batch-control` and thread flag; confirm the framework REST submit service is reachable for your version |

## B. Batch window overruns / throughput too low
| Symptom | Cause | Remediation |
|---|---|---|
| Cycle runs past the window | Heavy control under-threaded or in the wrong pool | Move it to `C2M Pool - Billing - Batch`; raise its thread count within host headroom; re-measure with `OC2MBATCH-Report.sql` |
| Threads run but slowly | Database contention from over-committed threads | Reduce total threads across pools/nodes; check DB waits with the DBA — more threads can be slower |
| Online tier degrades during batch | Heavy batch sharing the online pool | Ensure heavy controls use `BILLING`, not `ONLINE`; re-validate pool assignment |

## C. Dependencies not honored
- A dependent control ran before its predecessor finished. The dependency was timing-based, not a
  chain rule. Encode it in `C2M Chain - Nightly - Dependencies` so the successor starts only on
  `predecessor SUCCEEDED`; re-run the cycle and confirm order with `OC2MBATCH-Report.sql`.

## D. A worker node is missing a pool
| Symptom | Cause | Remediation |
|---|---|---|
| Validation flags a missing pool | Node started without the standard `-p` set | Restart the worker with `DEFAULT=..,ONLINE=..,BILLING=..` (the `C2M Worker - Node - Threadpools` set) or set it in `threadpoolworker.properties`; `OC2MBATCH-Remediation.sh` shows the intended fix (dry-run) |

## E. A thread is stuck
- A thread stays active far past its expected duration. List it with
  `jmxbatchclient.sh -j your-jmx-url -d`, filter with `-f pattern`, and cancel the specific thread with
  `-c` (non-production first; production only under change control). If threads repeatedly stick on one
  control, capture the run and review the control with the application team — a stuck thread past all
  fixes is a code/data issue, not a config one.

## F. Backlog does not drain
- The Batch Job Submission backlog stays non-zero after the cycle. Confirm the daemon node is polling,
  the target pool has free threads (`jmxbatchclient.sh -s`), and no control is failing-and-retrying.
  Run `OC2MBATCH-Report.sql` to see which control is backlogged, then re-size or re-sequence it.

## G. JMX client cannot connect
- `jmxbatchclient.sh` fails to reach a worker. Confirm the RMI/JMX port (e.g. `BATCH_RMI_PORT`) is
  populated on that worker and reachable, and that you passed the correct `-j your-jmx-url`;
  `OC2MBATCH-Validation.sh` reports whether the port is configured. Restart the worker in a change
  window if the port was not set.

## H. Diagnostics quick reference
```bash
splenviron.sh -e your-env                        # source the environment first
./OC2MBATCH-Discovery.sh                          # controls, pools/counts, recent run history (read-only)
./OC2MBATCH-Validation.sh                         # pools advertised, scheduler + JMX signals (read-only)
sqlplus user@db @OC2MBATCH-Report.sql             # run status, throughput, backlog (read-only)
jmxbatchclient.sh -j your-jmx-url -s              # live active-thread summary
./OC2MBATCH-Remediation.sh                        # dry-run by default; add the apply flag in a change window
```

## I. When to escalate
If the pools are advertised, the scheduler and daemon are healthy, dependencies are chain-encoded, and
a control still overruns or fails after re-sizing and remediation, capture `OC2MBATCH-Validation.sh`,
`OC2MBATCH-Report.sql`, and the `jmxbatchclient.sh -d` output and review with the DBA and application
team. For product defects, consult the version's My Oracle Support notes and open a service request —
gated content is pointed to, not reproduced here.
