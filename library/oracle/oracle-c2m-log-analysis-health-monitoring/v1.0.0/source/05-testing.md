# 5. Testing Guide — Oracle C2M Log Analysis & Health Monitoring (SLO Assurance)

Run after the pilot monitoring pass on the non-production environment (Implementation Step 8) and again
after production expansion. Each test confirms one part of the log-analysis and health-monitoring
chain works end to end — that it not only *collects* logs but *detects* problems and *measures* health
against SLOs. Source the environment first: `splenviron.sh -e your-env`.

## Test 1 — Every log layer is inventoried and readable
Do: Run `OC2MLOG-Discovery.sh`.
Expected: The inventory lists OUAF application logs (`$SPLEBASE/logs/system/spl*.log`), WebLogic server
and domain logs (from `DOMAIN_HOME`), and batch logs (`$SPLOUTPUT/threadpoolworker.*`) — each readable,
with a current file present. No layer missing or unreadable (the `C2M Log - Inventory - All Layers`
set).

## Test 2 — Logs are current (collection is live)
Do: Check the newest file's timestamp per layer in the discovery output; run `OC2MLOG-Validation.sh`.
Expected: Each in-scope log has been written recently (is current) — no log that stopped being written.
A stale log is a blind spot and fails the collection-health check.

## Test 3 — Health checks run and report
Do: Run `OC2MLOG-Validation.sh` (the `C2M Health - Checks - Standard` set).
Expected: Application, container, batch, and collection health checks each run and report PASS/FAIL —
`spl*.log` current and within error threshold, WebLogic logs free of OOM/pool-exhaustion/stuck-thread,
recent batch runs completed, all logs current with disk headroom.

## Test 4 — Each early-warning signal fires on a known trigger
Do: In non-production, trigger a safe, known instance of each signal (e.g. generate test `ERROR`
lines; run a batch known to fail); re-run `OC2MLOG-Validation.sh` and `OC2MLOG-Report.sh`.
Expected: The corresponding signal in `C2M Health - Signals - EarlyWarning` fires and appears in the
report — error-rate, batch-failure (and, where safely reproducible, pool/stuck/OOM) detected. The
monitoring detects, it does not merely store.

## Test 5 — Signals are clean when they should be
Do: On a healthy run with no trigger, run `OC2MLOG-Validation.sh`.
Expected: No signal fires falsely — a healthy environment reports all-clear. (A signal that fires
constantly on a healthy system has its threshold set below baseline; re-tune per Implementation
Step 4.)

## Test 6 — Cross-layer correlation works
Do: Take a recent application error's ECID from `spl*.log` and find the matching WebLogic (and, if
applicable, batch) entry by ECID/time.
Expected: The ECID ties the entries across layers — the application error, its container entry, and any
batch entry line up (Requirement 2.7). Correlation is possible, not blocked by clock skew or a missing
ECID field.

## Test 7 — The health/SLO report renders with error budgets
Do: Run `OC2MLOG-Report.sh` (the `C2M Health - Report - Daily` view).
Expected: The report shows each health check's result, which signals fired, and each SLO's status and
**remaining error budget** — availability, batch-completion, error-rate, and log-freshness/coverage.
Health is a number and a trend, not an opinion.

## Test 8 — Remediation preview is safe (dry-run)
Do: Run `OC2MLOG-Remediation.sh` with no apply flag against a log location needing rotation/cleanup.
Expected: It prints the exact rotation/cleanup or config change it *would* make and changes nothing —
safe to run anywhere. (Applying is a change-window action with `--apply`.)

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-8 pass on non-production: all layers inventoried, current, and readable; checks run; every signal fires on a known trigger and is clean otherwise; ECID correlation works; the report renders SLOs with error budgets; remediation dry-run is safe |
| Expand pass | Tests 1-3, 5, 7 pass in production after the first monitoring cadence, and Test 4 (signals fire) plus Test 8 (safe remediation) are verified in non-production before go-live |
