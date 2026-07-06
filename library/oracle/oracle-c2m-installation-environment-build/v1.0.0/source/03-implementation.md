# 3. Installation Guide — Oracle Customer to Meter (C2M) Installation & Multi-Environment Build

Follow these steps in order, **per environment**, building `C2MDEV` first, then `C2MTST`, then
`C2MPRD` under change control. Work as the product OS user **`cissys`** on the application tier and with
the DBA for the database step. The supplied scripts assist at the read-only and validation steps; the
remediation script is dry-run by default.

Exact installer prompts, menu-item numbers, default ports, patch/rollup numbers, and the certification
matrix are **Oracle's and version-specific** — this guide gives the correct ordered procedure and the
named objects, and points to Oracle's C2M Installation Guide, C2M Database Administrator's Guide, OUAF
Server Administration Guide, and the WebLogic 14.1.2 documentation for the exact screens. Placeholders
are written without angle brackets (for example `your-host`, `your-db`, `your-mount`). Every version
specific below is flagged **"verify for your version."**

> Model: certify the stack, install the framework, install the product, create/verify the WebLogic
> domain, load the database schema, configure the environment, validate — proven on `C2MDEV` and
> `C2MTST` before `C2MPRD`. Standard model: **Assess → Configure → Pilot → Validate → Expand.**

Named objects produced/used by this guide (reuse these exact names):
- Environments: `C2MDEV`, `C2MTST`, `C2MPRD` (`$SPLENVIRON`)
- Product home: `$SPLEBASE` = `/opt/oracle/spl/your-env`; output: `$SPLOUTPUT` = `/opt/oracle/splout/your-env`
- WebLogic domain `c2m_domain`, Admin Server `AdminServer`, Managed Server `c2m_server1`
- DB accounts `CISADM` (owner), `CISUSER` (app), `CISREAD` (read-only); security role `cisusers`

## Step 0 — Assess: confirm prerequisites and back up (Assess)
1. Confirm every item in the Requirements Guide for the environment you are about to build: certified
   media + matrix, WebLogic 14c installed, certified Java, database + accounts + `Storage.xml`, product
   OS user + mount points (log directory already exists), free WebLogic ports, and a completed
   worksheet.
2. Run `OC2MINST-Discovery.sh` on the target host to capture the starting state read-only: OS user,
   `JAVA_HOME`/`java -version`, WebLogic Home and version, mount points and free space, listener
   reachability to `your-db`, and whether the chosen WebLogic ports are free. Save the output as the
   `Build Baseline – your-env – Assess` record.
3. For any rebuild or for Production, take verified **backups** first (existing `$SPLEBASE`, any existing
   domain config, and the database) and confirm the restore path. This is the rollback anchor.
4. Set the shell for the install: as `cissys`, ensure `JAVA_HOME` and `PATH` point at the certified JDK
   (Java 17 — verify for your version).

**Gate:** all prerequisites present, baseline captured, backups verified. Do not proceed otherwise.

## Step 1 — Install the OUAF framework (Configure)
1. Extract the framework media to a temporary directory and change into it (for example
   `your-temp/FW-Vxx`).
2. Run the installer as `cissys`: `ksh ./install.sh` (UNIX) or `install.cmd` (Windows). The installer is
   an interactive, menu-driven utility; drive it from your completed worksheet. Verify for your version.
3. Complete the framework menu blocks in order (numbers vary by release — **verify for your version**):
   - **Environment ID, Roles, Third-Party Software** — environment name (`$SPLENVIRON`, e.g. `C2MDEV`),
     Java Home, WebLogic Home.
   - **Keystore Options** — the OUAF keystore (store type JCEKS, alias `ouaf.system`, HMAC alias
     `ouaf.system.hmac`; accept documented defaults unless you have a keystore standard).
   - **Environment Installation Options** — the environment **mount point** (`$SPLEBASE` under
     `/opt/oracle/spl/C2MDEV`), the **log mount point** (must already exist), output directory
     (`$SPLOUTPUT`), and web application server type **WebLogic**.
   - **Environment parameters** — web server host/ports, database name and schema user; these are written
     to `$SPLEBASE/etc/ENVIRON.INI`. Press **P** to proceed.
