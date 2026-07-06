# 3. Implementation Guide — Oracle C2M Log Analysis & Health Monitoring (SLO Assurance)

Follow these steps in order. This guide establishes C2M log analysis and health monitoring: locate and
standardize the logs across all three layers first, then define the health checks and early-warning
signals, then track against SLOs, then validate — pilot-first on a non-production environment, then
expand to production under change control. Object names are fixed — create them with the exact names
shown and reuse them everywhere.

> Model: assess the current log landscape and blind spots, configure the inventory, checks, signals,
> and SLOs, prove it on a non-production pilot, validate against the gate, then expand to production.
> Assess, then Configure, then Pilot, then Validate, then Expand — with a documented rollback for every
> production change.

> All commands assume the environment is sourced first: `splenviron.sh -e your-env` (run as the
> product user). Log paths, file names, and the OUAF log format are from the OUAF/C2M Server
> Administration Guides and the WebLogic Server logging documentation — verify the exact paths and
> file-name patterns for your version.

## Step 1 — Assess the current log landscape
1. Source the environment (`splenviron.sh -e your-env`) and run `OC2MLOG-Discovery.sh`. It captures:
   the OUAF application logs under `$SPLEBASE/logs/system` (`spl*.log`), the batch logs in `$SPLOUTPUT`
   (`threadpoolworker.<pool>.<datetime>-tech.log` / `-user.log`), and — from `DOMAIN_HOME` — the
   WebLogic server and domain logs, with each location's file list and directory size (read-only).
2. Identify the blind spots: logs you cannot read, logs that stopped being written, a filesystem near
   full, or a layer with no monitoring at all. Record gaps against the Requirements Guide checklist.
   Do not proceed past an unreadable log layer or a missing environment — implement those first.

## Step 2 — Locate and standardize the logs (build the inventory)
1. Build the inventory `C2M Log - Inventory - All Layers` — one row per log with its path, the layer
   (OUAF / WebLogic / batch), what it carries, its owner, and its rotation/retention:
   - **OUAF application:** `$SPLEBASE/logs/system/spl*.log` (and `spl_service.log` for service times).
   - **WebLogic server:** `$DOMAIN_HOME/servers/<server>/logs/<server>.log` per managed server.
   - **WebLogic domain:** `$DOMAIN_HOME/servers/<AdminServer>/logs/<domain>.log` (aggregated).
   - **Batch:** `$SPLOUTPUT/threadpoolworker.<threadpool>.<datetime>-tech.log` and `...-user.log`.
2. Confirm the log line format carries the **ECID** (`<userid> <transactionid> <ECID> <date/time>
   <threadinfo> <log level> (<class>) <message>`) so entries can be correlated across layers, and that
   NTP keeps the hosts' clocks in step (Requirement 2.7). Standardize on the ECID as the correlation
   key.

## Step 3 — Define the health checks
1. Create the health-check set `C2M Health - Checks - Standard` — the standing checks run against the
   three layers:
   - **Application health** — `spl*.log` current and error rate within threshold.
   - **Container health** — WebLogic server logs free of `OutOfMemoryError`, connection-pool
     exhaustion, and repeated stuck-thread warnings.
   - **Batch health** — recent `threadpoolworker` logs show completed, not errored/overrunning, runs.
   - **Collection health** — every inventoried log is current (being written) and the log filesystems
     have headroom.
2. Each check names the log it reads and the pass condition. Run `OC2MLOG-Validation.sh` to exercise
   the check set against the inventoried logs.

## Step 4 — Define the early-warning signals
1. Create the early-warning signal set `C2M Health - Signals - EarlyWarning` — each signal is a
   pattern in a named log with a threshold that means "act now, before it becomes downtime":
   | Signal | Read from | Fires on |
   |---|---|---|
   | Error/exception rate | OUAF `spl*.log`, WebLogic server log | `ERROR`/`FATAL` + stack traces per interval above baseline |
   | `OutOfMemoryError` / heap | WebLogic server log | any `OutOfMemoryError` / repeated heap-pressure lines |
   | Connection-pool exhaustion | WebLogic server log | "no resources currently available" / pool-at-max |
   | Stuck threads | WebLogic server log | repeated "stuck thread" warnings |
   | Batch failure / overrun | `$SPLOUTPUT/threadpoolworker.*` | errored threads or non-completing runs |
   | Log growth / disk | log filesystems | directory/volume above the headroom threshold |
