# 3. Diagnostic Playbook — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

This is the working core of the toolkit: a **symptom-driven decision tree**. Find your symptom, walk
its branch top-down through the layer-isolation ladder, and each check tells you the exact WLST /
console / SQL / log command to run and the **layer it isolates**. Do not skip down the ladder — a
check that passes rules out a layer; a check that fails is your root cause (or the next layer to
descend into). Capture evidence as you go with `OC2MRCA-Discovery.sh` so the RCA writes itself.

> Model: reproduce and scope the symptom, isolate the failing layer with the checks below, restore
> service with the smallest safe action, validate the restore against the gate, then record the RCA.
> Assess, then Configure the checks, then Pilot (on non-production or a captured snapshot), then
> Validate, then Expand — with a documented rollback for every production change.

> All commands assume the environment is sourced first: `splenviron.sh -e your-env` (run as the
> product user). WLST connects to the Admin Server (`connect()` to the `t3://` admin URL). Command,
> script, log, and object names are from the OUAF Server Administration Guide, the C2M documentation,
> and the WebLogic 14c administration documentation — **verify exact names/flags/paths for your
> version**. MOS-gated notes are pointed to, not reproduced.

## Step 0 — Scope the symptom first (before any check)
1. Run `OC2MRCA-ScopeHelper.sh --symptom your-symptom` to bound the incident: which tier(s), which
   Managed Server(s)/node(s), when it started, what changed (deploy, patch, cert, data spike), and
   whether it is total (outage) or partial (one function). This selects the branch below and the
   target set the other scripts run against.
2. Capture a starting `C2M RCA - Diagnostic Snapshot` with `OC2MRCA-Discovery.sh` (read-only): server
   states, log tails, thread/heap, DB signals. This is timestamped evidence for the RCA and the
   "before" for any restore.

---

## Branch A — C2M won't start / can't log in
The two most common openers, walked down the same ladder.

### A. Reachable? (network layer)
- **Check:** From the app host, confirm the DB listener/service and the tiers answer:
  `tnsping your-service`, and a port check to the DB listener and to the Managed Server ports. DNS
  resolves the DB and LB hostnames.
- **Isolates:** Network. If a required port/host is unreachable, the cause is network/infrastructure —
  fix routing/DNS/firewall/listener before touching WebLogic. If reachable, descend.

