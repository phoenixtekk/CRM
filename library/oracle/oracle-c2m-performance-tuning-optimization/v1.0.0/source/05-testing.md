# Testing Guide — Measured Gates

Tuning is only "done" when it is **proven**. Every change is judged against a **measured pass/fail
gate** derived from the Step 1 baseline, re-measured on the **same** workload, on the **pilot first**.
A change that does not pass its gate — or that passes but regresses another layer — is **rolled back**.

> **Comparison rule.** Baseline and re-measure must use the identical workload (same data volume,
> concurrency, batch parameters). Use `OC2MPERF-Discovery` for the baseline and `OC2MPERF-Validation`
> for the re-measure so the two captures are comparable, then `OC2MPERF-Report` for the evidence pack.

## Gate targets are relative, not absolute

There is no universal "good" heap size or thread count. The gate is a **relative improvement against
your own baseline** with **no regression elsewhere**. Set the target percentages with your
stakeholders from the workload's success criteria; the tables below give the metric and the direction.

---

## Layer gates

### JVM / GC

| Metric (from GC logs) | Pass condition |
|---|---|
| GC time as fraction of wall-clock | **Decreased** vs. baseline and below your target (commonly a low single-digit %) |
| Steady-state pause time | Within `-XX:MaxGCPauseMillis` target; no sustained full-GC storms |
| Post-full-GC live heap | Comfortably below `-Xmx` (headroom remains) |

### WebLogic threads / Work Managers

| Metric (`ThreadPoolRuntime`) | Pass condition |
|---|---|
| `PendingUserRequestCount` | At or near **zero** under the workload |
| `StuckThreadCount` / `HoggingThreadCount` | Not rising; no new stuck threads introduced |
| `Throughput` | **Increased** or unchanged (never regressed) |

### JDBC connection pool

| Metric (`JDBCDataSourceRuntimeMBean`) | Pass condition |
|---|---|
| `WaitingForConnectionCurrentCount` | **Zero** under the workload |
| `ActiveConnectionsHighCount` vs. `Maximum Capacity` | High-water below max (headroom remains) |
| `ConnectionDelayTime` / reserve latency | **Decreased** vs. baseline |
| `NumUnavailable` | Zero |

### Batch throughput

| Metric | Pass condition |
|---|---|
| Batch elapsed time (representative control) | **Decreased** vs. baseline and within the batch window |
| Throughput (records/units per minute) | **Increased** vs. baseline |
| Thread utilization | Threads doing work, not idle-waiting on connections/locks |

### SQL / Database

| Metric (AWR/ASH) | Pass condition |
|---|---|
| Top-SQL elapsed time (tuned statement) | **Decreased** vs. baseline |
| Top wait events | Target wait reduced; no new dominant wait introduced |
| DB CPU / sessions / processes | Within capacity headroom; no session/process exhaustion |

---

## No-regression gate (mandatory, every pass)

A per-layer pass is invalid if it pushed load into another layer. After each change, confirm **none**
of the following regressed past its baseline:

- GC pause/time fraction (Step 3d batch threads must not induce heap pressure).
- Connection-pool waits (Step 3d/3b must not create `WaitingForConnectionCurrentCount`).
- DB sessions/processes/CPU (Step 3c/3d must not exhaust DB capacity).
- WebLogic stuck/hogging threads (no new stuck threads from any change).

---

## Production go/no-go gate

Before promoting to production:

1. The change **passed its layer gate** on the pilot with the representative workload.
2. The **no-regression gate** passed.
3. A **rollback** to the recorded prior value is verified and a change window is booked.
4. `OC2MPERF-Report` shows baseline-vs-current evidence for the change.

If any item fails, it is **no-go** — roll back and re-diagnose.

---

## Test execution checklist

- [ ] Baseline captured with `OC2MPERF-Discovery` on the pilot, numbers recorded.
- [ ] Bottleneck isolated to a single layer.
- [ ] One named, reversible change applied to that layer only.
- [ ] Re-measure with `OC2MPERF-Validation` on the **same** workload.
- [ ] Layer gate **and** no-regression gate both pass.
- [ ] Evidence pack generated with `OC2MPERF-Report`.
- [ ] Promote under change control, or roll back and re-diagnose.
