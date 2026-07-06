# 7. Best Practices — Oracle C2M Log Analysis & Health Monitoring (SLO Assurance)

## Log hygiene
- Inventory every log once and keep it current. Maintain `C2M Log - Inventory - All Layers` — OUAF
  (`$SPLEBASE/logs/system`), WebLogic server/domain (`$DOMAIN_HOME/servers/*/logs`), and batch
  (`$SPLOUTPUT/threadpoolworker.*`) — with each log's path, owner, and retention. A log you did not
  know existed is a blind spot; an unknown log is an unmonitored one.
- Rotate before the filesystem fills, retain long enough to investigate. Set WebLogic rotation via
  `LogFileMBean` (file min size and file count) and a size/time rotation plus retention policy for
  `$SPLOUTPUT` and `logs/system`. A full log filesystem takes the application down on its own; logs
  that rotate away too fast destroy the evidence you need for early detection — balance the two
  deliberately.
- Never let cleanup be ad-hoc. Use `OC2MLOG-Remediation.sh` (dry-run by default) to preview a rotation
  or cleanup and apply it only in a change window — deleting the wrong log or truncating an active one
  is its own incident.
- Keep the ECID and NTP so logs correlate. Ensure the OUAF log format carries the **ECID** and that
  NTP keeps the OUAF, WebLogic, and database hosts in step — early detection needs the *chain* across
  layers, and correlation breaks on clock skew or a missing ECID field.
- Standardize log paths and format across environments. Same locations and format in Dev, Test, and
  Production so the same discovery, validation, and report scripts run everywhere unchanged.

## Early detection
- Watch leading indicators, not just the outage. Define `C2M Health - Signals - EarlyWarning` on the
  signals that *precede* downtime — error-rate rising, `OutOfMemoryError`, connection-pool exhaustion,
  stuck-thread warnings, batch failures — so you intervene before the business feels it.
- Set thresholds from a measured baseline. Measure normal first (Implementation Step 1), then set each
  signal's trip point above it. A threshold guessed too low fires constantly and gets ignored; too high
  never fires — both are as bad as no monitoring.
- Treat `OutOfMemoryError` and pool exhaustion as top-priority signals. An OOM means a JVM is (or is
  about to be) down; a filling connection pool degrades the whole application before it fails. These
  earn the fastest response.
- Correlate across layers before concluding. An application error, its WebLogic entry, and its batch
  entry are one event — use the ECID to see the whole chain rather than fixing a symptom in one layer.
- Alert on the signal, review the trend. Fire an alert when a signal trips, but also review the
  health report's trend — a slowly rising error rate or a steadily burning error budget is a warning
  even before any single threshold trips.

## SLO tracking
- Track health against explicit SLOs with error budgets. Define `C2M SLO - Uptime - Standard`
  (availability, batch-completion, error-rate, log-freshness/coverage), each with a target, a
  measurement source, and an owner — so "how healthy is C2M?" is a number and a trend, not an opinion.
- Watch the error budget burn, not only the breach. A budget burning faster than the window allows is
  an early warning in itself; act on the burn rate before the SLO is missed.
- Make coverage an SLO too. A log that stopped being collected is a blind spot — track
  log-freshness/coverage so a monitoring gap is caught like any other health problem.
- Own every SLO. Each SLO has a named owner and a review cadence; an SLO nobody owns is not tracked.

## Operating discipline
- Keep the health report a standing daily view. Run `OC2MLOG-Report.sh` (`C2M Health - Report - Daily`)
  every day so signals that fired and budgets burning down are seen in operations, not after an outage.
- Prove monitoring on a pilot before you scale. Confirm on non-production that signals fire on a known
  trigger and the report renders SLOs (the pilot gate) before extending to production.
- Change logging config under change control only. Back up any WebLogic/OUAF logging-config change,
  prove it on non-production first, and keep a documented rollback — rotation and retention changes are
  production-impacting.
- Complement, don't duplicate, an APM platform. Where an enterprise monitoring/APM tool exists, this
  solution defines *what* to watch and *why* (the signals and SLOs) and feeds it — it does not replace
  it.
- Point to MOS for product defects. If a signal keeps firing after the config is sound, consult the
  version's My Oracle Support notes and open a service request — gated content is pointed to, not
  reproduced.
