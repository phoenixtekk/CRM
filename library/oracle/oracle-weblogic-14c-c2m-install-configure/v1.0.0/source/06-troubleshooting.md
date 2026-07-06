# Troubleshooting Guide

The common failures when installing and configuring WebLogic 14c for C2M, organized by
**symptom → likely cause → resolution**. Start with the read-only **Discovery** and **Validation**
scripts — they surface most of these mechanically. Fixable config drift can be previewed and applied
with the **Remediation** script (**dry-run first**, backup before `--apply`).

Placeholders are **without angle brackets** (`your-domain-home`, `your-db-host`, `your-service`) —
substitute your values. Version-specific behavior is **verify for your version** against Oracle's
WebLogic 14.1.1 documentation; MOS-gated notes/patches are pointed to, not reproduced.

---

## Install & domain creation

### Installer fails or WLST won't launch after install
- **Likely cause:** wrong/uncertified JDK, `JAVA_HOME` not set, insufficient disk, or wrong
  installer type for the C2M release.
- **Resolution:** confirm `java -version` is the **certified** JDK and `JAVA_HOME` points at it;
  ensure free disk for `ORACLE_HOME`; re-run the correct installer (**verify for your version**).
  Verify with `$ORACLE_HOME/oracle_common/common/bin/wlst.sh`.

### `config.sh` / WLST domain creation errors, or domain half-created
- **Likely cause:** domain home path not writable by the product user, path **inside** `ORACLE_HOME`,
  or a template mismatch.
- **Resolution:** create `DOMAIN_HOME` **outside** `ORACLE_HOME`, owned by the product user; re-run
  creation with `setOption('OverwriteDomain','true')` (WLST) after clearing the partial domain.
  Confirm the selected template matches your topology (add Coherence extension only if used).

### `config.xml` still contains `localhost` or placeholder listen addresses
- **Likely cause:** accepted defaults in the Wizard, or WLST script left placeholders.
- **Resolution:** set **specific host/IP** listen addresses for `AdminServer`, managed servers, and
  the machine/Node Manager. `localhost` breaks Node Manager control and clustering. Validation flags
  this; Remediation can correct the machine address.

## Administration Server

### AdminServer won't start / prompts endlessly for credentials
- **Likely cause:** production mode with **no boot-identity file**, or a wrong/forgotten admin
  credential.
- **Resolution:** create `DOMAIN_HOME/servers/AdminServer/security/boot.properties` with
  `username=` / `password=` (WebLogic encrypts on next start). If the credential is lost, reset it
  via the offline security tooling (see Oracle docs). Check `admin.out` /
  `servers/AdminServer/logs/AdminServer.log` for the actual error.

### AdminServer starts but Console is unreachable
- **Likely cause:** listen port in use / firewalled, or bound to the wrong address.
- **Resolution:** confirm the listen port is free (`ss -tlnp`) and open in the firewall; confirm the
  listen address is the host you're browsing to; try `http://your-admin-host:7001/console`.

## Node Manager

### Node Manager "not reachable" from Console/WLST
- **Likely cause:** Node Manager not running, listening on `localhost`, port mismatch, or the domain
  never enrolled.
- **Resolution:** start it (`DOMAIN_HOME/bin/startNodeManager.sh`); set
  `ListenAddress=your-nm-host` (not `localhost`) and the correct `ListenPort` in
  `nodemanager.properties`; enroll the domain: WLST `nmEnroll('your-domain-home/c2m_domain',
  'your-domain-home/c2m_domain/nodemanager')`. Test with `nmConnect(...)`.

### Managed server starts in foreground but not via Node Manager
- **Likely cause:** `StartScriptEnabled=false`, so Node Manager doesn't run the start script (and
  your JVM args don't apply either).
- **Resolution:** set `StartScriptEnabled=true` in `nodemanager.properties`, restart Node Manager,
  and start the server via `nmStart('c2m_ms1')` / Console **Control → Start**. Remediation can set
  this flag.

### Node Manager SSL / trust errors
- **Likely cause:** `SecureListener=true` without matching trust between the domain and Node
  Manager, or a stale enrollment.