2. Set each threshold from the environment's own baseline (Step 1), not a guess — measure normal, then
   set the trip point above it. `OC2MLOG-Validation.sh` reports whether each signal pattern is found
   (fired) or cleanly absent.

## Step 5 — Define the SLOs and error budgets
1. Create the SLO set `C2M SLO - Uptime - Standard` — each SLO with a target, an error budget, a
   measurement source, and an owner:
   - **Availability** — % of the window C2M is up and serving (error budget = allowed downtime).
   - **Batch-completion** — % of scheduled cycles completing successfully in-window.
   - **Error-rate** — application/middleware error rate kept below the defined threshold.
   - **Log-freshness / coverage** — every in-scope log current and collected (no blind spots).
2. Map each SLO to the signal(s) that measure it (availability ← OOM/pool/stuck signals + up/down;
   batch-completion ← batch signal; error-rate ← error-rate signal; coverage ← collection-health
   check). Set targets from the business's uptime commitments and assign owners.

## Step 6 — Stand up the health report
1. Build the daily health view `C2M Health - Report - Daily`: run `OC2MLOG-Report.sh` (read-only) to
   render, from the inventoried logs and signals, the current health-check results, which early-warning
   signals fired, and each SLO's status and remaining error budget.
2. Make it the standing operational view so health and SLO burn are visible every day — a signal that
   fired or a budget burning down is the early warning, caught in operations rather than by a business
   user.

## Step 7 — Scope the pilot
1. Run `OC2MLOG-ScopeHelper.sh --scope pilot` to resolve the bounded set of log sources / hosts /
   signals to bring under monitoring first (a representative slice: one managed server, the batch
   pool, the OUAF logs), then the full set for expansion. This keeps the pilot to a known scope rather
   than "everything at once".

## Step 8 — Pilot the monitoring on non-production
1. On the non-production environment, run the full monitoring pass over the pilot scope: build/confirm
   the inventory (`OC2MLOG-Discovery.sh`), exercise the checks and signals (`OC2MLOG-Validation.sh`),
   and render the health/SLO report (`OC2MLOG-Report.sh`).
2. Deliberately trigger a safe, known signal in non-production (for example, generate a handful of
   test `ERROR` lines, or run a batch known to fail) and confirm the corresponding early-warning signal
   fires in the report — proving the monitoring *detects*, not just *collects*.

## Step 9 — Validate against the pilot gate
1. Complete the Testing Guide. The pilot passes only when: every inventoried log across the three
   layers is readable and current; each health check runs and reports; each early-warning signal fires
   on a known trigger and is clean otherwise; and the health report renders every SLO's status and
   error budget.
2. Remediate any gaps — an unreadable log, a filesystem short on headroom, an un-rotated log — with
   `OC2MLOG-Remediation.sh` (dry-run by default: it previews the log rotation/cleanup or config change;
   add the apply flag only in a change window) before re-running validation.

## Step 10 — Expand to production
1. After the pilot passes the gate, apply the same inventory (`C2M Log - Inventory - All Layers`),
   checks (`C2M Health - Checks - Standard`), signals (`C2M Health - Signals - EarlyWarning`), and SLOs
   (`C2M SLO - Uptime - Standard`) to production under change control, with backups of any
   logging-config change taken first and a documented rollback ready.
2. Run `OC2MLOG-Report.sh` on the production cadence (daily) and keep `C2M Health - Report - Daily`
   running so signals and SLO burn stay visible day over day — the loop that turns logs into maximized
   uptime.

---
### Order of operations
`Assess landscape -> Inventory logs -> Health checks -> Early-warning signals -> SLOs & budgets -> Health report -> Scope pilot -> Pilot monitoring -> Validate gate -> Expand to production`
