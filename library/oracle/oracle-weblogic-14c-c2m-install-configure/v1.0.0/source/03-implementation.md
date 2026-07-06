# Implementation Guide

This guide installs and configures **Oracle WebLogic Server 14c (14.1.1)** as the C2M middleware
foundation, in order:

**install WebLogic 14c → create the `c2m_domain` domain → configure Admin / managed servers +
Node Manager + machine → create the `C2MDataSource` data source → tune JVM / startup → validate.**

It follows **Assess → Configure → Pilot → Validate → Expand** with explicit **gates**. Do the whole
sequence on a **non-production environment first**; promote to production only under change control
with a verified backup. Every step names the same objects defined in the Solution Overview
(`c2m_domain`, `AdminServer`, `c2m_ms1`/`c2m_ms2`, `c2m_cluster`, `c2m_machine1`, `C2MDataSource`)
— adopt them or map to your convention **once** and reuse consistently.

Commands use placeholders **without angle brackets** (e.g. `your-oracle-home`, `your-db-host`,
`your-service`). Replace them with your values; do not leave placeholders in a built domain. Where a
value is release-dependent it is flagged **verify for your version**.

> **Two ways to do each configuration step.** WebLogic gives you the **Administration Console** (GUI)
> and **WLST** (scriptable). This guide shows **Admin Console navigation** and the equivalent **WLST**
> so the build is repeatable. For a new domain, prefer **WLST offline** (or the Configuration Wizard)
> to create it; use the Console/WLST-online for later edits. As always: **verify against the Oracle
> WebLogic 14.1.1 documentation** for your exact patch level — MOS-gated notes/patches are pointed to,
> not reproduced.

---

## Phase 0 — Assess (gate before you build)

1. **Confirm the requirements are met** (see Requirements Guide): certified WebLogic 14c installer +
   JDK, sized host, OS product account, planned free ports, reachable C2M database + service,
   WebLogic admin credential, WLST/shell/SQL tooling, change control + backup.
2. **Capture the environment — run Discovery** (read-only): inventory the host, JDK, any existing
   `ORACLE_HOME`/domains, free ports, and DB reachability.
   ```
   java weblogic.WLST OWLS14C-Discovery.py    # or: run before install with --pre-install
   ```
3. **Pin your targets — run ScopeHelper**: record the domain name, server names/ports, machine,
   Node Manager port, and the data-source coordinates the later scripts will act on.
   ```
   ./OWLS14C-ScopeHelper.sh --interactive     # writes owls14c-scope.env
   ```

> **Gate 0 → Configure:** certified stack confirmed, host sized, ports free, database reachable,
> backup/rollback path in place. If any fails, **stop** and remediate — do not build on a shaky base.

---

## Phase 1 — Configure

### Step 1 — Install WebLogic Server 14c

As the **OS product account**, with `JAVA_HOME` set to the certified JDK:

1. **Launch the installer** into your chosen `ORACLE_HOME` (outside any future domain home):
   ```
   $JAVA_HOME/bin/java -jar fmw_14.1.1.0.0_wls_generic.jar
   ```
   (Installer filename is **verify for your version** — use the file your entitlement provides.)
2. In the installer: set **Installation Location** = `your-oracle-home`, choose the install type the
   C2M release requires (WebLogic Server or Fusion Middleware Infrastructure — **verify for your
   version**), let it run prerequisite checks, and complete.
3. **Silent / repeatable install** (recommended for Test/Prod parity) — generate and reuse a
   response file:
   ```
   $JAVA_HOME/bin/java -jar fmw_14.1.1.0.0_wls_generic.jar -silent \
       -responseFile your-oracle-home/install.rsp -invPtrLoc your-oracle-home/oraInst.loc
   ```
4. **Verify the install:** `ORACLE_HOME` populated, and:
   ```
   $ORACLE_HOME/oracle_common/common/bin/wlst.sh    # WLST launches
   ```

> **Do not** create the domain into `ORACLE_HOME`. Keep `DOMAIN_HOME` separate so patching/reinstall
> of the binaries never disturbs `c2m_domain`.

### Step 2 — Create the `c2m_domain` domain

Pick **one** method; both produce the same domain.

