# 7. Best Practices — Oracle C2M Batch Scheduling & Thread-Pool Management

- Partition capacity with named pools. Keep heavy controls in `C2M Pool - Billing - Batch` and light
  or online-adjacent work in `C2M Pool - Online - Batch`; a single shared pool lets one long billing
  run starve everything else. Offer the same pool names on every node (`C2M Worker - Node -
  Threadpools`) so config is portable.
- Size threads to the host and the database, not to a wish. Total threads across all pools on a node
  must fit the JVM heap and the CPU, and the aggregate across nodes must not overwhelm the database —
  over-committing threads causes GC thrashing and DB contention that make batch *slower*, not faster.
  Start conservative, measure with `OC2MBATCH-Report.sql`, then raise.
- Match thread count to the batch control's own default and data volume. A control's shipped default
  thread count is a starting point; tune per control against its record volume rather than applying
  one number everywhere.
- Prefer the REST/daemon submission path for new work. `submitbatchREST.sh` writes to the Batch Job
  Submission table that the batch daemon polls — it is the supported modern path; keep the legacy
  direct submitter only where you must.
- Encode every hard dependency as a chain rule, never as timing. Use `C2M Chain - Nightly -
  Dependencies` so a successor starts on `predecessor SUCCEEDED`, not "20 minutes later and hope" —
  gap-timing dependencies break the first slow night.
- Schedule the heavy controls into the widest part of the window. Put billing and other long controls
  where they have room; sequence lighter controls around them so the window does not overrun.
- Monitor live and after. Watch active threads during the run with `jmxbatchclient.sh` and completion
  and backlog after with `OC2MBATCH-Report.sql` — a growing Batch Job Submission backlog is the
  earliest warning that pools are under-sized or a control is stuck.
- Keep run-status visible every night. Make `C2M Monitor - Batch - Run Status` a standing operational
  view so a missed or failed control is caught by operations at completion, not by a business user the
  next morning.
- Change pools, schedules, and dependencies under change control only. Back up
  `threadpoolworker.properties` and the scheduler objects, prove the change on non-production first,
  and keep a documented rollback — batch config changes are high-impact.
- Prove throughput on a pilot before you scale. Run the whole cycle on non-production and pass the
  gate (pools advertised, dependencies honored, completes in-window, no backlog) before touching
  production.
