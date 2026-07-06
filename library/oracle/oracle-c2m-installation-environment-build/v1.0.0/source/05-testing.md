# 5. Testing Guide — Oracle Customer to Meter (C2M) Installation & Multi-Environment Build

Run these tests after each environment is built (Installation Guide Steps 1–5) and again after any
restart or change, **per environment** — `C2MDEV` and `C2MTST` must both pass before `C2MPRD` is built.
Each test states what it proves, how to run it, and an explicit **pass / fail** gate. The read-only
scripts (`OC2MINST-Discovery.sh`, `OC2MINST-Validation.py`, `OC2MINST-Report.sql`) do the checking;
nothing here changes the environment.

Use `OC2MINST-ScopeHelper.sh` first to confirm you are targeting the intended environment
(`$SPLENVIRON`, `$SPLEBASE`, `c2m_domain`, and DB service) so a test never runs against the wrong tier.

## Test 1 — Certified stack present (Assess gate)
- **Proves:** the host runs a certified OS/Java/WebLogic/Database combination for the release.
- **Run:** `OC2MINST-Discovery.sh` and compare `java -version`, the WebLogic Home version, and the DB
  version to the certification matrix for your release.
- **Pass:** all four match a certified combination. **Fail:** any component off the matrix — stop and
  align the stack before continuing (an uncertified stack is unsupported).

## Test 2 — OUAF environment defined correctly
- **Proves:** the framework/product install produced a valid environment.
- **Run:** confirm `$SPLEBASE/etc/ENVIRON.INI` exists and names the correct `$SPLENVIRON`
  (`C2MDEV`/`C2MTST`/`C2MPRD`), mount points, and database; confirm `$SPLEBASE` and `$SPLOUTPUT` are
  populated. `OC2MINST-ScopeHelper.sh` resolves and reports these for the environment.
- **Pass:** ENVIRON.INI present and correct, directories populated, no build errors in the install logs.
  **Fail:** missing/incorrect ENVIRON.INI or empty `$SPLEBASE` — re-run `configureEnv.sh` +
  `initialSetup.sh` per the Installation Guide.

## Test 3 — Database schema installed and owned by CISADM
- **Proves:** the schema loaded over the `Storage.xml` tablespaces and the accounts exist.
- **Run:** `OC2MINST-Report.sql` as a read-only user against the schema; confirm `CISADM` owns the
  expected objects, `CISUSER` and `CISREAD` exist, and the installed release/version row matches the
  intended level. Confirm the `OraDBI` logs in `Install-Upgrade/logs` were clean.
- **Pass:** accounts present, `CISADM` owns the C2M objects, version matches, logs clean. **Fail:**
  missing objects/accounts or version mismatch — review the `OraDBI` logs and re-run the DB install step
  with the DBA.

## Test 4 — WebLogic domain healthy
- **Proves:** the `c2m_domain` domain and its servers are up.
- **Run:** `OC2MINST-Validation.py` via WLST against the domain; confirm `AdminServer` and `c2m_server1`
  are **RUNNING** (not ADMIN/STANDBY/FAILED). Cross-check in the Administration Console.
- **Pass:** both servers RUNNING with no health warnings. **Fail:** a server not RUNNING — check the
  server logs and the incorporated `setUserOverride.sh`/memory settings; `OC2MINST-Remediation.sh`
  (dry-run) will propose a safe restart.

## Test 5 — C2M application and IWS deployed and active
- **Proves:** the application is deployed and serving.
- **Run:** confirm via WLST/console that the C2M application and inbound web services are **ACTIVE** on
  `c2m_server1`; load the online login page at `http://your-host:your-port/` and confirm it renders.
- **Pass:** application ACTIVE and login page reachable. **Fail:** application not ACTIVE or page
  unreachable — check deployment state, the `cisusers` role grant, and app-to-DB connectivity.

## Test 6 — Application-to-database connectivity
- **Proves:** the running application reaches its schema as `CISUSER`.
- **Run:** authenticate to the online login page; confirm no data-source/connection errors in the
  managed-server log; confirm the WebLogic data source targeting `c2m_server1` is healthy.
- **Pass:** login succeeds and the data source is healthy. **Fail:** connection errors — verify the DB
  service, listener reachability, and `CISUSER` credentials.

## Test 7 — Build report matches the expected baseline
- **Proves:** the environment matches its intended definition and (for Test/Prod) matches Dev
  structurally.
- **Run:** combine the `OC2MINST-Discovery.sh` baseline (stack versions, ports), `OC2MINST-Validation.py`
  (domain + application state), and `OC2MINST-Report.sql` (schema state) into the build report; compare
  to the `Build Baseline – your-env – Assess` and to Dev's report.
- **Pass:** report matches the expected baseline; Test/Prod differ from Dev only in host/port/DB values.
  **Fail:** structural drift — reconcile before promoting workloads.

## Test 8 — Survives a clean stop/start (reproducibility gate)
- **Proves:** the build is stable, not just green on first start.
- **Run:** `spl.sh -stop` then `spl.sh -start` for the environment; re-run Tests 4–7.
- **Pass:** the environment comes back and all checks pass after the bounce. **Fail:** it does not come
  back cleanly — resolve before declaring the environment done or building the next tier.

---
### Test summary
| # | Test | Pass gate |
|---|---|---|
| 1 | Certified stack | OS/Java/WebLogic/DB all on the matrix |
| 2 | OUAF environment | ENVIRON.INI correct, `$SPLEBASE` populated |
| 3 | DB schema | `CISADM` owns objects; `CISUSER`/`CISREAD` exist; version matches; clean logs |
| 4 | WebLogic domain | `AdminServer` + `c2m_server1` RUNNING |
| 5 | Application + IWS | C2M ACTIVE; login page renders |
| 6 | App-to-DB | login works; data source healthy |
| 7 | Build report | matches baseline; Test/Prod ≈ Dev structurally |
| 8 | Stop/start | environment returns; Tests 4–7 still pass |

**Overall pass:** all eight pass for `C2MDEV` and `C2MTST` before `C2MPRD` is built, and all eight pass
for `C2MPRD` inside its change window.
