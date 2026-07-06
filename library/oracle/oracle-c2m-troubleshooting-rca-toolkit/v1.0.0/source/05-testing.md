# 5. Testing Guide — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

Two things get tested here: first that the **toolkit itself works** in your environment (run these on
a healthy day so the scripts are proven before an incident), and second that a **restore is complete**
(run the relevant checks after any fix). Each test confirms one layer-isolation check returns the
expected reading. Source the environment first: `splenviron.sh -e your-env`; WLST connects to the
Admin Server.

## Test 1 — Discovery collects a clean snapshot
Do: Run `OC2MRCA-Discovery.sh` on a healthy environment.
Expected: It reports environment sourced OK, resolves the domain and product log paths, tails the
standard logs, and emits a `C2M RCA - Diagnostic Snapshot` — with no error. Store it as the baseline.

## Test 2 — Validation reads every layer's state
Do: Run `OC2MRCA-Validation.py` under WLST (`java weblogic.WLST OC2MRCA-Validation.py`).
Expected: For each layer it prints a reading: server states (`RUNNING`), thread-pool health
(`ok`, stuck/hogging counts), JDBC data-source/pool state, JMS destination consumer/pending counts,
and certificate expiry. On a healthy environment every layer reads PASS.

## Test 3 — Report returns the database diagnostic sections
Do: Run `OC2MRCA-Report.sql` via SQL*Plus/SQLcl against the schema.
Expected: All sections return — batch run status, in-flight/overdue threads, blocking sessions,
tablespace/temp pressure, and any error rows. On a healthy day: no blocking, no overdue thread, no
error rows, tablespace within threshold.

## Test 4 — A symptom routes to the right branch
Do: For a known past incident (or a reproduced one on non-production), run
`OC2MRCA-ScopeHelper.sh --symptom your-symptom`.
Expected: It bounds the incident to the correct tier/servers and selects the matching Diagnostic
Playbook branch and target set — the tree points at the layer that actually failed.

## Test 5 — The layer-isolation ladder isolates a seeded fault (non-production)
Do: On non-production, seed one fault per layer in turn (stop the listener = network/DB; suspend a data
source = auth; drive threads to stuck = resource; misconfigure one IWS service = application) and walk
the branch.
Expected: Each seeded fault is caught at the correct rung — the ladder stops descending at the failing
layer and names it, without false-blaming a lower layer.

## Test 6 — Remediation previews only (dry-run safety)
Do: Run `OC2MRCA-Remediation.sh` with no apply flag.
Expected: It prints the exact restore action it *would* take (orderly restart / data-source re-sync /
JMS re-sync) and **changes nothing** — exit without side effects. It never restarts a live server by
itself.

## Test 7 — A restore validates clean
Do: After applying a fix (non-production, or production in a change window), re-run the failed layer's
check (`OC2MRCA-Validation.py` / `OC2MRCA-Report.sql`) and exercise the symptom under representative
load.
Expected: The previously failing layer now reads PASS, dependent layers still PASS, and the symptom
does not reproduce. This is the restore gate.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Toolkit ready | Tests 1-4 pass on a healthy environment: discovery snapshots, validation reads every layer, report returns all sections, scope routes correctly — and a baseline is stored |
| Method proven | Test 5 passes: each seeded per-layer fault is isolated at the correct rung on non-production |
| Restore complete | Tests 6-7 pass: remediation previews safely, and after a fix the failed layer reads PASS with the symptom gone under load, dependent layers still PASS |
