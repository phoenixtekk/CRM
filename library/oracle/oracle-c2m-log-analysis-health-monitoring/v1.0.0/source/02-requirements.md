# 2. Requirements Guide — Oracle C2M Log Analysis & Health Monitoring (SLO Assurance)

Verify every requirement before building the log inventory, health checks, early-warning signals, or
SLOs. Each entry: Description, Why, Verify, Implement-if-missing. Category-wide prerequisites
(licensing, certified stack, environments, WLST/shell/SQL tooling, change control) are in
`global-requirements-oracle.md`.

## 2.1 A reachable C2M environment and product user
Description: A licensed C2M environment with its OUAF product home reachable, and the OS product user
that owns it (the account under which the online, batch, and service processes run), with the
environment sourced via `splenviron.sh -e your-env`.
Why: Every discovery and monitoring script needs the environment variables `splenviron.sh` sets —
`SPLEBASE` (install/log home), `SPLOUTPUT` (batch/application output logs), and the paths to the OUAF
utilities; without them the scripts cannot locate the logs.
Verify: As the product user, run `splenviron.sh -e your-env`, then run `OC2MLOG-Discovery.sh` — it
confirms the environment is sourced and `SPLEBASE`/`SPLOUTPUT` resolve.
Implement-if-missing: Obtain the product-user credentials and the environment name; confirm the OUAF
install is complete (`initialSetup`/`configureEnv` run) before proceeding.

## 2.2 OUAF application log access (`$SPLEBASE/logs/system`)
Description: Read access to the OUAF system logs under `$SPLEBASE/logs/system` — the `spl*.log` files
(and `spl_service.log`) that carry application-level errors, warnings, and service timings.
Why: The application-layer half of every health signal (error rate, exceptions, service timing) comes
from these logs; without access there is no application health view.
Verify: You can list and read `$SPLEBASE/logs/system` and see current `spl*.log` files; run
`OC2MLOG-Discovery.sh`, which inventories them (read-only).
Implement-if-missing: Grant the monitoring account read on the OUAF logs directory (or run as the
product user); confirm the logs are current (being written) per the version's Server Administration
Guide.

## 2.3 WebLogic server + domain log access (`$DOMAIN_HOME/servers/.../logs`)
Description: Read access to the WebLogic **server logs** (`$DOMAIN_HOME/servers/<server>/logs/<server>.log`)
and the **domain log** in the Administration Server's log directory, plus (optionally) WLST access to
read the logging configuration.
Why: The middleware half of the health signals — JVM/`OutOfMemoryError`, JDBC connection-pool
exhaustion, JMS, and stuck-thread warnings — lives in the WebLogic logs; these precede most container
outages.
Verify: You can read the managed-server logs and the domain log; run `OC2MLOG-Discovery.sh` (it
locates them from `DOMAIN_HOME`) and, if WLST access is granted, `OC2MLOG-Validation.py` reads the
logging config (read-only).
Implement-if-missing: Grant read on `$DOMAIN_HOME/servers/*/logs` and, for config checks, a
read-capable WebLogic user for WLST; confirm `DOMAIN_HOME` is known.

## 2.4 Batch / background-processing log access (`$SPLOUTPUT`)
Description: Read access to the thread pool worker batch logs in `$SPLOUTPUT` — the
`threadpoolworker.<threadpool>.<datetime>-tech.log` and `...-user.log` files that record batch
technical and business output.
Why: Batch failures and overruns — often the first sign of a data, integration, or connectivity
problem — show in these logs; a batch that starts failing is a leading indicator.
Verify: You can list `$SPLOUTPUT` and read recent `threadpoolworker.*` logs; `OC2MLOG-Discovery.sh`
inventories them (read-only).
Implement-if-missing: Confirm `SPLOUTPUT` is set and readable (grant read or run as the product user);
confirm batch logs are current for recent runs. File-name pattern per the OUAF Server Administration
Guide — verify for your version.

