# 2. Requirements Guide — Oracle Customer to Meter (C2M) Installation & Multi-Environment Build

Verify every requirement before you start the Installation Guide. Each entry follows: **Description**,
**Why**, **Verify**, and **Implement if missing**. Category-wide prerequisites (entitlement, certified
stack, environment topology, tooling, change control, collaborating teams) are in
`global-requirements-oracle.md`; the requirements below are the ones specific to building a C2M
installation across Dev/Test/Prod. Placeholders are written without angle brackets (for example
`your-host`, `your-mount`, `your-db`).

> Version note: specifics such as C2M 25.4 / minimum 2.9.x, WebLogic 14c (14.1.2.x), Java 17, and Oracle
> Database 19c are **flagged "verify for your version"** — always confirm against Oracle's certification
> matrix on My Oracle Support (MOS) for your exact release.

## 2.1 Licensed C2M media and the certification matrix
- **Description:** The licensed C2M installation media (framework, product, and database components) for
  your release, and the matching **certification/compatibility matrix** that pins certified OS, Java,
  WebLogic, and Oracle Database versions together.
- **Why:** C2M/OUAF only supports certified combinations; the media and matrix are the authoritative
  inputs to the whole build.
- **Verify:** Confirm you can download the C2M framework, product, and database media for your release
  from Oracle Software Delivery / MOS, and locate the certification matrix for that release.
- **Implement if missing:** Obtain the entitlement and MOS access; do not proceed on uncertified media.

## 2.2 Certified WebLogic Server 14c installed on the application tier
- **Description:** **Oracle WebLogic Server 14c (14.1.2.x — verify for your version)** installed into an
  Oracle Home on each application-tier host, from the WLS/FMW distribution, before the C2M product
  install. C2M creates a **native** WebLogic domain into this install.
- **Why:** The C2M online application, inbound web services, and batch runtime are hosted in a WebLogic
  domain; the install expects a certified WebLogic Home present.
- **Verify:** Confirm the WebLogic Home exists and its version matches the matrix (for example inspect the
  registry/inventory or run the WLS version check). Confirm the OS product user can read it.
- **Implement if missing:** Install certified WebLogic 14c per Oracle's WebLogic 14.1.2 installation
  documentation before the C2M product step.

## 2.3 Certified Java (JDK) on the application tier
- **Description:** A certified **JDK — Java 17 for C2M 25.4 / 2.9.x (verify for your version)** installed
  on each application-tier host, with `JAVA_HOME` and `PATH` set for the product OS user.
- **Why:** OUAF utilities, WebLogic, and the C2M application all run on the certified JDK; a mismatched
  Java version breaks install and runtime.
- **Verify:** As the product OS user, run `java -version` and confirm it matches the certified JDK.
- **Implement if missing:** Install the certified JDK and set `JAVA_HOME`/`PATH` before installing.
- **Note:** The **database installer (`OraDBI`)** may require a specific Java per your release (some
  releases require an older JDK to run the DB install tool) — verify the DB install step's Java
  requirement in the C2M Database Administrator's Guide separately from the application-tier Java.

## 2.4 Oracle Database available, with schema accounts and Storage.xml
- **Description:** A reachable **Oracle Database (19c — verify for your version)** for each environment,
  plus the plan for the three C2M schema accounts — schema owner **`CISADM`**, application user
  **`CISUSER`**, read-only user **`CISREAD`** — and the DBA-supplied **`Storage.xml`** defining the
  tablespaces the C2M schema will use.
- **Why:** The C2M database installer (`OraDBI`) creates/loads the application schema into these accounts
  over the tablespaces named in `Storage.xml`; if a named tablespace is missing the install aborts.
- **Verify:** Confirm database connectivity (TNS/`tnsping`, SQL*Plus login), that a DBA will create the
  tablespaces named in your `Storage.xml`, and that you have (or can create) `CISADM`/`CISUSER`/`CISREAD`.
- **Implement if missing:** Have the DBA provision the database, tablespaces, and accounts, and hand you a
  populated `Storage.xml` before the database install step.

## 2.5 Product OS user, mount points, and file-system layout
- **Description:** A dedicated **product OS user (`cissys`)** on each application-tier host, and the
  planned **mount points** for the environment home (`$SPLEBASE`, under `/opt/oracle/spl/your-env`), the
  output directory (`$SPLOUTPUT`, under `/opt/oracle/splout/your-env`), and the **log mount point** — the
  log directory must already exist before the framework install.
- **Why:** OUAF is installed and run as the product user under `$SPLEBASE`; the installer requires the
  mount points (and an existing log directory) to lay down and configure the environment.
- **Verify:** Confirm the `cissys` account exists on each host, owns the mount points, and that the log
  mount point directory already exists.
- **Implement if missing:** Create the OS user and mount points and pre-create the log directory before
  running the installer.

## 2.6 Network access and ports between tiers
- **Description:** Network reachability between the application tier and the database (Oracle listener
  port), plus the planned **WebLogic ports** (Administration Server, Managed Server `c2m_server1`, and
  any SSL/IWS ports) open per environment and not already in use on the host.
- **Why:** The domain cannot start and the application cannot reach its schema without these paths; port
  collisions on a shared host block domain startup.
- **Verify:** From each app host confirm you can reach the DB listener; confirm the chosen WebLogic ports
  are free on the host (they are not already bound by another domain or service).
- **Implement if missing:** Open the firewall paths and choose free ports before creating the domain.

## 2.7 Per-environment build worksheet (Dev/Test/Prod inputs)
- **Description:** A completed **install worksheet per environment** capturing, for `C2MDEV`, `C2MTST`,
  and `C2MPRD`, the exact values the installer prompts for: environment name (`$SPLENVIRON`), mount
  points, WebLogic host and ports, WebLogic admin credentials, database name/host/service and schema
  user, and the keystore options.
- **Why:** The OUAF installer is prompt-driven; having every value decided up front is what makes the
  three builds consistent rather than improvised, and lets you script validation against known-expected
  values.
- **Verify:** Confirm a filled worksheet exists for each environment and that Test and Prod differ from
  Dev only in host/port/DB values, not in structure or object names.
- **Implement if missing:** Complete the worksheet from Oracle's installation-worksheet section of the
  C2M Installation Guide before running any install.

## 2.8 Backup, change control, and a non-production-first sequence
- **Description:** Verified **backups** (any existing domain config, OUAF product/config, and database)
  before disruptive steps, a **change window/approval** for the Production build, and agreement to build
  and prove **Dev then Test first**, Production last.
- **Why:** Installs and schema loads are high-impact; the solution follows Assess → Configure → Pilot →
  Validate → Expand with a documented rollback, and Production is only built after non-prod passes its
  gates.
- **Verify:** Confirm a backup/restore path and an approved change window for the Production install.
- **Implement if missing:** Establish backups and change control, and sequence Dev/Test before Prod,
  before touching Production.

---
### Requirements checklist
`Licensed media + certification matrix -> WebLogic 14c installed -> Certified Java -> Database + CISADM/CISUSER/CISREAD + Storage.xml -> Product OS user + mount points (log dir exists) -> Network + free ports -> Per-env worksheet -> Backup + change control + non-prod first`
