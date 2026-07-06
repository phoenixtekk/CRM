# Best Practices

Repeatable, evidence-based tuning for C2M on WebLogic 14c. These are the habits that keep tuning
safe, honest, and durable.

## Measure first, always

- **No baseline, no change.** Never adjust a knob without a recorded "before." The baseline is the
  only thing that lets you prove a gain — or catch a regression.
- **Same workload, every time.** Baseline and re-measure with the identical workload (data volume,
  concurrency, batch parameters). A different workload invalidates the comparison.
- **Diagnose the layer, don't pattern-match the symptom.** Slow SQL, a starved thread pool, and an
  exhausted connection pool all *look* like "C2M is slow." Read the evidence and isolate the real
  constraint before touching anything.

## One change at a time

- **Single, named, reversible.** Each tuning pass changes exactly one layer, records the prior value,
  and has a rollback ready. Bundled changes make it impossible to attribute the result.
- **Tune the lower layer first.** When two layers look saturated, fix the lower one (DB/connection
  pool) and re-measure — it often relieves the layer above and saves you a change.

## Respect layer coupling

- **Batch threads cost connections and DB sessions.** Before raising `submitbatchREST.sh -c` or a
  thread pool size, confirm the JDBC pool `Maximum Capacity` and the database `processes`/`sessions`
  can carry the extra concurrency. Coordinate with the DBA.
- **A bigger pool can overload the database.** Sizing `Initial Capacity = Maximum Capacity` removes
  first-use latency but must stay within DB session headroom.
- **More heap is not free.** Larger heaps can lengthen GC pauses; keep the pause target and confirm
  RAM headroom so the heap is never swapped.

## Prefer self-tuning and shaping over fixed counts

- WebLogic 9.0+ uses a **self-tuning** thread pool — shape it with **Work Managers** and constraints
  rather than forcing fixed thread counts. Investigate stuck/hogging threads at the source (usually a
  downstream wait), don't just add threads.

## Production discipline

- **Pilot first.** Validate every change on a non-production environment against a measured gate before
  it reaches production, then promote under change control.
- **Back up before you touch.** Domain config, OUAF config files (`threadpoolworker.properties`, JVM
  and data-source settings), and the database — verified restore path.
- **Dry-run remediation.** Run `OC2MPERF-Remediation` in its default **dry-run** mode first, review
  the planned change, then apply deliberately in a change window.

## Version and licensing hygiene

- **Verify for your version.** GC flags, MBean paths, OUAF utility options, and default values shift
  across JDK / WebLogic / OUAF releases. Confirm against the certified matrix and the docs for your
  exact versions — never carry a value across versions blindly.
- **Respect gated content and licensing.** AWR/ASH need the Diagnostics Pack; some tuning notes/patches
  are MOS-gated. Point to them; don't assume entitlement.
- **Don't alter product-owned schema.** Index/stat/plan fixes on C2M product objects are
  vendor-governed — confirm with support/MOS; free-hand only custom/CM objects.

## Keep the evidence

- **Record every pass.** Baseline, change, re-measure, gate outcome, keep/rollback decision — build the
  evidence pack with `OC2MPERF-Report` so tuning is auditable and repeatable next quarter.
- **Re-baseline after promotion.** Once a change is live, the new steady state becomes the baseline for
  the next bottleneck.
