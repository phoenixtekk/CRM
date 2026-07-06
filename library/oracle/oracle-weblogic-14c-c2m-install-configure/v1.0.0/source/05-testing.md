# Testing Guide

Testing proves the WebLogic 14c foundation for C2M is actually sound — **domain up, managed
server(s) running, Node Manager in control, and data sources healthy** — with **evidence**, not
assumption. Run these tests at the **Pilot** gate (one node) and again after each **Expand** step.

Each test states what to check, **how** (Admin Console navigation and/or WLST, plus the solution's
scripts), and the **pass criteria**. Run the read-only **Validation** and **Report** scripts to
collect most of this automatically; the manual checks below explain what those scripts assert.

Use placeholders **without angle brackets** (`your-admin-host`, `your-service`) — substitute your
values.

---

## 1. Installation & domain structure

- **Check:** WebLogic 14c installed in `ORACLE_HOME`, and `c2m_domain` created **outside** it with a
  populated `bin/`, `config/config.xml`, and `nodemanager/`.
- **How:** on the host, confirm the directory trees; `cat $DOMAIN_HOME/config/config.xml | head`
  shows the domain; WLST launches (`java weblogic.WLST`). Or run `OWLS14C-Discovery.py`.
- **Pass:** `ORACLE_HOME` and a separate `DOMAIN_HOME` both present; `config.xml` names
  `c2m_domain`; **no template placeholders** left in `config.xml` (e.g. no leftover `localhost`
  machine listen address).

## 2. Node Manager running and reachable

- **Check:** the per-domain Node Manager is up and the Admin Console/WLST can reach it to control
  servers.
- **How:** *WLST:* `nmConnect('your-nm-user','your-nm-pass','your-nm-host',5556,'c2m_domain',
  'your-domain-home/c2m_domain')` then `nm()` returns true. *Console:* **Environment → Machines →
  c2m_machine1 → Monitoring → Node Manager Status** = **Reachable**. Or `OWLS14C-Validation.py`.
- **Pass:** Node Manager status **Reachable**; `nmConnect` succeeds; the machine listen address is a
  **specific host/IP, not `localhost`**.

## 3. Administration Server RUNNING

- **Check:** `AdminServer` is up in production mode and the Console is reachable.
- **How:** browse `http://your-admin-host:7001/console` and log in; *WLST:* `connect(...)` then
  `state('AdminServer')`. *Console:* **Environment → Servers** shows `AdminServer` state **RUNNING**.
- **Pass:** `AdminServer` state = **`RUNNING`**, Console reachable, health **OK**.

## 4. Managed server(s) RUNNING

- **Check:** `c2m_ms1` (and `c2m_ms2` for HA) start under Node Manager and reach **`RUNNING`**.
- **How:** *Console:* **Environment → Servers → Control** → start → state goes **RUNNING**; *WLST:*
  `nmStart('c2m_ms1')` then `state('c2m_ms1')`. Confirm no `SEV`/`ERROR` at startup in
  `DOMAIN_HOME/servers/c2m_ms1/logs/c2m_ms1.log`. Or `OWLS14C-Validation.py`.
- **Pass:** each managed server = **`RUNNING`**, health **OK**, started **via Node Manager**
  (not just a foreground `startManagedWebLogic.sh`), and the C2M app is **not** deployed to
  `AdminServer`.

## 5. Data source healthy (Test-On-Reserve)

- **Check:** `C2MDataSource` connects to the C2M database and passes its reserve-time health test,
  and is targeted at the **managed server(s)**, not `AdminServer`.
- **How:** *Console:* **Services → Data Sources → C2MDataSource → Monitoring → Testing** → select
  `c2m_ms1` → **Test Data Source** = **passed**; check **Targets** = `c2m_ms1`/`c2m_cluster`.
  *WLST:* invoke `testPool` on the runtime MBean, or confirm connections reserve without error. Or
  `OWLS14C-Validation.py`.
- **Pass:** data-source test **passed** on each target; **Test Connections On Reserve = true** with a
  valid **Test Table Name**; pool **Initial/Max Capacity** set (not left at defaults blindly);
  target list **excludes** `AdminServer`.

## 6. Database round-trip from the host (independent of WebLogic)

- **Check:** the same DB coordinates the data source uses are reachable and log in from the host —
  isolates "DB/network problem" from "WebLogic config problem."
- **How:** `sqlplus your-schema-user@//your-db-host:your-db-port/your-service` (or `tnsping`); a
  SQL check script (`OWLS14C-*.sql`) can confirm the schema is present.
- **Pass:** login succeeds against the **service name** (not SID for RAC); the C2M schema objects
  are visible. If this fails but you expected the data source to work, the issue is DB/network, not
  WebLogic.

## 7. JVM / startup configuration in effect

- **Check:** the managed server(s) actually run with the intended heap/metaspace and production
  mode — i.e. `USER_MEM_ARGS` took effect via Node Manager (`StartScriptEnabled=true`).
- **How:** *Console:* **Environment → Servers → c2m_ms1 → Monitoring → Performance** shows heap
  sizes; or inspect the server's runtime args (`ps` on the JVM, or WLST JVMRuntime). Confirm
  `boot.properties` exists so startup is unattended.
- **Pass:** running heap/metaspace **match** the configured `USER_MEM_ARGS`; domain in **production
  mode**; server starts **unattended** under Node Manager (no credential prompt), auto-restart
  enabled.

## 8. Coverage / regression — the Report

- **Check:** a single health/coverage snapshot of the whole foundation to attach to the change
  record and to re-run after each Expand step (regression baseline).
- **How:** `java weblogic.WLST OWLS14C-Report.py` — summarizes servers & states, Node Manager
  reachability, data-source targets & test results, JVM args, and placeholder/`localhost` findings.
- **Pass:** Report shows **all** servers `RUNNING`, Node Manager reachable, `C2MDataSource` healthy
  and correctly targeted, JVM args as configured, and **zero** placeholder/`localhost`/AdminServer-
  targeting findings.

---

## Test summary gate

| # | Test | Pass criteria |
|---|------|---------------|
| 1 | Install & domain structure | `ORACLE_HOME` + separate `DOMAIN_HOME`; no placeholders in `config.xml` |
| 2 | Node Manager | **Reachable**; machine on real host/IP, not `localhost` |
| 3 | Admin Server | `AdminServer` = **RUNNING**, Console reachable |
| 4 | Managed server(s) | `c2m_ms1`(/`c2m_ms2`) = **RUNNING** via Node Manager; app not on Admin |
| 5 | Data source | `C2MDataSource` test **passed**; Test-On-Reserve on; not targeted at Admin |
| 6 | DB round-trip | SQL login to the **service** succeeds from host |
| 7 | JVM / startup | Heap/metaspace match config; production mode; unattended start |
| 8 | Report | All green; zero placeholder/localhost/Admin-targeting findings |

**All eight pass → the domain has cleared the Validate gate.** A failure at any test sends you to
the Troubleshooting Guide; fixable config drift can be previewed and applied with the Remediation
script (dry-run first). Re-run this suite after every **Expand** change.
