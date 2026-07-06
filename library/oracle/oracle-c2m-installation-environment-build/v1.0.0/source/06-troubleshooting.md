# 6. Troubleshooting Guide — Oracle Customer to Meter (C2M) Installation & Multi-Environment Build

Use `OC2MINST-Discovery.sh` for host/prereq state, `OC2MINST-ScopeHelper.sh` to confirm you are on the
intended environment, `OC2MINST-Validation.py` (WLST) for the domain and application, and
`OC2MINST-Report.sql` for the schema. Apply fixes with `OC2MINST-Remediation.sh` — **dry-run by default**,
`-apply` only after review. Oracle-specific internals (exact installer prompts, the certification matrix,
patch/rollup numbers, gated My Oracle Support notes) are Oracle's; this guide gives the correct
diagnostic path and points to Oracle's C2M Installation Guide, C2M Database Administrator's Guide, OUAF
Server Administration Guide, and WebLogic 14.1.2 documentation for the details. Every version-specific
value is **"verify for your version."**

Work the stages in build order — stack, framework, product, database, domain, application — because a
failure at a later stage is usually caused by an unmet gate at an earlier one.

## Symptom: the framework or product installer fails or exits with errors
- **Likely causes:** uncertified Java/WebLogic; the log mount point does not exist; wrong mount-point
  ownership; `JAVA_HOME`/`PATH` not set for `cissys`; a worksheet value entered wrong.
- **Do:** run `OC2MINST-Discovery.sh -e your-env` and fix any CHECK first (Test 1/Test 2 in Testing).
  Confirm the log directory exists before installing. Confirm `java -version` matches the certified JDK.
  Re-run the installer from the completed worksheet.
- **Do not:** hand-edit `ENVIRON.INI` to "fix" a value — re-run `configureEnv.sh` then `initialSetup.sh`
  so the templates regenerate consistently (`OC2MINST-Remediation.sh -t templates`).

## Symptom: `ENVIRON.INI` missing, wrong, or config files look stale
- **Likely causes:** `initialSetup.sh` did not complete; a value was hand-edited; templates not rebuilt
  after a change.
- **Do:** confirm `$SPLEBASE/etc/ENVIRON.INI` exists and names the correct environment/DB
  (`OC2MINST-ScopeHelper.sh -e your-env`). Regenerate templates with
  `OC2MINST-Remediation.sh -e your-env -t templates` (dry-run, then `-apply`), which runs
  `initialSetup.sh -t` under the environment.
- **Escalate:** if ENVIRON.INI is structurally wrong, re-run `configureEnv.sh` to set the values, then
  `initialSetup.sh`, per the Installation Guide.

## Symptom: the database install (`OraDBI`) aborts or logs errors
- **Likely causes:** a tablespace named in `Storage.xml` does not exist; wrong DB Java (the DB installer
  may need a different JDK than the app tier); insufficient privileges; connectivity to `your-db` down.
- **Do:** with the DBA, confirm every tablespace in `Storage.xml` exists (a missing one aborts by
  design). Confirm the DB install step's Java requirement (**verify for your version** — it may differ
  from the app-tier Java). Read the logs in `Install-Upgrade/logs` — the schema load is not complete
  until they are clean. Re-run the DB install step.
- **Verify after:** `OC2MINST-Report.sql` — `CISADM` exists and owns objects, `CISUSER`/`CISREAD` exist,
  invalid-object count is 0 (or explained), installed version matches (Testing Test 3).

## Symptom: `AdminServer` or `c2m_server1` will not reach RUNNING
- **Likely causes:** a WebLogic port already in use on the host; `setUserOverride.sh` settings not
  incorporated into the domain start-up; memory arguments too small for C2M; a bad admin credential.
- **Do:** re-run `OC2MINST-Discovery.sh -e your-env -l your-ports` to confirm the ports are free.
  Confirm `$SPLEBASE/tools/examples/bin/setUserOverride.sh` is incorporated into the domain start-up and
  that memory is sized per Oracle's guidance. Read the server logs. Offer a controlled restart with
  `OC2MINST-Remediation.sh -e your-env -t restart` (dry-run, then `-apply`), then re-check with
  `OC2MINST-Validation.py`.
- **Escalate:** persistent FAILED/ADMIN state → follow Oracle's WebLogic 14.1.2 server-troubleshooting
  documentation with the server log's specific error.

## Symptom: the C2M application is deployed but not ACTIVE, or the login page will not load
- **Likely causes:** the EAR was not rebuilt after a change; the `cisusers` role was not granted online
  access on first start-up; the application-to-database data source is unhealthy.
- **Do:** confirm the application deployment state via `OC2MINST-Validation.py` (Testing Test 5). In the
  Administration Console, confirm the `cisusers` role grant. If a config change preceded this, rebuild the
  EAR (`initialSetup.sh`) and redeploy. Check app-to-DB connectivity (next symptom).

## Symptom: application cannot connect to the database (`CISUSER`)
- **Likely causes:** DB service/listener down or unreachable from the app tier; wrong `CISUSER`
  credentials; the data source not targeted to `c2m_server1`.
- **Do:** from the app host confirm listener reachability (`OC2MINST-Discovery.sh -d your-db-host`).
  Confirm the WebLogic data source is healthy and targeted to `c2m_server1`. Verify `CISUSER` credentials.
  Testing Test 6 is the pass/fail gate.

## Symptom: Test or Prod behaves differently from Dev
- **Likely causes:** build drift — a different port scheme, a hand-edited config, a rollup applied to one
  tier but not another, or object names that were not reused.
- **Do:** compare the `OC2MINST-Discovery.sh` baselines and `OC2MINST-Report.sql` output across the
  environments (Testing Test 7). Confirm the object names are identical and only host/port/DB differ.
  Confirm the same required rollups are applied in every tier. Reconcile before promoting workloads.

## Symptom: a command was almost run against the wrong environment
- **Likely causes:** multiple environments on shared infrastructure; ambiguous shell state.
- **Do:** always run `OC2MINST-ScopeHelper.sh -e your-env` first; for Production it refuses an
  OK-to-proceed unless you pass `-confirm C2MPRD`. Make this the habitual first step of any change.

## Symptom: the environment is green on first start but fails after a restart
- **Likely causes:** a manual runtime change that was never persisted to the built configuration; a
  start-up ordering or dependency problem.
- **Do:** run Testing Test 8 — `spl.sh -stop` then `-start` — and re-validate (Tests 4–7). Fold any
  manual fix back into the documented build (via `configureEnv.sh`/`initialSetup.sh`) so it survives a
  bounce. A build that does not come back cleanly is not done.

## When to escalate to Oracle / My Oracle Support
- Install/patch failures tied to the certification matrix, a required rollup, or a gated note.
- `OraDBI`/schema errors that persist after tablespace and Java prerequisites are confirmed.
- WebLogic server failures whose logs point to a product defect rather than configuration.
Gather the relevant logs (`Install-Upgrade/logs`, the WebLogic server logs, and the installer output)
and the exact release/version before opening the service request.

---
### Triage order
`ScopeHelper (right env?) -> Discovery (stack/ports/prereqs) -> framework/product install logs -> OraDBI logs + Report.sql (schema) -> Validation.py (domain + app) -> app-to-DB -> Remediation (dry-run -> apply) -> compare tiers -> restart test -> escalate to Oracle/MOS`
