# 1. Solution Overview — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

## What this is
When Oracle Utilities Customer to Meter (C2M) breaks, the hardest part is not fixing it — it is
finding **which layer is actually failing**. A login that hangs can be a WebLogic data source that
cannot reach the database, an expired keystore, a saturated connection pool, or a stuck thread deep in
application code — and the symptom looks the same from the front. This solution is a **structured
root-cause tree plus diagnostic scripts** for C2M and its Oracle WebLogic Server 14c middleware. It
turns guesswork triage into a layered method: you start at the symptom, run the exact checks that
isolate the failing layer, restore service, and capture a **defensible root-cause analysis (RCA)**.

> **Version boundary.** Command names, script names, log paths, and object terminology below are from
> the Oracle Utilities Application Framework (OUAF) Server Administration Guide, the C2M product
> documentation, and the Oracle WebLogic Server 14c administration documentation. Version-specific
> details (C2M 25.4 / minimum v2.9, WebLogic 14c, OUAF batch/IWS surfaces) are **cited or flagged
> "verify for your version"** — never invented. Some notes and patches are gated on My Oracle Support
> (MOS) and are pointed to, not reproduced. See `global-requirements-oracle.md`.

## The C2M fault domains
Every C2M incident lives in one (or the seam between two) of four layers. The whole method is built on
naming the layer first, because the fix — and who owns it — is different in each:

1. **WebLogic / middleware** — the Administration Server, the Managed Servers (`SPLService`,
   `SPLWeb`, `ohelp`), Node Manager, JVM heap and garbage collection, the execute-thread pool (stuck
   and hogging threads), JDBC data sources and connection pools, JMS servers/queues, and the domain's
   SSL/keystore configuration. Most "won't start", "can't log in", "hangs under load", and JMS-backlog
   symptoms surface here first.
2. **Database** — the Oracle Database schema behind C2M: listener and service availability, the
   accounts the data sources use, locking/blocking sessions, tablespace and temp pressure, and query
   plans. A middleware symptom (a data source that will not connect, a stuck thread in JDBC) is very
   often a database cause.
3. **Network / infrastructure** — DNS, host reachability, the ports between the tiers (Managed Server
   ↔ DB listener, Node Manager, JMS/RMI, the load balancer/reverse proxy to `SPLWeb`), firewalls, and
   time skew. A layer that "cannot reach" another is a network cause wearing a middleware mask.
4. **Application / OUAF** — the framework and C2M configuration and code: Inbound Web Services (IWS,
   the successor to the deprecated XAI servlet), batch controls and the thread-pool workers, the MPL /
   messaging configuration, feature configuration, algorithms, business objects/services, and the
   product logs (`spl*.log`, `system.log`). When the platform is healthy but one function fails, the
   cause is here.

## The layered root-cause model
The toolkit's core is a **top-down isolation** method — check the cheapest, broadest layer first and
descend only when it passes, so you never tune the application for what is really an expired
certificate:

> **Reachable? → Up? → Authenticated? → Resourced? → Correct?**
>
> 1. **Reachable** (network) — can the tier be reached at all (host, port, DNS, listener)?
> 2. **Up** (middleware) — are the Admin/Managed Servers and Node Manager `RUNNING`, not `ADMIN`,
>    `FAILED`, or `FAILED_NOT_RESTARTABLE`?
> 3. **Authenticated** (middleware ↔ DB, SSL) — do the data sources connect, are the keystores/certs
>    valid and unexpired, does login succeed?
> 4. **Resourced** (middleware + DB) — heap/GC, thread pool (stuck/hogging), connection pools, JMS
>    depth, DB locks/tablespace — is anything saturated?
> 5. **Correct** (application/OUAF) — with the platform healthy, is the specific function (batch, IWS,
>    a screen) configured and coded correctly?

Each symptom branch in the Diagnostic Playbook (document 3) walks this ladder with the exact WLST,
console, SQL, and log check for that branch, and states the layer each check isolates.

## Named diagnostic artifacts this solution defines
So the method is repeatable and the RCA is defensible, the toolkit names its artifacts once and reuses
them across every incident:

- **`C2M RCA - Fault Domain Map`** — the four-layer model above, the reference every triage starts from.
- **`C2M RCA - Symptom Decision Tree`** — the symptom-to-branch tree (won't start / can't log in;
  batch fails; JMS backs up; IWS/integration errors; performance stall; outage).
- **`C2M RCA - Layer Isolation Checklist`** — the per-layer checks (Reachable/Up/Authenticated/
  Resourced/Correct) the validation script runs.
- **`C2M RCA - Diagnostic Snapshot`** — the point-in-time evidence bundle (config, server states,
  thread/heap, DB signals, log tails) the discovery script collects.
- **`C2M RCA - Root-Cause Record`** — the defensible write-up: symptom, timeline, isolating evidence,
  the layer and cause, the fix applied, and prevention, produced from the report script's output.

## What this is not
This is a **diagnostic** toolkit. Every included script is **read-only** where it touches a live
system — discovery, validation, and report only observe (they read config, server states, JMX, and
`SELECT` from the schema). The remediation script is **dry-run by default**: it previews only safe,
reversible service-restoration actions (an orderly restart, a data-source or JMS re-sync) and never
changes anything unless explicitly asked, in a change window. The toolkit does not rewrite C2M
business logic, patch the product, or replace the database; where a fix is a product defect it points
to the version's MOS note and a service request rather than reproducing gated content.

## The deployment model
> Reproduce and scope the symptom, run the layer-isolation checks to find the failing layer, restore
> service with the smallest safe action, validate the restore against a gate, then record the RCA and
> the prevention. The repeatable way: Assess, then Configure (the checks), then Pilot (on
> non-production or a captured snapshot), then Validate, then Expand — with a documented rollback for
> every production change.
