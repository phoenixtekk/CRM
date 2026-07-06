# 1. Solution Overview — Oracle C2M Batch Scheduling & Thread-Pool Management

## What C2M batch is
Oracle Utilities Customer to Meter (C2M) does most of its heavy lifting in **batch**: billing,
payment upload, meter-read processing, To Do generation, workflow, extracts, and hundreds of other
background processes. Each of these is a **batch control** — the framework object that names a
background process, its parameters, and its defaults. A batch control is executed as one or more
**threads**, and those threads run inside **thread pool workers** (`threadpoolworker`) — the JVMs
that actually do the work. Getting C2M batch right means three things done together: sizing and
running the right **thread pool workers**, scheduling the batch controls (and their **dependencies**)
correctly, and **monitoring** completion and backlog. This solution configures and manages all three
the repeatable way: named thread pools and schedules you define once and reuse everywhere.

> **Version boundary.** Command names, script names, and object terminology below are from the Oracle
> Utilities Application Framework (OUAF) Server Administration Guide and C2M product documentation.
> Version-specific details (C2M 25.4 / minimum v2.9, WebLogic 14c, OUAF batch REST submission) are
> **cited or flagged "verify for your version"** — never invented. Some notes and patches are gated on
> My Oracle Support (MOS) and are pointed to, not reproduced. See `global-requirements-oracle.md`.

## Why this matters
Batch that is mis-scheduled or under-resourced quietly breaks the business. Under-resourced thread
pools mean the nightly window overruns and bills go out late; over-resourced pools starve the online
system or the database. Missing dependencies mean a downstream job (say, bill completion) runs before
its upstream job (billing) finished, producing wrong or partial results. No monitoring means a stuck
thread or a growing backlog is discovered by a business user, not by operations. A real solution fixes
the cause, not the symptom: it sizes named thread pools deliberately, encodes dependencies in the
scheduler, and makes backlog and completion visible — turning "did batch run?" from a morning
surprise into a measured, monitored outcome.

## The C2M batch architecture
Four moving parts, each with a named object you define and reuse:

1. **Batch control** — the process definition (for example the billing batch control, the payment
   upload batch control). It carries the program name, default thread count, and parameters. You do
   not invent batch controls; C2M ships them. You *do* decide which pool each runs in and on what
   schedule.
2. **Thread pool worker (`threadpoolworker`)** — a JVM that offers one or more **named thread pools**
   (for example `DEFAULT`, `ONLINE`, and a dedicated pool such as `BILLING`), each with a thread
   count. Batch threads execute inside these pools. Pools are how you partition capacity so heavy
   batch does not starve light or online-facing work.
3. **Submitter** — the mechanism that submits a batch control's threads to a pool. C2M supports the
   REST submission path (`submitbatchREST.sh`, backed by the framework service that writes to the
   **Batch Job Submission** table and is polled by the batch daemon) and the legacy direct submitter
   (`submitjob.sh`). New work uses the REST/daemon path.
4. **Scheduler** — what decides *when* each batch control runs and in what order. C2M integrates with
   the Oracle Database **DBMS scheduler** through framework `F1-DBMS` business services: a **DBMS
   Program** per batch control, a **DBMS Schedule** for frequency, a **DBMS Job** to run a program or
   chain, and a **DBMS Chain** to express **dependencies** (step B runs only if step A `SUCCEEDED`).
   Enterprise/third-party schedulers integrate through the same REST submission and monitoring
   surface.

Monitoring closes the loop: the framework **Batch Run Tree** / batch run status (in the database) and
the JMX batch client (`jmxbatchclient.sh`) expose active threads, completion, and errors so a stuck
or slow run is caught in operations, not in the business.

## Named objects this solution defines
So the configuration is repeatable, this solution names its artifacts once and reuses them:

- **Thread pools** — `C2M Pool - Default - Batch`, `C2M Pool - Online - Batch`, and one dedicated
  heavy pool `C2M Pool - Billing - Batch`, each with a documented thread count. (Pool names are your
  own; reuse them across every worker node.)
- **Thread pool worker config** — `C2M Worker - Node - Threadpools`, the standard set of pools each
  worker node offers.
- **Schedule** — `C2M Schedule - Nightly - Batch Cycle`, the ordered nightly cycle of batch controls.
- **Dependency chain** — `C2M Chain - Nightly - Dependencies`, the DBMS chain that encodes which batch
  control must complete before the next starts.
- **Monitoring view** — `C2M Monitor - Batch - Run Status`, the standing view of batch run status and
  backlog.

## What this is not
This solution configures and operates C2M's own batch framework. It does not rewrite C2M business
logic, invent new batch controls, or replace the database. Where the included scripts touch live
systems they **read** — the discovery, validation, and report scripts are read-only; remediation runs
**dry-run by default**. Any change to production thread-pool sizing, schedules, or dependencies goes
through change control and is proven on a non-production environment first.

## The deployment model
> Assess the current batch estate and its bottlenecks, configure named thread pools plus the schedule
> and its dependencies, pilot the cycle on a non-production environment, validate throughput and
> completion against a gate, then expand to production. The repeatable way: Assess, then Configure,
> then Pilot, then Validate, then Expand — with a documented rollback for every production change.
