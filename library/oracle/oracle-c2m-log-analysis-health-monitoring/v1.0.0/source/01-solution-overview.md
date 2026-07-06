# 1. Solution Overview — Oracle C2M Log Analysis & Health Monitoring (SLO Assurance)

## What C2M logging and health monitoring is
Oracle Utilities Customer to Meter (C2M) is a layered system — the Oracle Utilities Application
Framework (OUAF) application, the Oracle WebLogic Server middleware that hosts it, and background
**batch** processing — and each layer writes its own logs. The signal that keeps uptime high (a
growing error rate, a filling connection pool, a batch that started failing, a heap heading for an
`OutOfMemoryError`) is in those logs, but it is spread across three log landscapes and buried in
volume. This solution establishes **C2M log analysis and health monitoring** the repeatable way:
find and standardize the logs across all three layers, define a named set of **health checks** and
**early-warning signals** to watch, and track system health against **service-level objectives
(SLOs)** — so you catch problems early and maximize uptime, pilot-first.

> **Version boundary.** Log paths, file names, environment variables, and object terminology below are
> from the OUAF Server Administration Guide, the C2M Server Administration Guide, and the WebLogic
> Server logging documentation. Version-specific details (C2M 25.4 / minimum v2.9, WebLogic 14c, the
> OUAF log format and directory layout) are **cited or flagged "verify for your version"** — never
> invented. Some notes and patches are gated on My Oracle Support (MOS) and are pointed to, not
> reproduced. See `global-requirements-oracle.md`.

## Why this matters
Logs that nobody reads until an outage are cost, not insurance. When the only time anyone looks at
`spl*.log` or the WebLogic server log is after a business user reports the system is down, every
problem is discovered late — the connection pool was exhausted for an hour, the batch failed three
nights running, the heap was climbing all week — and each is a missed chance to intervene before it
became downtime. A real solution turns the logs into leading indicators: it knows exactly where each
log is, defines the specific signals that precede an outage (error-rate spikes, stuck-thread
warnings, pool exhaustion, `OutOfMemoryError`, batch failures), watches them continuously, and
measures the result against SLOs so "how healthy is C2M?" has a number, not an opinion. The fix is
early detection, not faster firefighting.

## The C2M log landscape — three layers
C2M writes logs in three places. Knowing each one — its path, its files, and what it tells you — is
the foundation of everything else.

1. **OUAF application logs (`$SPLEBASE/logs/system`).** The framework's own system logs live under
   the environment's `SPLEBASE` install directory in `logs/system` — the `spl*.log` files (and
   `spl_service.log`, which records SPL service times). These are independent of the WebLogic and
   database logs and carry the application-level errors, warnings, and service timings. (Paths per the
   OUAF Server Administration Guide — verify for your version.)
2. **WebLogic Server logs (`$DOMAIN_HOME/servers/<server>/logs`).** The middleware that hosts C2M
   writes a **server log** per managed server (`<server-name>.log`) and an aggregated **domain log**
   in the Administration Server's log directory (`$DOMAIN_HOME/servers/<AdminServer>/logs/<domain>.log`).
   These carry JVM, deployment, JDBC/connection-pool, JMS, and stuck-thread messages — the health of
   the container C2M runs in. (Paths per the WebLogic Server logging documentation.)
3. **Batch / background-processing logs (`$SPLOUTPUT`).** The thread pool workers write batch logs to
   the application output directory `$SPLOUTPUT`, split into a **technical** and a **business** log per
   pool run: `threadpoolworker.<threadpool>.<datetime>-tech.log` and
   `...-user.log`. These are where a failing or slow batch shows itself. (File-name pattern per the
   OUAF Server Administration Guide — verify for your version.)

The OUAF log line format is consistent across these — `<userid> <transactionid> <ECID> <date/time>
<threadinfo> <log level> (<class>) <message>` — which is what makes them parseable: the **ECID**
(Execution Context ID) is the correlation key that ties an application-layer entry to its WebLogic
and batch entries for the same request or job.