4. The installer automatically runs **`initialSetup.sh`** (in `$SPLEBASE/bin`), which builds the
   configuration files, keystore, and WAR/EAR from the ENVIRON.INI values, then runs **`splenviron.sh -e
   your-env`** to set the environment variables.
5. **Do not hand-edit `ENVIRON.INI`.** To change any value later, re-run `configureEnv.sh` then
   `initialSetup.sh` so the templates are regenerated consistently.

**Gate:** framework install completes with no errors; `$SPLEBASE/etc/ENVIRON.INI` exists and names the
correct environment, mount points, and database.

## Step 2 — Install the C2M product application (Configure)
1. In a new session, initialize the environment: `$SPLEBASE/bin/splenviron.sh -e your-env` (e.g.
   `C2MDEV`). Stop the environment if it is running.
2. Extract the C2M product media (for example `jar -xvf C2M-Vxx-MultiPlatform.jar`) and change into the
   product install directory.
3. Run `ksh ./install.sh` (UNIX) / `install.cmd` (Windows). On the configuration menu, if no changes are
   needed, choose **P** to proceed. Verify for your version.
4. Re-apply configuration and rebuild templates:
   ```
   splenviron.sh -e your-env
   configureEnv.sh            # review values; type P and Enter if no changes
   splenviron.sh -e your-env
   initialSetup.sh            # rebuilds config/EAR from ENVIRON.INI
   ```
5. Review and, per Oracle's guidance, incorporate `$SPLEBASE/tools/examples/bin/setUserOverride.sh` into
   the WebLogic domain start-up (Step 4). This carries OUAF-required JVM/classpath settings into the
   domain.
6. Apply any **post-release rollup/patches** required for your release — extract the rollup and run its
   installer (for example `installSFgroup.sh`). **Patch numbers are MOS-gated; obtain them from MOS and
   follow the rollup's own readme** — do not skip required rollups.

**Gate:** product install completes with no errors; `initialSetup.sh` rebuilt the EAR/config cleanly.

## Step 3 — Load the C2M database schema (Configure)
Perform with the DBA. The database schema is installed by the OUAF database installer, **not** by the
file-system installer above.
1. Confirm the DBA has created the tablespaces named in your **`Storage.xml`** and the target database is
   reachable. If a named tablespace is missing, the install aborts by design.
2. From the C2M **database** media, use the `Install-Upgrade` folder. Set `JAVA_HOME`/`PATH`/`CLASSPATH`
   as the DB install step requires (**the DB installer's Java may differ from the app-tier Java — verify
   for your version**).
3. Run the OUAF database installer **`OraDBI`** for an initial install. It prompts for the schema owner
   (`CISADM`), the application user (`CISUSER`), and the read-only user (`CISREAD`) and their passwords,
   validates the `Storage.xml` tablespaces, and loads the schema and seed data. Verify for your version.
4. Check the logs in `Install-Upgrade/logs` for errors; the schema load is not complete until the logs
   are clean.

**Gate:** `OraDBI` completes; logs are error-free; `CISADM`/`CISUSER`/`CISREAD` exist and the schema
objects are present (see Testing).

## Step 4 — Create and verify the WebLogic 14c domain (Configure)
C2M uses a **native** WebLogic 14c domain named `c2m_domain`.
1. Create the domain into the WebLogic 14c Home using Oracle's WebLogic Configuration Wizard (or the
   documented WLST offline flow), per the C2M Installation Guide and WebLogic 14.1.2 documentation. Name
   the domain `c2m_domain`, the Administration Server `AdminServer`, and the Managed Server
   `c2m_server1`, using the ports from your worksheet. Verify for your version.
2. Incorporate the OUAF `setUserOverride.sh` settings (Step 2.5) into the domain's start-up so the C2M
   application deploys with the correct JVM/classpath. Confirm memory arguments are sized for C2M per
   Oracle's guidance.
