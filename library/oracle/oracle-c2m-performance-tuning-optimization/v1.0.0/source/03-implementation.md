# Tuning Method

This is the hands-on procedure. It is a **measure → isolate → tune → re-measure → validate** loop, run
**once per bottleneck**, always on a **non-production pilot first**, with a **single, named, reversible**
change per pass and a rollback ready for production. Names of tuning artifacts are given exactly; where a
value or path is version-specific it is flagged **"verify for your version."**

> **Golden rule.** Change **one layer at a time**, re-measure against the **same** workload, and keep or
> roll back based on a **measured gate** (see the Testing Guide). Never tune more than one knob per pass.

---

## Step 0 — Prepare (Assess)

1. Confirm the Requirements Guide is satisfied — metrics access, environment access, a repeatable
   workload, matched versions, backups/change control.
2. Record scope and rollback targets with `OC2MPERF-ScopeHelper` (which nodes, which data sources,
   which batch controls, current values to restore to).
3. **Back up** the domain config, the OUAF config files you may touch
   (`threadpoolworker.properties`, JDBC/data-source and JVM settings), and the database.

---

## Step 1 — Measure & baseline

Capture a repeatable baseline of the **whole stack** under the representative workload. Run
`OC2MPERF-Discovery` (read-only) to collect it, and enable GC logging so the JVM layer is visible.

- **JVM / GC.** Enable GC logging on each WebLogic node and each OUAF thread pool worker JVM. On a
  modern JDK (JDK 11/17 — **verify for your version**) use unified logging:
  `-Xlog:gc*:file=/path/gc-%p.log:time,uptime,level,tags`. On JDK 8 (**verify**):
  `-verbose:gc -Xloggc:/path/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps`. Add these to the
  node's Java options (`setUserOverrides.sh` / the managed server's **Server Start → Arguments**, or
  the OUAF worker's `-J` options). Record heap size, collector, and steady-state GC pause and GC-time
  fraction.
- **WebLogic pools.** Read the runtime MBeans (via WLST/JMX; `OC2MPERF-Discovery` does this read-only):
  - **Thread pool** (`ServerRuntime → ThreadPoolRuntime`): `ExecuteThreadTotalCount`,
    `HoggingThreadCount`, `StuckThreadCount`, `PendingUserRequestCount`, `Throughput`,
    `SharedCapacityForWorkManagers`.
  - **JDBC data source** (`ServerRuntime → JDBCServiceRuntime → JDBCDataSourceRuntimeMBeans`):
    `ActiveConnectionsCurrentCount`, `ActiveConnectionsHighCount`, `WaitingForConnectionCurrentCount`,
    `WaitingForConnectionHighCount`, `ConnectionDelayTime`, `CurrCapacity`, `NumUnavailable`.
- **Batch.** Capture elapsed time and throughput for the representative batch control(s) from the
  Batch Run Tree / batch run tables, or the JMX batch client (`jmxbatchclient.sh -s` for a summary),
  along with the current thread pool worker layout and per-batch thread count.
- **Database.** Take an **AWR** snapshot spanning the workload (`awrrpt.sql`) — or query `V$` views /
  Statspack if the Diagnostics Pack is not licensed (**verify licensing**). Record the top wait events,
  DB CPU, and top SQL by elapsed time.

**Write the numbers down.** This baseline is the gate every later change is judged against.

---

## Step 2 — Isolate the bottleneck

Read the baseline and identify the **one** saturated layer. Typical signatures:

| Signature in the baseline | Constrained layer | Go to |
|---|---|---|
| GC time a high fraction of wall-clock; long/ frequent pauses; heap near `-Xmx` after full GC | **JVM / GC** | Step 3a |
| `PendingUserRequestCount` persistently > 0; `HoggingThreadCount` / `StuckThreadCount` rising; throughput flat while requests queue | **WebLogic threads / Work Managers** | Step 3b |
| `WaitingForConnectionCurrentCount` > 0; `ActiveConnectionsHighCount` at `Maximum Capacity`; `ConnectionDelayTime` high | **JDBC connection pool** | Step 3c |
| Batch elapsed dominated by one job; threads idle waiting; window overruns | **Batch throughput** | Step 3d |
| AWR top waits are I/O / row-lock / library-cache; a few SQL statements dominate elapsed | **SQL / Database** | Step 3e |

If two layers look saturated, tune the **lower** one first (a fix there often relieves the layer above)
and re-measure before touching the other.

---

## Step 3 — Tune the constraint (one layer, one change)

### 3a — JVM / GC

1. **Right-size the heap.** Set `-Xms` equal to `-Xmx` to avoid runtime heap resizing pauses; size
   `-Xmx` from the baseline (post-full-GC live-set with headroom). Confirm the node has RAM headroom so
   the heap is not swapped.
2. **Choose/tune the collector.** On JDK 11/17, **G1GC** is the default (**verify for your version**);
   set a pause target with `-XX:MaxGCPauseMillis` rather than hand-tuning generations. Avoid stacking
   contradictory flags. Size **metaspace** (`-XX:MetaspaceSize` / `-XX:MaxMetaspaceSize`) from the
   baseline to stop metaspace-driven full GCs.
3. Keep GC logging on so Step 4 can compare pause distribution and GC-time fraction.

Apply the same discipline to **OUAF thread pool worker** JVMs (their heap/GC is set in the worker's
Java options), not just WebLogic managed servers.

> Reference: Oracle WebLogic Server 14.1.1 **Tuning Performance** guide; JDK GC tuning guide for your
> JDK version. **Verify default collector and flag syntax for your JDK.**

### 3b — WebLogic threads / Work Managers