**Option A — Configuration Wizard (GUI):**
```
$ORACLE_HOME/oracle_common/common/bin/config.sh
```
Then: **Create a New Domain** → Domain Location = `your-domain-home/c2m_domain` → select the
**Basic WebLogic Server Domain** template (add the Coherence Cluster extension if your C2M topology
uses Coherence — see the Coherence/JMS/IWS solution) → set the **admin** username/password →
**Domain Mode = Production** and the **certified JDK** → (Advanced) select **Administration
Server, Node Manager, Topology**. Continue into Step 3 for servers/Node Manager/machine, then
**Create**.

**Option B — WLST offline (scriptable, preferred for repeatability):**
```python
# create_c2m_domain.py  — run: java weblogic.WLST create_c2m_domain.py
readTemplate('your-oracle-home/wlserver/common/templates/wls/wls.jar')
cd('/Servers/AdminServer')
set('ListenAddress', 'your-admin-host')      # a real host/IP, not localhost
set('ListenPort', 7001)
cd('/Security/base_domain/User/weblogic')    # set admin credentials
cmo.setName('your-admin-user')
cmo.setPassword('your-admin-password')
setOption('ServerStartMode', 'prod')         # production mode
setOption('OverwriteDomain', 'true')
writeDomain('your-domain-home/c2m_domain')
closeTemplate()
exit()
```

**Verify:** `DOMAIN_HOME` (`your-domain-home/c2m_domain`) exists with `bin/`, `config/config.xml`,
and `nodemanager/` populated.

### Step 3 — Configure Admin Server, managed server(s), machine

If you used the Wizard you can do this inline; either way, here is the WLST-online form (start
`AdminServer` first — Step 5 — then connect and edit). **Admin Console** path is given for each.

1. **Managed server `c2m_ms1`** — *Console:* **Environment → Servers → New** → Name `c2m_ms1`,
   Listen Address = `your-ms1-host`, Listen Port = your planned port, **not** part of a cluster yet
   (or assign to `c2m_cluster`). *WLST:*
   ```python
   edit(); startEdit()
   cmo.createServer('c2m_ms1')
   cd('/Servers/c2m_ms1')
   cmo.setListenAddress('your-ms1-host'); cmo.setListenPort(7003)
   ```
2. **(HA) Cluster `c2m_cluster` + second server `c2m_ms2`** — *Console:* **Environment →
   Clusters → New** (`c2m_cluster`), then create `c2m_ms2` and set each server's **Cluster** to
   `c2m_cluster`. *WLST:*
   ```python
   cmo.createCluster('c2m_cluster')
   cmo.createServer('c2m_ms2')
   cd('/Servers/c2m_ms2'); cmo.setListenAddress('your-ms2-host'); cmo.setListenPort(7005)
   cd('/Servers/c2m_ms1'); cmo.setCluster(getMBean('/Clusters/c2m_cluster'))
   cd('/Servers/c2m_ms2'); cmo.setCluster(getMBean('/Clusters/c2m_cluster'))
   ```
3. **Machine `c2m_machine1`** — *Console:* **Environment → Machines → New** (Unix Machine),
   then **Node Manager** tab → Type `SSL` (or `Plain`), Listen Address = **specific host/IP, not
   `localhost`**, Listen Port = your Node Manager port. Assign servers under the machine's
   **Servers** tab. *WLST:*
   ```python
   cmo.createUnixMachine('c2m_machine1')
   cd('/Machines/c2m_machine1/NodeManager/c2m_machine1')
   cmo.setListenAddress('your-nm-host'); cmo.setListenPort(5556); cmo.setNMType('SSL')
   cd('/Servers/AdminServer'); cmo.setMachine(getMBean('/Machines/c2m_machine1'))
   cd('/Servers/c2m_ms1');     cmo.setMachine(getMBean('/Machines/c2m_machine1'))
   # (c2m_ms2 likewise for HA)
   save(); activate()
   ```

> **Keep the C2M application off `AdminServer`.** The C2M/OUAF EAR (`SPLWeb`/`SPLService`) is
> deployed to the **managed server(s)** — deploying it in a separate solution. Here we only build
> the domain that receives it.

### Step 4 — Configure the per-domain Node Manager

The **per-domain** Node Manager config already lives in `DOMAIN_HOME/nodemanager` after domain
creation. Finalize it and enroll the domain:

1. **Set Node Manager properties** in `DOMAIN_HOME/nodemanager/nodemanager.properties`:
   `ListenAddress=your-nm-host` (not `localhost`), `ListenPort=5556`, `SecureListener=true` (SSL) or
   `false` (Plain, non-production only), and — so Node Manager can start managed servers itself —
   `StartScriptEnabled=true`.
