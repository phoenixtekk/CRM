# Requirements Guide

These requirements are **specific to installing and configuring WebLogic 14c as the C2M
middleware foundation**. They are in addition to the Oracle-category **Global Requirements**
(licensed C2M/WebLogic entitlement, certified platform stack, Dev/Test/Prod topology,
administrative access & tooling, change control/backup/pilot, collaborating teams) — verify those
first, then these.

Each requirement below states **Description**, **Why**, how to **Verify**, and how to **Implement
if missing**. Where a value depends on the release, it is flagged **verify for your version**
against Oracle's certification matrix on My Oracle Support (MOS) — never assumed.

---

## 1. Certified WebLogic 14c install media + a certified JDK

- **Description:** The **Oracle WebLogic Server 14c (14.1.1)** installer (the generic `.jar` /
  Fusion Middleware Infrastructure installer, per what the C2M release requires) and a **certified
  JDK** (a supported Oracle JDK / Java SE version) for that WebLogic + C2M combination.
- **Why required:** WebLogic 14c installs into an `ORACLE_HOME` using a JDK; C2M/OUAF is only
  supported on **certified** WebLogic ↔ JDK combinations, and an uncertified JDK causes install and
  runtime failures and loses supportability.
- **How to verify:** Confirm the WebLogic 14.1.1 installer is downloaded from Oracle
  (eDelivery / MOS) and its checksum matches; run `java -version` and confirm the JDK version and
  vendor are on the C2M release's certification matrix. **Verify for your version** — the exact
  WebLogic 14.1.1.x patch level and JDK build are pinned per C2M release.
- **How to implement if missing:** Obtain the certified installer and JDK via your entitlement;
  install the JDK first and set `JAVA_HOME` before installing WebLogic.

## 2. Host meeting WebLogic 14c + C2M sizing (CPU, memory, disk, OS)

- **Description:** A host (physical/VM/container) running a **certified OS** with enough **CPU,
  RAM, and disk** for the WebLogic 14c binaries, the `c2m_domain` domain home, JVM heaps for the
  Admin + managed server(s), and OUAF product/log/temp space.
- **Why required:** C2M managed-server JVMs are memory-hungry; under-provisioned memory or disk
  causes `OutOfMemoryError`, failed domain creation, or servers that will not stay `RUNNING`.
- **How to verify:** Check OS version against the certification matrix; confirm free memory covers
  the planned heaps for `AdminServer` + `c2m_ms1` (+ `c2m_ms2`) with headroom, and disk for
  `ORACLE_HOME`, `DOMAIN_HOME`, and logs. Confirm required OS packages/kernel settings and file-
  descriptor / process **ulimits** for the product user.
- **How to implement if missing:** Right-size the host, raise ulimits (e.g. `nofile`), and add
  disk before building the domain. Heap sizing is **verify for your version** against C2M sizing
  guidance for your user/batch load.

## 3. OS product account + directory layout (`ORACLE_HOME`, `DOMAIN_HOME`)

- **Description:** A dedicated **OS product account** (the OUAF product user, e.g. `cissys`) that
  owns the WebLogic install and the domain, with a planned layout: `ORACLE_HOME` for the WebLogic
  14c binaries and a **separate** `DOMAIN_HOME` for `c2m_domain` **outside** `ORACLE_HOME`.
- **Why required:** Running WebLogic and OUAF under a single, correctly-permissioned product
  account is required for supportability; keeping the domain outside the binaries lets you patch or
  reinstall WebLogic without disturbing `c2m_domain`.
- **How to verify:** Confirm the product user exists, owns (or can create) both paths, and that the
  paths are on adequately-sized filesystems. Confirm the account's shell profile sets `JAVA_HOME`
  and can reach WebLogic's `common/bin`.
- **How to implement if missing:** Create the product user/group, provision the two directory trees
  with correct ownership, and place the domain home outside `ORACLE_HOME`.

## 4. Network reachability + planned ports (Admin, managed, Node Manager)

- **Description:** Reachable, **non-conflicting** listen ports for the `AdminServer` (e.g. 7001),
  each managed server, the **Node Manager**, and (if used) SSL ports and the Coherence unicast
  port — plus DNS/hostnames the servers and machine bind to.
