# 3. Implementation Guide — Oracle C2M Batch Scheduling & Thread-Pool Management

Follow these steps in order. This guide configures C2M batch: named thread pool workers first, then
the schedule and its dependencies, then scheduler integration, then validation of throughput and
completion — pilot-first on a non-production environment, then expand to production under change
control. Object names are fixed — create them with the exact names shown and reuse them everywhere.

> Model: assess the estate, configure pools and the schedule, prove it on a non-production pilot,
> validate against the gate, then expand to production. Assess, then Configure, then Pilot, then
> Validate, then Expand — with a documented rollback for every production change.

> All commands assume the environment is sourced first: `splenviron.sh -e your-env` (run as the
> product user). Command and script names (`threadpoolworker`, `submitbatchREST.sh`,
> `jmxbatchclient.sh`, `F1-DBMS` services) are from the OUAF Server Administration Guide — verify the
> exact flags for your version.

## Step 1 — Assess the current batch estate
1. Source the environment (`splenviron.sh -e your-env`) and run `OC2MBATCH-Discovery.sh`. It captures:
   the in-scope batch controls and their default thread counts, the currently configured thread pools
   and thread counts on each worker node, and recent batch run history (durations, failures) from the
   C2M schema (read-only).
2. Identify the bottleneck controls (longest-running, most-failed) and the overrun points in the
   nightly window. Record gaps against the Requirements Guide checklist. Do not proceed past a missing
   environment, missing scheduler decision, or missing run-status access — implement those first.

## Step 2 — Define the named thread pools
1. Decide capacity per pool from the worker topology (Requirement 2.3). Standardize three pools:
   - `C2M Pool - Default - Batch` — general batch controls (name it `DEFAULT` in the worker config).
   - `C2M Pool - Online - Batch` — light, online-adjacent processes kept off the heavy pool (name it
     `ONLINE`).
   - `C2M Pool - Billing - Batch` — the dedicated heavy pool for billing and other long controls
     (name it `BILLING`).
2. Assign a documented thread count to each pool per node, sized to the host's cores/heap so total
   threads across pools do not over-commit the JVM or the database.

## Step 3 — Configure the thread pool workers
1. On each worker node, configure the standard pool set `C2M Worker - Node - Threadpools` — every node
   offers the same pool names so the configuration is portable. Set the pools either at startup or in
   `threadpoolworker.properties`:
   ```bash
   # every worker node offers the same named pools with node-sized thread counts
   threadpoolworker.sh -p DEFAULT=5,ONLINE=3,BILLING=8
   ```
   (`-p name=count,...` offers the named pools; size the counts per node. Verify flag syntax for your
   version in the Server Administration Guide.)
2. Designate the scheduler-daemon node if you use the REST/daemon submission path (the node that polls
   the **Batch Job Submission** table), per the version's `-d` daemon option.
3. Enable JMX on each worker (populate the RMI/JMX port, e.g. `BATCH_RMI_PORT`) so `jmxbatchclient.sh`
   can monitor and control live threads.
4. Start the workers in a change window and confirm each advertises the standard pools.

## Step 4 — Map batch controls to the scheduler
1. For each in-scope batch control, define a scheduler **program**:
   - **DBMS scheduler:** create a **DBMS Program** per batch control via the framework `F1-DBMS`
     business services (one program per batch control that needs scheduling).
   - **Enterprise/third-party scheduler:** define the job to invoke
     `submitbatchREST.sh -b your-batch-control -c threads` (REST submission writes to the Batch Job
     Submission table, which the batch daemon polls and executes).
2. Set each program to submit its batch control into the correct **pool** (heavy controls to
   `BILLING`, light to `ONLINE`, the rest to `DEFAULT`) with the intended thread count.

## Step 5 — Build the schedule
1. Create the schedule `C2M Schedule - Nightly - Batch Cycle`:
   - **DBMS scheduler:** define a **DBMS Schedule** (the nightly frequency) and a **DBMS Job** to run
     the cycle.
   - **Enterprise scheduler:** define the equivalent time trigger for the cycle.
2. Order the batch controls into the nightly cycle from the assessment (Step 1) so heavy controls run
   in the widest part of the window.

## Step 6 — Encode dependencies
1. Create the dependency chain `C2M Chain - Nightly - Dependencies`:
   - **DBMS scheduler:** define a **DBMS Chain** whose steps reference the DBMS Programs, with rules
     that gate each step on its predecessor (for example a step starts only on `predecessor SUCCEEDED`
     — the framework's documented chain-rule form). This is how "bill completion runs only after
     billing succeeds" is enforced, not assumed.
   - **Enterprise scheduler:** express the same predecessor→successor dependencies as the scheduler's
     job dependencies.
2. Verify every hard dependency from the business (billing before completion, upload before posting,
   etc.) is a rule in the chain.

## Step 7 — Configure monitoring
1. Stand up the monitoring view `C2M Monitor - Batch - Run Status` from the batch run-status tables:
   run `OC2MBATCH-Report.sql` (read-only) to render recent run status, durations, failures, and
   backlog.
2. Confirm live-thread visibility: `jmxbatchclient.sh -j your-jmx-url -s` for an active-thread summary
   and `-d` for detail. This is the operational view during the run.

## Step 8 — Pilot the cycle on non-production
1. On the non-production environment, run the whole nightly cycle end to end through the scheduler
   using the pools, schedule, and dependency chain.
2. Run `OC2MBATCH-Validation.sh` to confirm the pools are advertised as expected, the scheduler is
   reachable, and the run-status/JMX signals are present.
3. Run `OC2MBATCH-Report.sql` to capture throughput (records/sec, thread completion) and confirm every
   control completed and the chain honored its dependencies.

## Step 9 — Validate against the pilot gate
1. Complete the Testing Guide. The pilot passes only when: every worker advertises the standard pools;
   the cycle ran end to end within the window; every dependency in the chain was honored; and the
   run-status report shows all controls completed with no stuck threads and no backlog.
2. Remediate any configuration gaps with `OC2MBATCH-Remediation.sh` (dry-run by default — it prints
   the intended change; add the apply flag only in a change window) before re-running validation.

## Step 10 — Expand to production
1. After the pilot passes the gate, apply the same pools (`C2M Worker - Node - Threadpools`), schedule
   (`C2M Schedule - Nightly - Batch Cycle`), and dependency chain (`C2M Chain - Nightly -
   Dependencies`) to production under change control, with backups of the worker config and scheduler
   objects taken first and a documented rollback ready.
2. Re-run `OC2MBATCH-Validation.sh` and `OC2MBATCH-Report.sql` in production after the first cycle;
   keep the monitoring view running so backlog and completion stay visible night over night.

---
### Order of operations
`Assess -> Named pools -> Configure workers -> Map controls to scheduler -> Build schedule -> Encode dependencies -> Monitoring -> Pilot cycle -> Validate gate -> Expand to production`