2. **Enroll the domain with Node Manager** (from WLST **online**, connected to `AdminServer`) so it
   trusts and can manage the servers:
   ```python
   nmEnroll('your-domain-home/c2m_domain', 'your-domain-home/c2m_domain/nodemanager')
   ```
3. **Node Manager type — per-domain vs per-host:** this solution uses **per-domain** (self-contained
   under `DOMAIN_HOME`), the modern default. Choose **per-host** only if a site standard requires one
   Node Manager serving multiple domains on the host; if so, configure it under `ORACLE_HOME` and
   register each domain — see Oracle's *Administering Node Manager* (14.1.1) documentation.

### Step 5 — Start Node Manager and the Administration Server

From `DOMAIN_HOME/bin`, as the product user:

1. **Node Manager:**
   ```
   nohup ./startNodeManager.sh > $DOMAIN_HOME/nm.out 2>&1 &
   ```
2. **Administration Server:**
   ```
   nohup ./startWebLogic.sh > $DOMAIN_HOME/admin.out 2>&1 &
   ```
   In production mode you are prompted for the admin credential on first start. Then create a
   **boot-identity file** so it (and the managed servers) start unattended under Node Manager —
   create `DOMAIN_HOME/servers/AdminServer/security/boot.properties` with `username=` / `password=`
   (WebLogic encrypts it on next start); repeat per managed server directory.
3. **Reach the Console:** `http://your-admin-host:7001/console` — log in with the admin credential.

### Step 6 — Create the `C2MDataSource` JDBC data source

Point WebLogic at the C2M database. Choose **generic** (single-instance DB) or **Active GridLink**
(Oracle **RAC**).

*Console:* **Services → Data Sources → New → Generic Data Source** (or **GridLink**). Name =
`C2MDataSource`, JNDI Name = `jdbc/C2MDataSource`, Database Type = **Oracle**. Driver: the Oracle
Thin driver (XA or non-XA per your transaction needs). Enter the connection: host = `your-db-host`,
port = `your-db-port`, **service name** = `your-service` (use service, not SID, for RAC). Set the
schema credentials. **Target** the data source at **`c2m_ms1`** (and `c2m_cluster` for HA) — **not**
`AdminServer`. On the connection-pool tab set **Test Connections On Reserve = true** with **Test
Table Name = `SQL ISVALID`** (or `SQL SELECT 1 FROM DUAL`), and size **Initial/Max Capacity** for
your load (**verify for your version** against C2M sizing).

*WLST (generic, online):*
```python
edit(); startEdit()
cmo.createJDBCSystemResource('C2MDataSource')
cd('/JDBCSystemResources/C2MDataSource/JDBCResource/C2MDataSource')
cmo.setName('C2MDataSource')
cd('.../JDBCDataSourceParams/C2MDataSource'); set('JNDINames', jarray.array([String('jdbc/C2MDataSource')], String))
cd('.../JDBCDriverParams/C2MDataSource')
cmo.setUrl('jdbc:oracle:thin:@//your-db-host:your-db-port/your-service')
cmo.setDriverName('oracle.jdbc.OracleDriver')
cmo.setPasswordEncrypted('your-schema-password')
cd('.../Properties/C2MDataSource'); cmo.createProperty('user'); cd('Properties/user'); cmo.setValue('your-schema-user')
cd('.../JDBCConnectionPoolParams/C2MDataSource')
cmo.setTestConnectionsOnReserve(true); cmo.setTestTableName('SQL ISVALID')
cmo.setInitialCapacity(5); cmo.setMaxCapacity(30)
cd('/SystemResources/C2MDataSource'); set('Targets', jarray.array([ObjectName('com.bea:Name=c2m_ms1,Type=Server')], ObjectName))
save(); activate()
```
(For **GridLink/RAC**, use the RAC SCAN/service URL and enable ONS/FAN per Oracle's *Administering
JDBC Data Sources* 14.1.1.) **Verify the target list** does not include `AdminServer`.

### Step 7 — Tune JVM / startup

C2M managed-server JVMs are memory- and GC-sensitive; set this deliberately rather than accepting
template defaults.