- **Resolution:** re-run `nmEnroll` to re-establish trust; confirm the machine's Node Manager type
  (SSL vs Plain) matches `nodemanager.properties`. (Full keystore/SSL hardening is a separate
  solution.)

## Managed servers

### Managed server won't reach RUNNING (stuck in STARTING/ADMIN/FAILED)
- **Likely cause:** data-source failure at boot, JVM `OutOfMemoryError`, port conflict, or a
  deployment error (out of scope here).
- **Resolution:** read `servers/c2m_ms1/logs/c2m_ms1.log`. If the data source is failing, fix it
  (below). If OOM, raise heap (`USER_MEM_ARGS`). If a port conflict, pick a free port. Confirm the
  server isn't inadvertently hosting the C2M app *and* admin duties.

### C2M app accidentally deployed to AdminServer
- **Likely cause:** wrong deployment target chosen (application deployment is a separate solution,
  but the mistake surfaces here as admin instability).
- **Resolution:** target the C2M application and its data source at the **managed server(s)/
  cluster**, never `AdminServer`. Validation flags data sources mis-targeted at `AdminServer`.

## Data sources (`C2MDataSource`)

### Data-source test fails / connections can't be reserved
- **Likely cause:** wrong URL (SID vs **service name**), bad schema credentials, DB/listener down,
  network/firewall block, or uncertified driver.
- **Resolution:** confirm the DB round-trip **outside** WebLogic first —
  `sqlplus your-schema-user@//your-db-host:your-db-port/your-service` or `tnsping`. Then fix the
  data-source URL to use the **service name**, correct the credentials, and confirm the JDBC driver
  is certified for the DB release (**verify for your version**).

### Intermittent stale-connection errors under load
- **Likely cause:** **Test Connections On Reserve** disabled, so dead connections are handed out
  after a DB blip; or pool too small.
- **Resolution:** enable Test-On-Reserve with a valid **Test Table Name**
  (`SQL ISVALID` / `SQL SELECT 1 FROM DUAL`); raise Initial/Max Capacity per load
  (**verify for your version**). Remediation can enable Test-On-Reserve.

### RAC failover not working
- **Likely cause:** a **generic** data source (or SID-based URL) against a RAC database instead of
  **Active GridLink** with FAN/ONS.
- **Resolution:** use an Active GridLink data source with the RAC SCAN/service URL and ONS/FAN
  enabled (see Oracle *Administering JDBC Data Sources* 14.1.1).

## JVM / startup / memory

### `OutOfMemoryError` (heap or metaspace) on a managed server
- **Likely cause:** heap/metaspace left at template defaults, undersized for C2M's memory profile.
- **Resolution:** set `USER_MEM_ARGS` in `DOMAIN_HOME/bin/setUserOverrides.sh` (e.g. pin
  `-Xms`=`-Xmx`, size metaspace), ensure `StartScriptEnabled=true` so it applies via Node Manager,
  restart the server. Right-size per C2M sizing guidance (**verify for your version**).

### Tuned JVM args don't take effect
- **Likely cause:** args set only in a hand-edited `startWebLogic.sh` (lost on regeneration), or
  `StartScriptEnabled=false` so Node Manager ignores the start script.
- **Resolution:** put args in `setUserOverrides.sh` (sourced by `setDomainEnv.sh`), set
  `StartScriptEnabled=true`, restart via Node Manager, and confirm the running heap in Console
  **Monitoring → Performance**.

### Intermittent failures under load, no obvious config cause
- **Likely cause:** OS **ulimits** (open files / processes) too low for the product user.
- **Resolution:** raise `nofile`/process limits for the product user and restart the servers.

---

## When to escalate

- **MOS-gated** issues (a specific patch, certification question, or product bug) — raise a Service
  Request with My Oracle Support; the exact patch/note is entitlement-gated and pointed to, not
  reproduced here.
- **Cross-layer** problems (application deployment, Coherence/JMS/IWS, SSO/SSL, batch, DB tuning) —
  those belong to their own solutions; this guide covers the **domain/middleware foundation** only.
- Always capture the **Report** output and the relevant server / Node Manager logs before escalating,
  and confirm the change record's backup/rollback path is intact.
