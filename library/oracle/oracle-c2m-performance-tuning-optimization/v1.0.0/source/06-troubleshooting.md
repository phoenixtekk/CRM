# Troubleshooting Guide

Common tuning traps across the four layers, as **symptom → likely cause → what to do**. The recurring
theme: a symptom in one layer usually has its cause in another — measure before you tune.

> Run `OC2MPERF-Discovery` (read-only) whenever a symptom appears — nearly every entry below is
> diagnosed from the metrics it collects.

## Cross-cutting

**Symptom: "C2M is slow" but you don't know where.**
- **Cause:** No baseline; symptom pattern-matched instead of diagnosed.
- **Fix:** Capture the baseline (Step 1), then use the isolation table (Step 2) to find the one
  saturated layer. Do not change anything until a layer is isolated.

**Symptom: A tuning change "helped" but overall throughput didn't improve.**
- **Cause:** The bottleneck moved to the next layer (e.g. more batch threads now saturate the DB).
- **Fix:** Re-run `OC2MPERF-Validation` and check the **no-regression gate**. Tune the newly
  constrained layer; keep the earlier change only if it passed its own gate.

## JVM / GC

**Symptom: Periodic freezes / high response-time spikes; long GC pauses in the GC log.**
- **Cause:** Full-GC storms — undersized heap, metaspace pressure, or a mismatched collector.
- **Fix:** Set `-Xms = -Xmx`, size the heap from post-full-GC live set with headroom, size metaspace,
  and set a G1 pause target (`-XX:MaxGCPauseMillis`). Confirm RAM headroom so the heap is not swapped.
  **Verify GC flags for your JDK version.**

**Symptom: Heap grows to `-Xmx` and stays there; frequent full GCs.**
- **Cause:** Live set genuinely near the ceiling, or a leak.
- **Fix:** Re-baseline live set after a full GC; raise `-Xmx` only within RAM headroom. If it keeps
  climbing, capture a heap dump and involve app-dev — this is a leak, not a tuning problem.

## WebLogic threads / Work Managers

**Symptom: `PendingUserRequestCount` > 0, requests queue, but CPU and heap are idle.**
- **Cause:** Threads blocked **downstream** — usually a full connection pool or slow SQL — not a lack
  of threads.
- **Fix:** Check the JDBC pool (`WaitingForConnectionCurrentCount`) and top SQL first. Adding threads
  here only deepens the downstream queue.

**Symptom: `StuckThreadCount` / `HoggingThreadCount` rising.**
- **Cause:** Threads waiting on a long downstream operation (DB, connection reserve, external call).
- **Fix:** Find the wait's source and fix *that*. Adjust `StuckThreadMaxTime` only to tune detection,
  never to mask a real stall.

## JDBC connection pool

**Symptom: `WaitingForConnectionCurrentCount` > 0; `ActiveConnectionsHighCount` at `Maximum Capacity`.**
- **Cause:** Pool too small for the concurrency (often after raising batch threads).
- **Fix:** Raise `Maximum Capacity` (and `Initial Capacity` to match) **within DB session headroom** —
  confirm `processes`/`sessions` with the DBA first. If the DB can't take more sessions, reduce
  upstream concurrency instead.

**Symptom: First requests after idle are slow; connection errors after a brief DB blip.**
- **Cause:** Connections created on demand; stale connections handed out.
- **Fix:** Set `Initial Capacity = Maximum Capacity`; enable **Test Connections on Reserve** with a
  test frequency and a short trusted window.

**Symptom: High DB parse/CPU with repetitive statements.**
- **Cause:** No statement cache.
- **Fix:** Set an `LRU` **Statement Cache Size** sized to the app's distinct prepared statements.

## Batch throughput

**Symptom: A batch overruns its window; threads sit idle-waiting.**
- **Cause:** Threads starved of connections, blocked on row locks, or the job doesn't partition.
- **Fix:** Confirm the connection pool and DB headroom (layers 2 & 4) before adding threads. Only raise
  `submitbatchREST.sh -c` if the batch partitions cleanly and downstream capacity exists.

**Symptom: Raising thread count made batch *slower* or spiked DB waits.**
- **Cause:** Concurrency exceeded DB/connection capacity → contention, locking, or session exhaustion.
- **Fix:** Back the thread count down, size the connection pool and DB sessions for the intended
  concurrency, and re-test. Tune the commit/`chunk` interval — too small floods commits, too large
  lengthens locks/undo.

## SQL / Database

**Symptom: AWR shows a few statements dominating elapsed time.**
- **Cause:** Bad plan, stale/missing stats, or a missing index.
- **Fix:** `DBMS_XPLAN.DISPLAY_CURSOR` the statement, refresh stats (`DBMS_STATS`), add/repair an
  index — **only on custom/CM objects**; product-schema changes are vendor-governed (confirm via
  support/MOS).

**Symptom: Top waits are session/process related; new sessions fail.**
- **Cause:** `processes`/`sessions` exhausted — often from oversized pools or too many batch threads.
- **Fix:** Right-size pools and batch concurrency to the DB's session headroom, or raise
  `processes`/`sessions` with the DBA (requires a DB restart).

## Escalation

- **MOS-gated notes/patches:** where a fix references a My Oracle Support note or patch, open a service
  request — this solution points to gated content, it does not reproduce it.
- **Product-schema or product-code issues:** engage Oracle support; do not alter product-owned objects.
- **Suspected memory leaks / defects:** capture heap/thread dumps and the GC log and involve
  application-development and support.
