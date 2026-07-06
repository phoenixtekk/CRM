# Best Practices

Practices for a WebLogic 14c domain that carries C2M well over its life — not just up on day one.
They reinforce the **Assess → Configure → Pilot → Validate → Expand** model and the named topology
(`c2m_domain`, `AdminServer`, `c2m_ms1`/`c2m_ms2`, `c2m_cluster`, `c2m_machine1`, `C2MDataSource`).
Where a specific value depends on the release, **verify for your version** against Oracle's
documentation and certification matrix.

## Domain layout & topology

- **Keep `DOMAIN_HOME` outside `ORACLE_HOME`.** Binaries and domain have different lifecycles;
  separating them lets you patch/reinstall WebLogic without disturbing `c2m_domain`, and back them
  up independently.
- **Never deploy the C2M application to `AdminServer`.** Reserve `AdminServer` for administration;
  run C2M (`SPLWeb`/`SPLService`) on the managed server(s). This isolates admin availability from
  app load and is the supported OUAF pattern.
- **Name objects deliberately and reuse the names everywhere** — domain, servers, cluster, machine,
  data source. Consistent names across `config.xml`, WLST scripts, and runbooks prevent the
  "which server did we mean?" class of outage. Map to your site convention **once**, then hold it.
- **Bind to real hostnames/IPs, never `localhost`.** A machine or listen address on `localhost`
  breaks Node Manager control and (later) clustering/Coherence. This is a validation check for a
  reason.
- **Start single-node, then scale.** Prove one managed server clean before adding `c2m_ms2` /
  `c2m_cluster`. HA on top of an unproven single node just multiplies the problem.

## Node Manager

- **Use the per-domain Node Manager** (under `DOMAIN_HOME/nodemanager`) unless a site standard
  mandates per-host. Per-domain keeps each domain self-contained and easy to move/patch.
- **Run servers under Node Manager, not foreground scripts.** Foreground `startManagedWebLogic.sh`
  is fine for a quick pilot, but production servers should start/stop/**auto-restart** through Node
  Manager so a crash recovers itself.
- **Enable `StartScriptEnabled=true`** so Node Manager applies your `setUserOverrides.sh` JVM args
  when it launches servers — otherwise your carefully-tuned heap silently doesn't apply.
- **Secure Node Manager** (`SecureListener=true`, SSL) outside throwaway sandboxes, and register
  the domain with `nmEnroll` so trust is established once and reused.
- **Install Node Manager as a service/boot job** so it survives host reboots; a rebooted host with
  no Node Manager means nothing auto-starts.

## Data sources

- **Turn on Test Connections On Reserve** with a lightweight test (`SQL ISVALID` /
  `SQL SELECT 1 FROM DUAL`) so WebLogic hands out only live connections — cheap insurance against
  stale-connection failures after a DB blip.
- **Use the service name, not SID** (required for RAC), and prefer an **Active GridLink** data
  source when the C2M database is **RAC** so FAN/ONS failover and load balancing work.
- **Target data sources at the managed server(s)/cluster, never `AdminServer`.** A data source on
  `AdminServer` is a classic mis-target that "works" in a demo and fails the moment app load moves
  to the managed servers.
- **Size the pool for real load, not defaults.** Set Initial/Max Capacity from C2M sizing guidance
  and observed concurrency (**verify for your version**); watch for pool exhaustion and connection
  leaks under batch + online concurrency.
- **Keep schema credentials out of scripts.** Set them in the data source (WebLogic encrypts them);
  never bake passwords into WLST files committed anywhere.

## JVM / startup & memory

- **Set heap deliberately via `setUserOverrides.sh`**, not by editing generated startup scripts.
  Overrides survive domain re-generation; hand-edits to `startWebLogic.sh` do not.
- **Right-size heap and metaspace for C2M** and pin `-Xms` = `-Xmx` in production to avoid heap
  resize churn; choose/verify the GC per your JDK and C2M sizing guidance (**verify for your
  version**). C2M is memory-sensitive — undersized heap surfaces as `OutOfMemoryError` under load.
- **Run production domains in production mode** with an encrypted **boot-identity file** so servers
  start unattended under Node Manager.
- **Raise OS ulimits** (open files, processes) for the product user; low `nofile` limits cause
  intermittent, hard-to-diagnose failures under load.

## Security & operations

- **Least privilege:** dedicated OS product user owns the install/domain; distinct WebLogic admin
  and Node Manager credentials; rotate per policy. (SSL/keystore and SSO have their own solution —
  point to it, don't hand-roll.)
- **Back up before every change** — the domain home (config), plus note the OUAF product/config and
  DB state — and keep the rollback step in the change record. `DOMAIN_HOME` being outside
  `ORACLE_HOME` makes domain-only restore clean.
- **Keep environments parallel.** Build Dev → Test → Prod from the **same WLST scripts** with a
  per-environment `owls14c-scope.env`, so the domain that reaches production is the one you validated.
- **Change control for production**, always: certified stack, backup, change window, validation
  evidence (attach the Report), documented rollback.

## Validate continuously

- **Re-run Discovery/Validation/Report after every change** (server added, data source retargeted,
  JVM tuned, patch applied) so drift is caught by evidence, not by an incident.
- **Preview remediation before applying** — the Remediation script is **dry-run by default**;
  review its plan, take a backup, then `--apply`. Never let an automated fix touch a production
  domain unreviewed.
- **Treat the Report as your regression baseline** — a green Report before a change and a green
  Report after is the simplest proof you didn't regress the foundation.