WebLogic 9.0+ uses a **self-tuning** thread pool — you do **not** set a fixed thread count. Instead,
shape it with **Work Managers** and constraints:

1. Confirm the queue is genuinely thread-starved (pending requests with CPU/heap headroom), not blocked
   downstream (a full connection pool or slow SQL looks identical — rule those out first).
2. Define a **Work Manager** for the C2M application (or module) and, where justified, a
   `min-threads-constraint` (guarantee threads for a critical path) and/or `max-threads-constraint`
   (cap a component so it cannot starve others). Set these via the Administration Console or WLST.
3. Investigate **stuck/hogging threads** at the source — a rising `StuckThreadCount` usually means a
   downstream wait (DB/connection pool), not a need for more threads. Tune `StuckThreadMaxTime` only to
   change *detection*, not to mask a real stall.

> Reference: WebLogic 14.1.1 "Using Work Managers to Optimize Scheduled Work" and the Tuning
> Performance guide. The self-tuning pool's max is governed by `SelfTuningThreadPoolSizeMax`
> (default **400**; **verify for your version**).

### 3c — JDBC connection pool

Tune each C2M data source from its runtime evidence:

1. **Capacity.** Raise `Maximum Capacity` to clear `WaitingForConnectionCurrentCount`, and set
   `Initial Capacity` equal to `Maximum Capacity` so connections are pre-created (avoids first-use
   latency). **But** cap it against the database's `sessions`/`processes` headroom — confirm with the
   DBA before raising. An over-large pool moves the bottleneck to the database.
2. **Validation.** Enable **Test Connections on Reserve** with a **Test Frequency** and a short trusted
   window so healthy connections skip the test; this trades a little overhead for reliability under
   partial DB outages.
3. **Statement cache.** Set a **Statement Cache Size** (type `LRU`) sized to the application's distinct
   prepared statements to cut parse/CPU on the database.
4. **Shrinking / timeouts.** Tune **Shrink Frequency**, **Connection Reserve Timeout**, and
   **Inactive Connection Timeout** so the pool does not thrash open/close under bursty load.

> Reference: WebLogic 14.1.1 "Tuning Data Source Connection Pools." **Verify attribute defaults for
> your version.**

### 3d — Batch throughput (OUAF thread pool workers)

Batch is tuned at the OUAF/OS layer, not the WebLogic console:

1. **Thread pool worker layout.** Size the named thread pools with
   `threadpoolworker.sh -p DEFAULT=<n>,<POOL>=<n>` (or configure via `bedit.sh`), matching pool sizes
   to CPU cores available to the worker JVMs. Distribute workers across nodes for volume batches
   (CLUSTERED mode); use THIN mode only for isolated single-JVM runs.
2. **Per-batch threads.** Set the thread count per batch control with `submitbatchREST.sh -c <threads>`
   (the modern submitter; `submitjob.sh -c` is legacy). More threads only help if the batch partitions
   cleanly and the DB/connection pool can absorb the extra concurrency.
3. **Commit interval / chunking.** Tune the batch's commit (`chunk`) interval — too small floods the DB
   with commits, too large lengthens locks and undo. Set per the batch control's guidance.
4. **Balance against layers 2 and 4.** Every added batch thread consumes a JDBC connection and a DB
   session. Confirm the connection pool (Step 3c) and DB `processes`/`sessions` (Step 3e) can carry the
   new concurrency **before** raising thread counts.

> Reference: OUAF Server Administration Guide — Batch Server Configuration, `threadpoolworker.sh`,
> `submitbatchREST.sh`, `bedit.sh`. Optimal thread counts are workload- and data-specific — **verify
> for your batches**. Some batch-tuning notes are **MOS-gated**; they are pointed to, not reproduced.

### 3e — SQL / Database

1. From the AWR/ASH top-SQL and top-wait findings, take the **highest-elapsed** statement(s) first.
2. Get the **execution plan** (`DBMS_XPLAN.DISPLAY_CURSOR`), check for stale/missing **statistics**
   (`DBMS_STATS`) and missing/unusable **indexes**, and confirm the plan is not regressed.
3. Apply the **narrowest** fix — refresh stats, add/repair an index, or fix a plan — never a schema
   change to product-owned objects without vendor guidance (custom/CM objects only).
4. Confirm **database capacity** headroom used by the pools and batch: `processes`, `sessions`, undo,
   temp, and CPU. Raising batch threads or pool capacity is safe only within this headroom.

> Product-schema changes to C2M objects are vendor-governed — **confirm with support/MOS** before
> altering product tables or indexes. Do not invent index changes on product objects.

---

## Step 4 — Re-measure & validate

Re-run the **same** workload with `OC2MPERF-Validation` (read-only) and compare against the Step 1
baseline:

- Did the **target metric** cross its **gate** (Testing Guide)? e.g. GC-time fraction down,
  `WaitingForConnectionCurrentCount` at zero, batch elapsed reduced, top-SQL elapsed reduced.
- Did any **other** layer regress? (More batch threads must not create connection waits or DB
  saturation; a bigger heap must not increase pause time past target.)

**Keep** the change only if it passes the gate with no regression; otherwise **roll back** to the
recorded value and try a different hypothesis.

---

## Step 5 — Expand (promote & repeat)

1. Promote the validated change **Dev → Test → Prod** under change control, re-measuring at each stop.
2. Update the recorded baseline to the new steady state.
3. Return to **Step 2** for the next bottleneck. Stop when every layer meets its service target under
   the representative workload.

Generate an evidence pack for sign-off with `OC2MPERF-Report` (read-only) — baseline vs. current,
per-layer, with the gate outcomes.