## 2.5 The health-signal set defined
Description: The named early-warning signals this solution standardizes — `C2M Health - Signals -
EarlyWarning`: error/exception rate, `OutOfMemoryError`/heap pressure, connection-pool exhaustion,
stuck-thread warnings, batch failures/overruns, and log-growth/disk — each with a documented threshold
and the log it is read from.
Why: A named, consistent signal set is what lets monitoring watch the same things in every
environment and turn raw log lines into early warning rather than after-the-fact forensics.
Verify: Each signal has a source log and a threshold; run `OC2MLOG-Validation.sh`, which checks that
the signal patterns are found (or cleanly absent) in the inventoried logs.
Implement-if-missing: Define the signal set and thresholds (see the Implementation Guide) from the
environment's own baseline; record them against `C2M Health - Signals - EarlyWarning`.

## 2.6 The SLO set defined and owned
Description: The service-level objectives this solution standardizes — `C2M SLO - Uptime - Standard`:
availability, batch-completion, error-rate, and log-freshness/coverage — each with a target, an error
budget, a measurement source (which log/signal), and an owner.
Why: SLOs turn health from "seems fine" into a measured target with an error budget you can watch burn;
without them there is nothing to track health *against*.
Verify: Each SLO has a target, source, and owner; run `OC2MLOG-Report.sh`, which computes the current
health/SLO view from the inventoried logs and signals.
Implement-if-missing: Set the SLO targets from the business's uptime commitments and assign owners;
record them against `C2M SLO - Uptime - Standard`.

## 2.7 Time synchronization and ECID correlation
Description: Synchronized clocks (NTP) across the OUAF, WebLogic, and database hosts, and the OUAF log
format's **ECID** (Execution Context ID) available in the log lines, so entries across the three
layers can be correlated for the same request or job.
Why: Early detection often needs the *chain* — an application error, its WebLogic entry, and its batch
entry; correlation by time and ECID only works if clocks agree and the ECID is present.
Verify: Confirm NTP is in sync across the hosts and that log lines carry the ECID field (per the OUAF
log format `<userid> <transactionid> <ECID> <date/time> ...`); `OC2MLOG-Validation.sh` samples a log
line and reports whether the ECID field is populated.
Implement-if-missing: Enable/verify NTP on all hosts; confirm the log format for your version includes
the ECID.

## 2.8 Log retention, rotation, and disk headroom
Description: Known **rotation** (size/time), **retention** (how many files kept), and **disk headroom**
for each log location — the OUAF `logs/system`, `$SPLOUTPUT`, and the WebLogic server/domain logs
(WebLogic's `LogFileMBean` controls file size and count).
Why: A log filesystem that fills takes the application down on its own, and logs that rotate away too
fast destroy the evidence needed for early detection; both are health risks in their own right.
Verify: You can state the rotation/retention and current disk usage per location; `OC2MLOG-Discovery.sh`
reports log-directory sizes and `OC2MLOG-Validation.sh` flags low headroom.
Implement-if-missing: Set WebLogic rotation via `LogFileMBean` (file min size, file count) and a
retention/cleanup policy for `$SPLOUTPUT` and `logs/system`; use `OC2MLOG-Remediation.sh` (dry-run) to
preview a safe cleanup/rotation.

## 2.9 A non-production pilot environment and change control
Description: A non-production C2M environment to build the inventory, signals, and SLOs and prove the
monitoring before touching production, plus change control and backups (any logging-config change to
WebLogic or OUAF) per the global requirements.
Why: Logging-config, rotation, and retention changes are production-impacting; the model is
Assess → Configure → Pilot → Validate → Expand with a documented rollback.
Verify: A non-production environment is available and a backup/rollback path for any logging-config
change is confirmed.
Implement-if-missing: Stand up or obtain the non-production environment and establish the backup and
change window before any production change.

---
## Checklist
- [ ] C2M environment reachable, product user, `splenviron.sh -e your-env` sources cleanly — `OC2MLOG-Discovery.sh`
- [ ] OUAF application logs readable — `$SPLEBASE/logs/system` (`spl*.log`)
- [ ] WebLogic server + domain logs readable — `$DOMAIN_HOME/servers/*/logs`
- [ ] Batch logs readable — `$SPLOUTPUT` (`threadpoolworker.*-tech/-user.log`)
- [ ] Health-signal set defined — `C2M Health - Signals - EarlyWarning`, `OC2MLOG-Validation.sh`
- [ ] SLO set defined and owned — `C2M SLO - Uptime - Standard`, `OC2MLOG-Report.sh`
- [ ] Time sync (NTP) + ECID present for correlation
- [ ] Rotation/retention/disk headroom known per log location
- [ ] Non-production pilot + change control and backups