3. Start the domain: from `$DOMAIN_HOME/bin` start the Admin Server (`./startWebLogic.sh`) and then
   `c2m_server1`; or use the OUAF wrapper `spl.sh -start` to start the environment. Verify for your
   version.
4. Deploy the C2M application and inbound web services as documented (the EAR built by
   `initialSetup.sh`; `iwsdeploy.sh` for inbound web services where applicable).
5. In the WebLogic Administration Console (`http://your-host:your-admin-port/console`), grant online
   application access to the **`cisusers`** security role on first start-up, per Oracle's guidance.

**Gate:** `AdminServer` and `c2m_server1` reach RUNNING; the C2M application and IWS are deployed and in
an active state.

## Step 5 — Configure the environment and validate the build (Validate — pilot gate)
1. Confirm application-to-database connectivity: the C2M application connects to the schema as `CISUSER`
   and the online login page is reachable.
2. Run `OC2MINST-Validation.py` (WLST, against the domain) to confirm the build against the expected
   named objects: `AdminServer` and `c2m_server1` RUNNING and the C2M application/IWS ACTIVE. Save the
   result as `Build Validation – your-env – Validate`. (Use `OC2MINST-ScopeHelper.sh` first to confirm
   `ENVIRON.INI` is present/correct and `$SPLEBASE`/`$SPLOUTPUT` are populated for the environment.)
3. Run the C2M schema check `OC2MINST-Report.sql` (as a read-only user against the schema) to confirm
   `CISADM` owns the expected objects, `CISUSER`/`CISREAD` exist, and the installed version/release
   matches the intended level — this is the **build/schema report** for the environment.
5. If any check fails, run `OC2MINST-Remediation.sh` in its default **dry-run** mode to see the planned
   safe fixes (for example: correct file ownership/permissions on `$SPLEBASE`, restart a server that is
   ADMIN/STANDBY rather than RUNNING, re-run `initialSetup.sh -t` to regenerate templates). Apply only
   after review with `-apply`.

**Pilot gate (`C2MDEV`, then `C2MTST`):** all Validation and Report checks pass. See the Testing Guide
for the full pass/fail criteria. Do not build Production until Dev and Test both pass.

## Step 6 — Post-install validation and hand-off (Validate)
1. Record the environment in your build register with its `$SPLENVIRON`, hosts/ports, DB service, and the
   validated report — this is the reproducible definition of the environment.
2. Confirm the environment can be cleanly stopped and started (`spl.sh -stop` / `spl.sh -start`) and that
   validation still passes after a restart — proving the build survives a bounce, not just first start.
3. Hand the environment to the teams that own the next layers (SSO/SSL, Coherence/JMS/IWS tuning, batch
   scheduling, monitoring) — those are the dedicated solutions in this catalog. This solution's scope is
   a certified, healthy baseline install.

## Step 7 — Expand: repeat for Test and Production (Expand)
1. After `C2MDEV` passes, repeat Steps 0–6 for `C2MTST`, then — inside an approved change window with
   backups verified — for `C2MPRD`. Reuse the **same object names**; change only host/port/DB values from
   each environment's worksheet.
2. Use `OC2MINST-ScopeHelper.sh` to target the correct environment for every run (it resolves the
   `$SPLENVIRON`, `$SPLEBASE`, domain, and DB for the named environment) so a command intended for
   `C2MTST` never runs against `C2MPRD`.
3. Compare each environment's `OC2MINST-Report.sql` output and Discovery baseline to Dev's to confirm the
   builds match structurally — the point of the multi-environment build is that Dev, Test, and Prod
   differ only by their host/port/DB inputs.

---
### Order of operations
`Assess + backup -> Framework install (install.sh -> initialSetup.sh) -> Product install (configureEnv -> initialSetup) -> DB schema (OraDBI: CISADM/CISUSER/CISREAD over Storage.xml) -> WebLogic domain c2m_domain (AdminServer + c2m_server1, deploy C2M) -> Configure + validate (pilot gate) -> Post-install validation -> Expand to Test then Prod`
