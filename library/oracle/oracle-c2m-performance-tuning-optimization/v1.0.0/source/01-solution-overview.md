# Solution Overview

Oracle Utilities **Customer to Meter (C2M)** runs on the **Oracle Utilities Application Framework
(OUAF)** and is deployed on **Oracle WebLogic Server 14c** over an **Oracle Database**. When C2M
"feels slow," the cause is almost never a single knob — it is a bottleneck somewhere in a stack of
dependent layers, and turning the wrong knob wastes an outage window and can make throughput worse.

This solution gives you a **measure-first tuning method**: instrument the stack, find the *real*
bottleneck with evidence, tune the one layer that is constraining you, then re-measure to prove the
gain — and do it on a non-production pilot before you touch production.

> **Version boundary.** Written for **C2M** on **OUAF** with **WebLogic Server 14c** (14.1.1) and an
> **Oracle Database**. Exact MBean paths, OUAF utility names, and default values vary by release —
> everything below is **cited or flagged "verify for your version."** Certain notes/patches are gated
> on **My Oracle Support (MOS)**; those are pointed to, not reproduced.

---

## The C2M performance model — four layers, top to bottom

Performance flows down a chain. A request (online transaction, web service, or a batch work unit)
enters WebLogic, is handled by a JVM, holds a database connection from a pool, and executes SQL.
Every layer can be the constraint. Tune **in dependency order** and only after you have measured
which layer is actually saturated.

| # | Layer | What it governs | Primary tuning artifacts |
|---|-------|-----------------|--------------------------|
| 1 | **JVM / GC** | The Java runtime every WebLogic node and every batch thread pool worker runs inside. Heap sizing and garbage-collection behavior set the ceiling for everything above it. | Heap (`-Xms`/`-Xmx`), GC collector + pause target (G1: `-XX:MaxGCPauseMillis`), metaspace, GC logging |
| 2 | **WebLogic pools** | How WebLogic dispatches work and lends out database connections: the **self-tuning thread pool** / **Work Managers**, and each **JDBC data source connection pool**. | Work Manager `min-threads-constraint` / `max-threads-constraint`; data source `Initial Capacity`, `Maximum Capacity`, `Test Connections on Reserve`, statement cache |
| 3 | **Batch throughput** | OUAF batch: how many **thread pool workers** run, how many **threads** a batch runs across, and how work is distributed. This is where nightly billing/meter volume lives. | Thread pool worker count and pool sizes (`threadpoolworker.sh -p`), per-batch thread count (`submitbatchREST.sh -c`), commit/`chunk` interval |
| 4 | **SQL / Database** | The queries C2M and its batches issue, their plans, indexes, and the database's own resource limits (sessions, CPU, I/O, undo). | AWR/ASH findings, execution plans, index/stat freshness, `processes`/`sessions`, connection-pool sizing back-pressure |

The layers interact. Undersized DB connection pools (layer 2) masquerade as slow SQL (layer 4);
GC pauses (layer 1) look like stuck WebLogic threads (layer 2); too many batch threads (layer 3)
exhaust the connection pool (layer 2) and overload the database (layer 4). **This is exactly why the
method is measure-first** — you diagnose before you tune.

---

## The measure-first method

Guessing is the enemy. The method is a loop, run once per bottleneck, always on a **non-production
pilot first** with change control and a rollback for production:

1. **Measure & baseline.** Capture a repeatable baseline of the whole stack under a representative
   workload — GC behavior, WebLogic thread-pool and connection-pool runtime metrics, batch elapsed
   times/throughput, and a database AWR/ASH snapshot. Record the numbers; you will be judged against
   them. `OC2MPERF-Discovery` collects the read-only baseline for you.
2. **Isolate the bottleneck.** Read the baseline to find the **one** saturated layer: GC time as a
   fraction of wall-clock, WebLogic `PendingUserRequestCount` / stuck/hogging threads, connection-pool
   `WaitingForConnectionCurrentCount`, batch thread saturation, or the top DB wait event. Do **not**
   tune more than one layer at a time.
3. **Tune the constraint.** Apply a **single, named, reversible** change to that layer only — a heap
   or GC setting, a Work Manager or data-source capacity, a batch thread count, or a SQL/index fix.
4. **Re-measure & validate.** Re-run the *same* workload and compare against the baseline. Accept the
   change only if it **moves the target metric past a defined gate** and does not regress another
   layer. Otherwise roll back.
5. **Expand.** Promote the validated change through the environments (Dev → Test → Prod) under change
   control, then repeat the loop for the *next* bottleneck.

This maps onto the standard Oracle-category deployment model — **Assess → Configure → Pilot →
Validate → Expand** — with explicit measured pass/fail gates and a documented rollback.

---

## What's in this solution

- **Requirements Guide** — what you need before you tune (monitoring/metrics access, environment and
  admin access, a representative workload profile, backups/change control), each with how to *verify*.
- **Tuning Method** — the ordered, hands-on procedure: baseline, isolate, tune JVM/GC → WebLogic
  thread & connection pools → batch thread pools → SQL/DB, then re-measure and validate.
- **5 automation scripts (WLST/Jython, shell, SQL)** — read-only discovery, read-only per-node
  validation, a read-only health/coverage report, a **dry-run-by-default** remediation helper, and a
  scope/target helper — authentic to C2M and WebLogic administration.
- **Testing & Troubleshooting Guides** with measured pass/fail gates, plus **Best Practices** for
  repeatable, evidence-based tuning.

## Who this is for

C2M / WebLogic administrators, OUAF technical operations staff, and the DBA and infrastructure teams
who own the environment. It assumes you can reach the **WebLogic Administration Console / WLST**, the
**OUAF product user shell**, and the **C2M database schema** — see the Requirements Guide.

## Outcome

A slow C2M environment turned into a **measured, optimized** one: JVM/GC, WebLogic pools, batch, and
SQL each tuned to the layer that was actually constraining you, every change proven against a baseline
on a pilot before it reaches production.
