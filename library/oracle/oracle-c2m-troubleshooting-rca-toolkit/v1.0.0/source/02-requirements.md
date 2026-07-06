# 2. Requirements Guide — Oracle C2M Troubleshooting & Root-Cause Analysis Toolkit

Verify every requirement before you rely on the toolkit in an incident — the time to confirm you have
log access and WLST connectivity is *before* the outage, not during it. Each entry: Description, Why,
Verify, Implement-if-missing. Category-wide prerequisites (licensing, certified stack, environments,
WLST/shell/SQL tooling, change control) are in `global-requirements-oracle.md`.

## 2.1 A reachable C2M environment and product user
Description: A licensed C2M environment with its OUAF product home reachable, and the OS product user
that owns it (the account under which the WebLogic domain, `threadpoolworker`, and IWS run), with the
environment sourced via `splenviron.sh -e your-env`.
Why: The diagnostic scripts locate the domain, logs, and utilities through the variables
`splenviron.sh` sets (`SPLEBASE`, `SPLOUTPUT`); without them they cannot find what to inspect.
Verify: As the product user, run `splenviron.sh -e your-env` then run `OC2MRCA-Discovery.sh` — it
confirms the environment is sourced and the domain/log paths resolve.
Implement-if-missing: Obtain the product-user credentials and the environment name; confirm the OUAF
install is complete (`initialSetup`/`configureEnv` run) before proceeding.

## 2.2 Log and output access (WebLogic + OUAF + product)
Description: Read access to the log tree: the WebLogic domain logs and per-server `.out`/`.log` files
(including the Admin and Managed Server logs and any Node Manager log), and the OUAF/product logs under
`SPLOUTPUT`/the product log directory (`spl*.log`, `system.log`, batch and IWS logs).
Why: The log is the primary evidence for every branch of the tree — a `kill -3` thread dump lands in a
server `.out`, a data-source failure and a startup failure both write a diagnosable stack, and the RCA
is built from these tails. No log access means no defensible RCA.
Verify: You can read the current Managed Server `.out` and the product `spl*.log`; run
`OC2MRCA-Discovery.sh`, which tails and fingerprints the standard logs (read-only).
Implement-if-missing: Grant read on the domain and product log directories to the diagnostic account
(or run as the product user); confirm `SPLOUTPUT` and the WebLogic domain log path.

## 2.3 WLST access to the domain (offline and connected)
Description: WebLogic Scripting Tool (WLST, Jython) available and able to connect to the running
domain (to the Admin Server), plus the domain admin URL and credentials, so server states, thread
pools, JDBC, and JMS runtime can be read.
Why: WLST is how the toolkit reads live middleware state — server health (`RUNNING`/`ADMIN`/`FAILED`),
the execute-thread pool (stuck/hogging counts, health state), data-source connection-pool state, and
JMS destination depth — without clicking through the console during an incident.
Verify: `java weblogic.WLST` starts, and `connect()` to the Admin URL succeeds; run
`OC2MRCA-Validation.py` under WLST, which reports server and resource state.
Implement-if-missing: Install/point to the WLST from the domain's `oracle_common`/`wlserver`, and
obtain the Admin Server URL (`t3://...`) and read-capable admin credentials.