### B. Up? (middleware — server state)
- **Check (won't start):** Is **Node Manager** running and are the servers actually being started?
  Tail the server `.out`/`.log` under the domain log dir; under WLST `connect()` then
  `state('SPLService')` / `state('SPLWeb')`. A common cause after an unclean shutdown is orphaned Java
  processes holding the ports — confirm no stale JVM is bound before restart.
- **Check (health state):** `FAILED`, `FAILED_NOT_RESTARTABLE`, or stuck in `ADMIN` mode each point
  somewhere specific — `ADMIN` mode after a domain change often means a JRF/classpath problem, and a
  `ClassNotFoundException` in the `.out` names it (see the MOS note for JRF-in-admin-mode).
- **Isolates:** Middleware startup. `OC2MRCA-Validation.py` reports each server's state and health.

### C. Authenticated? (middleware ↔ DB, and SSL)
- **Check (can't log in / data source):** Under WLST read the JDBC runtime — does the C2M data source
  connect, or is it disabled/suspended with connection failures? A login that hangs or fails with the
  platform "up" is very often the data source unable to reach the DB or the DB account
  locked/expired. Confirm the DB side with `OC2MRCA-Report.sql` (blocking, account status).
- **Check (SSL):** List the identity/trust keystore expiry (`keytool -list`); an expired listener or
  trust cert presents as a failed login or a Managed Server that will not reach a secured resource.
  `OC2MRCA-Validation.py` flags near/expired certs.
- **Isolates:** DB connectivity/credentials, or SSL/keystore. Fixing here restores login without any
  application change.

### D. Resourced? (middleware + DB)
- **Check:** Heap/GC not exhausted (repeated full GC / `OutOfMemoryError` in the `.out`), the
  execute-thread pool not saturated with stuck threads (health `warning`/`critical`), the connection
  pool not at max with pending requests. `OC2MRCA-Validation.py` reports thread-pool health and pool
  usage.
- **Isolates:** Resource saturation at startup/login. If starved, restore capacity (see Remediation)
  before blaming config.

### E. Correct? (application/OUAF)
- **Check:** With platform healthy, is the product itself configured to start — `configureEnv`/
  `initialSetup` applied, the EARs (`SPLService`, `SPLWeb`, `ohelp`) deployed, feature configuration
  valid? Product startup errors land in `spl*.log`/`system.log`.
- **Isolates:** Application/OUAF configuration. This is the layer only after network, server, auth,
  and resources pass.

---

## Branch B — Batch fails or won't submit
### A. Up? (worker + daemon)
- **Check:** Are the `threadpoolworker` JVMs running and advertising their pools, and is the batch
  daemon node polling submissions? `OC2MRCA-Validation.py` / `jmxbatchclient.sh -s` for live threads;
  `OC2MRCA-Discovery.sh` for worker config. A control that "never runs" with no daemon is a worker/
  daemon-up problem, not a batch-code one.
- **Isolates:** Middleware (batch runtime).

### B. Authenticated / Resourced? (DB + pool)
- **Check:** Batch runs largely in JDBC — a stuck batch thread whose dump tops out in JDBC is a
  database cause: blocking session, tablespace/temp full, a bad plan. `OC2MRCA-Report.sql` shows batch
  run status, in-flight/overdue threads, blocking sessions, and tablespace pressure.
- **Isolates:** Database (the usual batch culprit) or connection-pool starvation.

### C. Correct? (batch control / data)
- **Check:** With runtime and DB healthy, the control itself errors — read the batch log and the run
  status (`batch_thread_stat_flg` error rows via `OC2MRCA-Report.sql`); a repeatable error on one
  control with clean infrastructure is a control config/data issue for the application team.
- **Isolates:** Application/OUAF. If it is a product defect, point to the version's MOS note / open an
  SR.

---

## Branch C — JMS backs up / messages pending
### A. Up? (consumers attached)
- **Check:** Open the JMS destination runtime (WLST or console Monitoring): are **consumers present**
  (consumer count > 0)? A backlog with **zero consumers** means the consuming component (an OUAF IWS/
  MPL consumer, an MDB) is down or not attached — that is the cause, not the queue.
- **Isolates:** Middleware (consumer availability).

### B. Resourced / draining? (throughput)
- **Check:** Consumers attached but **pending count climbs** — messages arrive faster than they drain,
  or messages sit in *send/pending-transaction* state (a transaction resource in the global
  transaction is stuck). Check the consumer's own errors (product log) and any downstream (DB/outbound)
  it calls; `OC2MRCA-Report.sql` correlates with DB blocking.
- **Isolates:** Consumer throughput / a stuck transaction / a slow downstream — descend to whichever
  the consumer's stack names.

### C. Correct? (message / config)
- **Check:** Messages move to an error/dead queue, or the consumer rejects them — a malformed message
  or a mis-mapped service. Read the consumer's product log; this is application/OUAF configuration.
- **Isolates:** Application/OUAF. Redelivery/error-queue settings are config, not a queue defect.

---

## Branch D — IWS / integration errors
(Inbound Web Services — the successor to the deprecated XAI servlet; XAI-via-IWS support is a Feature
Configuration option.)

### A. Reachable / Up?
- **Check:** Does the endpoint answer at all — is IWS **enabled** (it is disabled by default for
  backward compatibility and must be turned on), is the service **deployed** (not stuck in
  "Deployment in Progress"/`ERROR`), and does the URL resolve through the LB/reverse proxy to `SPLWeb`?
- **Isolates:** Network reachability or middleware deployment state.

### B. Authenticated? (security / SSL)
- **Check:** A `401`/`403` or an SSL handshake failure — the caller's credentials, the security policy
  on the service, or an expired/untrusted certificate on an outbound call. `OC2MRCA-Validation.py`
  flags cert expiry; the product/HTTP log shows the auth failure.
- **Isolates:** Auth/SSL — a distinct layer from the service logic.

### C. Correct? (service mapping / payload)
- **Check:** A `500`/business fault with the platform healthy — the service references the wrong
  business object/service/script, or the payload/schema is wrong. Read the IWS/product log for the
  fault; for an XAI-via-IWS service confirm the External Messages *Support XAI Services via IWS*
  feature option is set.
- **Isolates:** Application/OUAF service configuration.

---

## Branch E — Performance stall (slow, not down)
### A. Resourced — JVM? (middleware)
- **Check:** Thread pool full of **stuck/hogging** threads (default: continuously busy > 600s = stuck;
  all default-queue threads stuck → health `critical`) and/or heap in constant full GC. Take a thread
  dump (`kill -3` → server `.out`, or console *Dump Thread Stacks*) and read the **top of the stack**:
  JDBC = database, an object-lock wait = deadlock, product code = application. `OC2MRCA-Validation.py`
  reports stuck/hogging counts and health state.
- **Isolates:** Points you at the next layer by what the stuck threads are waiting on.

### B. Resourced — Database? (DB)
- **Check:** If dumps top out in JDBC — blocking sessions, a plan regression, tablespace/temp
  pressure, or connection-pool exhaustion. `OC2MRCA-Report.sql` lists blocking sessions, long-running
  SQL signals, tablespace/temp usage, and pool pressure.
- **Isolates:** Database. Most "everything is slow" with clean JVM CPU is a DB cause.

### C. Correct? (application/OUAF)
- **Check:** Platform and DB healthy but one function is slow — a specific algorithm, batch control, or
  IWS path. Read that function's product log and its SQL. Compare to the healthy **baseline**
  (Requirement 2.7) — what deviates is the cause.
- **Isolates:** Application/OUAF.

---

## Branch F — Outage (total: no tier responding)
Fastest path from "everything is down" to the failed layer.

1. **Reachable (network):** Is it the whole host/network or C2M? Ping/port-check the DB listener, the
   Managed Server ports, and the LB. A dead listener or a network partition is the outage — restore it
   first. (`OC2MRCA-ScopeHelper.sh --symptom outage` bounds which tiers are dark.)
2. **Up (middleware):** If reachable, are the servers down? WLST `state()` / server `.out` — a crashed
   Admin/Managed Server (OOM, disk full on the log/output volume, an unclean shutdown holding ports).
   Check disk on the domain and `SPLOUTPUT` volumes early; a full log volume takes C2M down and is
   easy to miss.
3. **Authenticated (DB):** If servers are up but every request fails, the database or its listener is
   down / the data source cannot connect — confirm with `OC2MRCA-Report.sql`/`tnsping`. A DB outage
   presents as a total C2M outage.
4. **Restore, smallest action first:** Restore the failed layer with the least, most reversible action
   (start the listener, free the disk, orderly-restart the failed server) — preview it with
   `OC2MRCA-Remediation.sh` (dry-run) — then re-validate. Capture the snapshot **before** restart so
   the RCA is not lost when logs roll.

---

## Step N — Restore, validate, and record the RCA
1. **Restore** with the smallest safe action. `OC2MRCA-Remediation.sh` is **dry-run by default** — it
   previews the exact restart / data-source re-sync / JMS re-sync it *would* do and changes nothing;
   apply only with the explicit flag in a change window, backups taken.
2. **Validate the restore** against the gate (Testing Guide): the failed layer's check now passes,
   dependent layers pass, and the symptom is gone under a representative load.
3. **Record `C2M RCA - Root-Cause Record`** from the collected evidence: symptom + scope, timeline,
   the isolating check that named the layer, the root cause, the fix applied, and the prevention.
   `OC2MRCA-Report.sql` and the discovery snapshots supply the evidence; escalate genuine product
   defects to Oracle with the snapshot attached (see Best Practices).

---
### Order of operations
`Scope symptom -> Reachable? (net) -> Up? (middleware) -> Authenticated? (DB/SSL) -> Resourced? (JVM/DB/pools/JMS) -> Correct? (app/OUAF) -> Restore (smallest safe action) -> Validate gate -> Record RCA`