- **Why required:** WebLogic servers and Node Manager bind to specific host:port pairs; a port in
  use by another service, or a machine pointed at `localhost` instead of a real IP/hostname, breaks
  startup, Node Manager control, and (later) clustering/Coherence.
- **How to verify:** Confirm each planned port is **free** on the host (e.g. `ss -tlnp` /
  `netstat`), that hostnames resolve, and that firewall rules allow admin traffic and inter-server
  traffic. Confirm the machine will use a **specific IP/hostname**, not `localhost`.
- **How to implement if missing:** Reserve free ports, add DNS/hosts entries, open firewall rules,
  and record the port map before creating the domain (the ScopeHelper script captures it).

## 5. C2M database reachable + a schema/service to point the data source at

- **Description:** A running **Oracle Database** hosting the C2M schema, reachable from the WebLogic
  host, with the connection coordinates the `C2MDataSource` will use: host(s)/SCAN, port, **service
  name** (not SID for RAC), and the schema credentials.
- **Why required:** `C2MDataSource` is the connection pool OUAF uses to reach C2M's data; if the
  database is unreachable or the service/credentials are wrong, the data source's **Test-On-
  Reserve** fails and C2M cannot start clean.
- **How to verify:** From the WebLogic host, confirm TCP reachability to the DB listener and a
  successful login to the C2M service (e.g. `sqlplus user@//host:port/service`, or `tnsping`).
  Confirm whether the target is single-instance or **RAC** (drives GridLink vs generic data source).
- **How to implement if missing:** Obtain the correct service name and schema credentials from the
  DBA, open network/firewall paths, and confirm the JDBC driver version is certified for that DB
  release (**verify for your version**).

## 6. WebLogic admin credentials + a boot-identity plan

- **Description:** The **WebLogic administrator** username/password to be set at domain creation,
  the plan for the **domain in production mode**, and a **boot-identity file** (`boot.properties`)
  so the Admin and managed servers can start unattended under Node Manager.
- **Why required:** Production-mode domains prompt for credentials at startup; without a boot
  identity, Node Manager cannot start servers unattended and automated startup/restart fails.
- **How to verify:** Confirm the admin credential is chosen and stored per your secrets policy, and
  that a boot-identity approach is agreed (encrypted `boot.properties` under the server's
  `security` directory).
- **How to implement if missing:** Define the admin credential, plan production mode at creation
  time, and create the boot-identity file after first start (covered in the Implementation Guide).

## 7. Administrative tooling: WLST, shell, SQL client

- **Description:** Working **WLST (Jython)** from the WebLogic install, OS **shell** access as the
  product user, and a **SQL client** (SQL*Plus / SQLcl) — the interfaces this solution's steps and
  scripts use. (Automation here is WLST/shell/SQL, **not** PowerShell.)
- **Why required:** Domain creation, Node Manager enrollment, data-source creation, and validation
  are performed through these tools; the Discovery/Validation/Report/Remediation scripts are WLST
  and shell.
- **How to verify:** Confirm `java weblogic.WLST` (or `ORACLE_HOME/oracle_common/common/bin/wlst.sh`)
  launches, that the product user has shell access to `ORACLE_HOME`/`DOMAIN_HOME`, and that the SQL
  client connects to the C2M service.
- **How to implement if missing:** Install/verify the WebLogic tooling and a SQL client on the host
  and grant the product user the needed access.

## 8. Change control, backup & a non-production pilot

- **Description:** Per the Global Requirements: a **change-control** approval for any production
  domain, verified **backups** (domain config, OUAF product/config, database) before disruptive
  actions, and a **non-production environment** to build and validate `c2m_domain` on **first**.
- **Why required:** The domain is the foundation the whole C2M stack sits on; a mis-built or
  mis-changed domain is high-impact. Every step follows **Assess → Configure → Pilot → Validate →
  Expand** with a documented rollback.
- **How to verify:** Confirm a backup/restore path for the domain home and a change window/approval
  for any production build or change.
- **How to implement if missing:** Establish backups and change control, and stand up the
  non-production environment, before touching production.

---

*Meeting these — a certified WebLogic 14c installer + JDK, a sized host, the product account and
directory layout, reachable ports and database, admin credentials and boot-identity plan, the
WLST/shell/SQL toolchain, and change control with a pilot — is the gate to Configure. Run the
**Discovery** and **ScopeHelper** scripts to capture the environment and pin targets before you
build the domain.*