## 2.4 Database read access for the diagnostic queries
Description: A read (SELECT) account on the C2M schema and the ability to reach the database as the
data sources do, so the toolkit can check listener/service availability, blocking sessions, tablespace
and temp pressure, and batch/IWS run status from the database side.
Why: A large share of "middleware" symptoms (a data source that will not connect, a stuck JDBC thread,
a slow screen) are database causes; the layered model descends into the DB, and that needs SQL access.
Verify: You can connect with SQL*Plus/SQLcl and select from the schema; run `OC2MRCA-Report.sql`
(read-only) and confirm it returns the diagnostic sections.
Implement-if-missing: Obtain a read-only DB account (or use the product user's), and confirm SQL
connectivity and the service name per the global requirements.

## 2.5 JMX / thread-diagnostic access
Description: The ability to obtain a JVM thread dump for each Managed Server (via the console's
Monitoring → Threads *Dump Thread Stacks*, `jstack`, or `kill -3` to the server `.out`), and — for
batch — the OUAF batch JMX interface (`jmxbatchclient.sh`, RMI/JMX port populated, e.g.
`BATCH_RMI_PORT`) for live batch threads.
Why: Stuck and hogging threads are diagnosed from thread dumps (the top of the stack names the layer —
JDBC = database, a lock = deadlock, product code = application); JMX is how live batch threads are
seen without bouncing a worker.
Verify: You can produce a thread dump for a Managed Server and it lands in the expected `.out`;
`jmxbatchclient.sh -s` returns a summary. `OC2MRCA-Validation.py` reports the thread-pool health state.
Implement-if-missing: Confirm `kill -3`/`jstack` access to the server processes and that the batch
RMI/JMX port is set; grant the OS access needed to signal the JVMs.

## 2.6 Keystore / SSL inspection access
Description: Access to inspect (not necessarily change) the domain's identity/trust keystores and the
certificates the SSL listeners and outbound integrations use — the keystore files/paths and
`keytool`/`orapki` to read expiry and chains.
Why: An expired or mis-trusted certificate presents as "can't log in", a failed outbound IWS call, or
a Managed Server that will not reach a secured resource — a distinct layer that the tree checks
explicitly so it is not misdiagnosed as an application fault.
Verify: You can list certificate expiry from the identity/trust store with `keytool -list`;
`OC2MRCA-Validation.py` flags certificates near or past expiry (read-only).
Implement-if-missing: Obtain read access to the keystore files and the store passwords needed only to
*list* contents; document the keystore paths from the domain SSL configuration.

## 2.7 A baseline of "healthy" (what normal looks like)
Description: A recorded baseline for the environment — normal startup log signature, typical heap/GC
and thread-pool levels, normal batch durations, normal JMS depth, and expected server states — so an
incident's snapshot can be compared to normal rather than to a guess.
Why: RCA is a comparison: "this is what changed." Without a baseline every reading is ambiguous; with
one, the deviating layer stands out immediately.
Verify: A baseline snapshot exists (capture one now with `OC2MRCA-Discovery.sh` on a healthy day);
`OC2MRCA-Report.sql` and the discovery output give you the comparison set.
Implement-if-missing: Run the discovery and report scripts on a known-good day and store the output as
the baseline `C2M RCA - Diagnostic Snapshot`.

## 2.8 A non-production environment (or captured snapshot) and change control
Description: A non-production C2M environment to reproduce symptoms and rehearse the toolkit safely,
or — when the fault is production-only — the discipline to capture a read-only `C2M RCA - Diagnostic
Snapshot` and test fixes on non-production, plus change control and backups (domain config, product
config) before any restart or re-sync in production.
Why: Even "safe" restorative actions (an orderly restart, a data-source re-sync) are production events;
the model is Assess → Configure → Pilot → Validate → Expand with a documented rollback.
Verify: A non-production environment is available and a backup/rollback path for the domain and product
config is confirmed.
Implement-if-missing: Stand up or obtain the non-production environment and establish the backup and
change window before any production restore action.

---
## Checklist
- [ ] C2M environment reachable, product user, `splenviron.sh -e your-env` sources cleanly — `OC2MRCA-Discovery.sh`
- [ ] Log/output access (WebLogic `.out`/domain logs + OUAF `spl*.log`/`system.log`) — `OC2MRCA-Discovery.sh`
- [ ] WLST connects to the Admin Server (read server/resource state) — `OC2MRCA-Validation.py`
- [ ] DB read access for the diagnostic queries — `OC2MRCA-Report.sql`
- [ ] Thread-dump + batch JMX access (stuck/hogging + live batch threads) — `OC2MRCA-Validation.py`, `jmxbatchclient.sh`
- [ ] Keystore/SSL inspection access (cert expiry) — `OC2MRCA-Validation.py`
- [ ] A recorded "healthy" baseline snapshot — `OC2MRCA-Discovery.sh`, `OC2MRCA-Report.sql`
- [ ] Non-production (or captured snapshot) + change control and backups
