# Requirements Guide

These are the prerequisites specific to **performance tuning** C2M and its WebLogic 14c middleware.
They are **in addition to** the shared Oracle-category prerequisites (licensed C2M/OUAF + certified
WebLogic 14c and Oracle Database, defined Dev/Test/Prod environments, WLST/shell/SQL admin access, and
change control/backup/non-production pilot) documented in the global Oracle requirements — verify those
first. Each requirement below is stated as **Description / Why / Verify / Implement**.

> You cannot tune what you cannot measure. The first three requirements exist to make the
> **measure-first** method possible; skipping them turns tuning back into guessing.

---

## 1. Metrics, monitoring & a repeatable baseline

- **Description:** The ability to capture, at will and repeatably, GC behavior (GC logs), WebLogic
  runtime metrics (thread pool + JDBC data-source MBeans), OUAF batch elapsed/throughput data, and an
  Oracle Database performance snapshot (**AWR/ASH**, which requires the **Diagnostics Pack** license).
- **Why required:** The method baselines the stack, isolates the saturated layer from evidence, and
  validates each change against measured **gates**. Without a repeatable baseline there is no "before"
  to prove a "gain."
- **How to verify:** Confirm GC logging can be enabled on the JVMs; confirm WLST/JMX can read the
  server `ThreadPoolRuntime` and `JDBCDataSourceRuntimeMBean`; confirm you can generate an AWR report
  (`$ORACLE_HOME/rdbms/admin/awrrpt.sql`) or query `V$` views; confirm batch run history is available
  (Batch Run Tree / `CI_BATCH_RUN` tables or the JMX batch client). Run `OC2MPERF-Discovery` — it
  collects the read-only baseline and tells you what it could and could not read.
- **How to implement if missing:** Enable GC logging (see the Tuning Method), enable JMX/WLST access,
  confirm the Diagnostics Pack entitlement for AWR/ASH (or fall back to Statspack / `V$` views if not
  licensed — **verify your licensing**), and establish batch run-history access.

## 2. Environment & administrative access (WebLogic, OUAF, database)

- **Description:** Working access to the target environment: the **WebLogic Administration Console and
  WLST** (admin credentials), the **OUAF product OS user** shell on each node (to read
  `threadpoolworker.properties`, run `bedit.sh`, `submitbatchREST.sh`, `configureEnv.sh`,
  `initialSetup.sh`), and a **database account** that can read the performance views and (for
  remediation) alter the relevant objects.
- **Why required:** Every measurement and every tuning change is applied through these three
  interfaces; batch tuning in particular is done at the OS/OUAF layer, not the console.
- **How to verify:** Log in to the Administration Console; connect WLST to the Admin Server; `su` to
  the product user and source the environment (`splenviron.sh -e <your-environment>`); connect to the
  schema with SQL*Plus/SQLcl and select from `V$SESSION`.
- **How to implement if missing:** Have the infrastructure/DBA teams grant the accounts and roles, and
  install the client tooling (WLST is delivered with WebLogic; SQLcl/SQL*Plus for the database).

## 3. A representative, repeatable workload profile

- **Description:** A defined, **reproducible** workload that represents the pain — a load-test script
  for the online/web-service tiers, and/or a named set of **batch controls** (e.g. billing, meter-read
  processing, To-Do) run against a known data volume — plus the **success criteria** (target response
  time, batch window, throughput).
- **Why required:** Baseline and re-measure must use the **same** workload or the comparison is
  meaningless. A one-off "it felt slow" cannot be tuned against a gate.
- **How to verify:** Confirm you can replay the workload on the pilot environment on demand and that
  its inputs (data volume, concurrency, batch parameters) are pinned.
- **How to implement if missing:** Build the load-test scenario and/or select and script the
  representative batch job(s) with fixed parameters before baselining.

## 4. Certified, matched stack versions across the tuning path

- **Description:** OS, **JDK** (the JVM you are tuning), **WebLogic 14c**, **OUAF/C2M**, and **Oracle
  Database** at versions **certified together** for your C2M release. GC flags and default MBean values
  differ across JDK and WebLogic versions.
- **Why required:** Applying a GC flag or MBean setting valid for one JDK/WebLogic version to another
  can be a no-op or an error; supportability depends on a certified combination (see the global
  requirements).
- **How to verify:** `java -version` on the product user's path; WebLogic version from the console or
  `. setDomainEnv.sh; java weblogic.version`; C2M/OUAF version from the console **About**; database
  `SELECT * FROM v$version;`. Compare against the C2M certification matrix on MOS.
- **How to implement if missing:** Align to a certified combination **before** tuning — do not tune on
  an uncertified stack.

## 5. Change control, backups & a non-production pilot

- **Description:** A change window and approval for production; **verified backups** of the WebLogic
  domain config, OUAF product/config files (`threadpoolworker.properties`, data-source and JVM
  settings), and the database before any change; and a **non-production environment** to pilot on.
- **Why required:** Tuning changes are production-impacting. Every change in the method is **single,
  named, and reversible**, validated on the pilot first, then promoted under change control with a
  rollback ready.
- **How to verify:** Confirm a tested restore path for the domain config and OUAF config files, a DB
  backup/restore or flashback point, and a booked change window.
- **How to implement if missing:** Establish backups and change control before touching production;
  `OC2MPERF-ScopeHelper` helps you record the pilot scope and rollback targets up front.

## 6. Collaborating teams (DBA, infrastructure, app-dev)

- **Description:** Named contacts on the **DBA**, **infrastructure/OS**, and **application-development**
  teams, plus the environment's monitoring stack (e.g. Dynatrace), since a bottleneck can live in any
  layer and a fix in one layer (batch threads) has consequences in another (DB sessions).
- **Why required:** Cross-layer tuning needs cross-team coordination — e.g. raising batch threads
  requires the DBA to confirm `processes`/`sessions` headroom.
- **How to verify:** Confirm the contacts and escalation path.
- **How to implement if missing:** Identify the teams and the monitoring model before starting.
