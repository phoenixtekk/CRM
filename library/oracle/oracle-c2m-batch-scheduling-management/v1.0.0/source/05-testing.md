# 5. Testing Guide — Oracle C2M Batch Scheduling & Thread-Pool Management

Run after the pilot cycle on the non-production environment (Implementation Step 8) and again after
production expansion. Each test confirms one part of the configured batch cycle works end to end.
Source the environment first: `splenviron.sh -e your-env`.

## Test 1 — Workers advertise the standard pools
Do: On each worker node, confirm the pools are offered; run `OC2MBATCH-Validation.sh`.
Expected: Every node advertises `DEFAULT`, `ONLINE`, and `BILLING` (the `C2M Worker - Node -
Threadpools` set) with the expected thread counts — no node missing a pool.

## Test 2 — A batch control submits into the right pool
Do: Submit a representative light control and the heavy billing control; observe with
`jmxbatchclient.sh -j your-jmx-url -d`.
Expected: Threads for the heavy control run in `BILLING`, light control in `ONLINE`/`DEFAULT` — heavy
batch is not sharing the online pool.

## Test 3 — The nightly schedule fires
Do: Let `C2M Schedule - Nightly - Batch Cycle` trigger (or trigger it manually via the DBMS Job /
enterprise scheduler).
Expected: The cycle starts on schedule and the batch controls submit in the defined order.

## Test 4 — Dependencies are honored
Do: Run the cycle through `C2M Chain - Nightly - Dependencies`; inspect run status with
`OC2MBATCH-Report.sql`.
Expected: Each dependent control starts only after its predecessor completed successfully (for example
bill completion after billing `SUCCEEDED`); no dependent control ran early on a failed predecessor.

## Test 5 — Throughput and completion
Do: Run the full cycle; capture `OC2MBATCH-Report.sql`.
Expected: Every in-scope batch control completes within the window; per-thread completion and
records/sec are recorded; no thread ended in error.

## Test 6 — No stuck threads or backlog
Do: During and after the run, check `jmxbatchclient.sh -j your-jmx-url -s` and `OC2MBATCH-Report.sql`.
Expected: No thread is stuck active past its expected duration; the Batch Job Submission backlog drains
to zero after the cycle; `C2M Monitor - Batch - Run Status` shows all-complete.

## Test 7 — Live-thread control works
Do: On a safe, cancellable test run, use `jmxbatchclient.sh -j your-jmx-url -f pattern -c` to cancel a
matching thread (non-production only).
Expected: The targeted thread cancels cleanly and the worker keeps running — operations can control a
runaway thread without bouncing the node.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 pass on non-production: pools advertised, schedule fires, dependencies honored, cycle completes in-window, no stuck threads/backlog |
| Expand pass | Tests 1-6 pass in production after the first cycle, and Test 7 (live-thread control) is verified in non-production before go-live |