1. **Heap / GC** — set `USER_MEM_ARGS` for the managed server(s) (do not hand-edit `startWebLogic.sh`;
   override in `setUserOverrides.sh` / `setUserOverridesLate.sh` under `DOMAIN_HOME/bin`, which
   `setDomainEnv.sh` sources):
   ```
   # setUserOverrides.sh  (example — size per your host & C2M sizing guidance: verify for your version)
   USER_MEM_ARGS="-Xms4g -Xmx4g -XX:MetaspaceSize=512m -XX:MaxMetaspaceSize=512m"
   export USER_MEM_ARGS
   ```
2. **Production mode** — confirm the domain is in production mode (set at creation). Confirm
   **`StartScriptEnabled=true`** so Node Manager applies these startup args when it launches servers.
3. **Boot identity** — confirm `boot.properties` exists for each server (Step 5) so Node Manager
   starts them unattended.
4. **Start managed servers** — via Node Manager (Console: **Environment → Servers → Control →
   Start**, or WLST `nmStart('c2m_ms1')`), or directly for a quick pilot:
   ```
   nohup ./startManagedWebLogic.sh c2m_ms1 t3://your-admin-host:7001 > $DOMAIN_HOME/ms1.out 2>&1 &
   ```

> **Gate 1 → Pilot:** WebLogic installed, `c2m_domain` created, Admin + managed server(s) + machine
> configured, per-domain Node Manager enrolled, `C2MDataSource` created with Test-On-Reserve, JVM
> args set. No template placeholders remain. Configuration validates in WLST/Console without errors.

---

## Phase 2 — Pilot (one non-production node)

Bring the domain up on **one** environment/node and confirm the baseline:

- **Node Manager** running and reachable from the Admin Console/WLST.
- **`AdminServer`** and **`c2m_ms1`** both in state **`RUNNING`**.
- **`C2MDataSource`** targeted at `c2m_ms1`, **Test = passed** (Console **Monitoring → Testing**,
  or WLST test).
- **JVM args** as intended on `c2m_ms1` (heap/metaspace reflect `USER_MEM_ARGS`).

> **Gate 2 → Validate:** a clean **single-node** domain — servers `RUNNING`, data source reserving
> connections, Node Manager in control — **before** any horizontal scale.

---

## Phase 3 — Validate (evidence, not assumption)

Run the scripts and confirm against the Testing Guide:

```
java weblogic.WLST OWLS14C-Validation.py     # servers RUNNING, DS test, NM reachable, JVM args
java weblogic.WLST OWLS14C-Report.py         # health/coverage summary
```

- **Validation** must report: servers `RUNNING`, `C2MDataSource` test **pass**, Node Manager
  **reachable**, JVM args **as configured**, no `config.xml` placeholders, machine not on
  `localhost`.
- If Validation flags a fixable drift (e.g. Test-On-Reserve off, data source on `AdminServer`,
  `StartScriptEnabled=false`), preview and apply with **Remediation** — **dry-run first**:
  ```
  ./OWLS14C-Remediation.sh                 # DRY-RUN: prints what it would change
  ./OWLS14C-Remediation.sh --apply         # apply, after review + backup
  ```

> **Gate 3 → Expand:** Validation is green with evidence (Report attached to the change record).

---

## Phase 4 — Expand

Scale and promote under change control, **re-validating** at each step:

1. **Add the second managed server / cluster** (`c2m_ms2` in `c2m_cluster`), target `C2MDataSource`
   at the cluster, start via Node Manager, re-run Validation.
2. **Add machines / nodes** for additional hosts (each with its own Node Manager and machine
   definition), keeping to a **specific IP/hostname** per machine.
3. **Promote the pattern across environments** (Dev → Test → Prod) using the same WLST scripts and
   `owls14c-scope.env` values per environment, each behind its own change approval and backup.
4. **Hand off to the layers above** — the domain is now ready to **receive the C2M/OUAF deployment**
   (`SPLWeb`/`SPLService`), Coherence/JMS/IWS, batch threadpools, SSO/SSL, and monitoring, each
   covered by its own solution.

---

## Rollback (any phase)

- **Config change (data source, server, JVM):** WebLogic keeps `config.xml` backups
  (`config/config.xml.booted` / pending edits). Revert the edit session or restore the domain
  config from your pre-change backup, then restart the affected server.
- **Domain build gone wrong:** because `DOMAIN_HOME` is **outside** `ORACLE_HOME`, remove/recreate
  the domain without touching the binaries; restore from the domain backup if needed.
- Always take a **verified backup of the domain home** (and note the DB/OUAF state) before a
  production change; record the rollback step in the change record.
