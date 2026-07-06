# 2. Requirements Guide — Oracle C2M Batch Scheduling & Thread-Pool Management

Verify every requirement before configuring thread pools, schedules, or dependencies. Each entry:
Description, Why, Verify, Implement-if-missing. Category-wide prerequisites (licensing, certified
stack, environments, WLST/shell/SQL tooling, change control) are in `global-requirements-oracle.md`.

## 2.1 A reachable C2M environment and product user
Description: A licensed C2M environment with its OUAF product home reachable, and the OS product user
that owns it (the account under which `threadpoolworker`/`submitbatch` run), with the environment
sourced via `splenviron.sh -e your-env`.
Why: Every batch script (`threadpoolworker.sh`, `submitbatchREST.sh`, `jmxbatchclient.sh`) requires
the environment variables `splenviron.sh` sets; without them the utilities cannot locate the domain,
class path, or configuration.
Verify: As the product user, run `splenviron.sh -e your-env` then run `OC2MBATCH-Discovery.sh` — it
confirms the environment is sourced and the batch utilities are on the path.
Implement-if-missing: Obtain the product-user credentials and the environment name; confirm the OUAF
install is complete (`initialSetup`/`configureEnv` run) before proceeding.

## 2.2 Batch controls inventory (what runs)
Description: A known list of the C2M **batch controls** in scope — the background processes you must
schedule (for example billing, payment upload, meter-read processing, To Do generation, extracts) —
with each one's default thread count.
Why: You cannot size thread pools or build a schedule without knowing which batch controls run, how
heavy each is, and its default parallelism; the schedule and dependencies are defined per batch
control.
Verify: You can list the in-scope batch controls and their defaults; run `OC2MBATCH-Discovery.sh`,
which reads batch-control metadata and recent run history from the C2M schema (read-only).
Implement-if-missing: Compile the batch-control list from the C2M batch schedule/run history and the
business owners; record each control's purpose and default threads.

## 2.3 Thread-pool worker topology and capacity
Description: The planned **thread pool worker** nodes (which hosts run `threadpoolworker`), and the
CPU/memory/JVM-heap headroom on each, so pools can be sized without starving the online tier or the
database.
Why: Thread count is only useful if the host and JVM can carry it; over-committing threads causes GC
thrashing, database contention, and overrun windows — under-committing wastes the batch window.
Verify: For each planned worker host you can state cores, memory, and the JVM heap the worker will
use; run `OC2MBATCH-Discovery.sh` to report the currently configured pools and thread counts.
Implement-if-missing: Confirm the worker hosts and their resource headroom with the infrastructure
team; document the heap sizing per node before assigning thread counts.

## 2.4 Named thread pools defined
Description: The named thread pools this solution standardizes — `C2M Pool - Default - Batch`,
`C2M Pool - Online - Batch`, and the dedicated heavy pool `C2M Pool - Billing - Batch` — each with a
documented thread count, offered consistently by every worker node (`C2M Worker - Node - Threadpools`).
Why: Named, consistent pools are what let you partition capacity (keep heavy billing off the online
pool) and reuse the same worker configuration across nodes and environments.
Verify: Each worker node offers the same pool names; run `OC2MBATCH-Validation.sh`, which checks that
every node advertises the standard pool set with the expected thread counts.
Implement-if-missing: Define the pool names and thread counts (see the Implementation Guide) and apply
them to each worker node's startup (`threadpoolworker -p ...`) or `threadpoolworker.properties`.

## 2.5 Scheduler decided and reachable (DBMS or enterprise)
Description: A chosen scheduler — the Oracle Database **DBMS scheduler** (via the framework `F1-DBMS`
business services: DBMS Program, Schedule, Job, Chain) or an enterprise/third-party scheduler
submitting through `submitbatchREST.sh` — with the access to define programs, jobs, and chains.
Why: A scheduler is what turns a list of batch controls into an ordered, time-based cycle with
dependencies; without one, batch is submitted by hand and dependencies are enforced by hope.
Verify: You can define (or already have) a DBMS Program for a representative batch control, or invoke
`submitbatchREST.sh -b your-batch-control` successfully; run `OC2MBATCH-Validation.sh` (checks
scheduler reachability signals).
Implement-if-missing: Choose the scheduler; for DBMS, confirm the schema has the `F1-DBMS` services
and the privileges to create scheduler objects; for enterprise, confirm REST submission works.

## 2.6 Database access for run status and monitoring
Description: Read access to the C2M schema tables that hold **batch run status** (batch run,
batch run thread, batch instance) so run history, completion, and backlog can be reported.
Why: Monitoring closes the loop; without run-status access there is no `C2M Monitor - Batch - Run
Status` view and a stuck or backlogged run is invisible to operations.
Verify: You can query batch run status for a recent run; run `OC2MBATCH-Report.sql` via SQL*Plus/SQLcl
against the schema (read-only) and confirm it returns recent runs.
Implement-if-missing: Grant the reporting account SELECT on the batch run-status tables (or use the
product user); confirm SQL connectivity per the global requirements.

## 2.7 JMX batch monitoring enabled (active-thread control)
Description: The batch JMX interface enabled on the worker nodes (the RMI/JMX port populated, e.g.
`BATCH_RMI_PORT`) so `jmxbatchclient.sh` can list, filter, and — when authorized — cancel active
threads.
Why: Run-status tables show completed and in-progress runs; JMX is how operations sees and controls
*live* threads (a stuck thread, a runaway pool) without bouncing the worker.
Verify: `jmxbatchclient.sh -j your-jmx-url -s` returns an active-thread summary; `OC2MBATCH-Validation.sh`
reports whether the JMX port is configured.
Implement-if-missing: Set the JMX/RMI port in the worker configuration and restart the worker in a
change window; confirm the client connects.

## 2.8 A non-production pilot environment and change control
Description: A non-production C2M environment to size pools, build the schedule, and prove the
dependency chain before touching production, plus change control and backups (domain config,
`threadpoolworker.properties`, scheduler objects) per the global requirements.
Why: Thread-pool sizing and dependency changes are high-impact; the model is Assess → Configure →
Pilot → Validate → Expand with a documented rollback.
Verify: A non-production environment is available and a backup/rollback path for the worker config and
scheduler objects is confirmed.
Implement-if-missing: Stand up or obtain the non-production environment and establish the backup and
change window before any production change.

---
## Checklist
- [ ] C2M environment reachable, product user, `splenviron.sh -e your-env` sources cleanly — `OC2MBATCH-Discovery.sh`
- [ ] Batch controls inventory with default threads — `OC2MBATCH-Discovery.sh`
- [ ] Worker topology and capacity known
- [ ] Named thread pools defined — `C2M Pool - Default/Online/Billing - Batch`, `OC2MBATCH-Validation.sh`
- [ ] Scheduler chosen and reachable (DBMS `F1-DBMS` or enterprise via `submitbatchREST.sh`)
- [ ] DB access to batch run-status tables — `OC2MBATCH-Report.sql`
- [ ] JMX batch monitoring enabled — `jmxbatchclient.sh`, `OC2MBATCH-Validation.sh`
- [ ] Non-production pilot + change control and backups