## Health signals — what to watch
From the three log landscapes this solution defines a named, reusable set of **health signals** — the
things that precede an outage — so monitoring watches the same set everywhere:

- **Error/exception rate** — `ERROR`/`FATAL` lines per interval in the OUAF and WebLogic logs, and
  any Java stack traces; a rising rate is the earliest general warning.
- **`OutOfMemoryError` / heap pressure** — the single most important container signal; an OOM in the
  server log means a JVM is (or is about to be) down.
- **Connection-pool health** — JDBC connection-pool exhaustion / "no resources currently available"
  messages in the WebLogic log; a filling pool degrades the whole application before it fails.
- **Stuck threads** — WebLogic "stuck thread" warnings (a thread active past the configured max-stuck
  time); repeated stuck-thread warnings precede a hung server.
- **Batch failures / overruns** — errored threads and long-running or non-completing runs in the
  `threadpoolworker` logs; a batch that starts failing is often the first sign of a data or
  connectivity problem.
- **Log growth / disk** — the logs directories filling `$SPLOUTPUT` / the domain log volume; a full
  log filesystem takes the application down on its own.

This solution names these once as the **health-signal set** and reuses it across environments so the
same signals are watched in Dev, Test, and Production.

## Named objects this solution defines
So the monitoring is repeatable, this solution names its artifacts once and reuses them:

- **Log inventory** — `C2M Log - Inventory - All Layers`, the documented map of every log (OUAF,
  WebLogic, batch) with its path, owner, and retention.
- **Health-check set** — `C2M Health - Checks - Standard`, the standard set of health checks run
  against the three layers.
- **Early-warning signal set** — `C2M Health - Signals - EarlyWarning`, the named signals above with
  their thresholds.
- **SLO set** — `C2M SLO - Uptime - Standard`, the availability and health SLOs (see below) with their
  targets and error budgets.
- **Health report** — `C2M Health - Report - Daily`, the standing daily health-and-SLO view.

## The SLO model
Health is tracked against **service-level objectives** — explicit, measurable targets with an error
budget — not against a vague sense of "seems fine":

- **Availability SLO** — the percentage of a measurement window the C2M application is up and serving
  (for example, a target expressed as a monthly availability percentage). The **error budget** is the
  allowed downtime; watching it burn is itself an early warning.
- **Batch-completion SLO** — the percentage of scheduled batch cycles that complete successfully
  within their window (a failed or overrunning nightly cycle burns this budget).
- **Error-rate SLO** — application/middleware error rate kept below a defined threshold over the
  window.
- **Log-freshness / coverage SLO** — every in-scope log is being collected and is current (a log that
  stopped being written is a blind spot, and a monitoring gap is itself a risk).

Each SLO has an owner, a target, a measurement source (which log and which signal), and a review
cadence. Tracking them turns health from anecdote into a trend you can act on before the budget runs
out. (Targets are yours to set from the business's uptime commitments — this solution defines the
structure and the measurement, not the specific numbers.)

## What this is not
This solution establishes log analysis and health monitoring against SLOs. It does not replace an
enterprise APM/monitoring platform (where one such as Dynatrace exists, this complements it by
defining what to watch and why), rewrite C2M business logic, or change the logging framework itself.
Where the included scripts touch live systems they **read** — discovery, validation, and report are
read-only; remediation (log rotation/cleanup preview) runs **dry-run by default**. Any change to
production logging configuration, retention, or rotation goes through change control and is proven on
a non-production environment first.

## The deployment model
> Assess the current log landscape and health blind spots, configure the log inventory plus the
> health checks, early-warning signals, and SLOs, pilot the monitoring on a non-production
> environment, validate that logs are accessible and signals fire against a gate, then expand to
> production. The repeatable way: Assess, then Configure, then Pilot, then Validate, then Expand —
> with a documented rollback for every production change.
