# Deliverables Summary

Everything included in **Oracle WebLogic 14c for C2M — Install, Configure & Domain Setup**, and how
the pieces fit together. This solution builds the **WebLogic 14c middleware foundation** that C2M is
deployed onto: install WebLogic → create the `c2m_domain` domain → configure Admin / managed servers
+ Node Manager + machine → create the `C2MDataSource` data source → tune JVM / startup → validate —
pilot-first, with explicit gates.

## Documentation

| Document | What it gives you |
|---|---|
| **Solution Overview** | The named domain topology (`c2m_domain`, `AdminServer`, `c2m_ms1`/`c2m_ms2`, `c2m_cluster`, `c2m_machine1`, `C2MDataSource`), how OUAF/C2M sits on WebLogic, the Assess→Configure→Pilot→Validate→Expand model, and scope boundaries. |
| **Requirements Guide** | Each prerequisite — certified WebLogic 14c installer + JDK, sized host, OS product account & directory layout, free ports, reachable DB + service, admin credential & boot-identity plan, WLST/shell/SQL tooling, change control — with **verify** / **implement** steps. |
| **Implementation Guide** | The exact ordered build: install WebLogic 14c → create `c2m_domain` → configure Admin/managed servers + Node Manager + machine → create `C2MDataSource` → tune JVM/startup → validate, with **Admin Console navigation** and **WLST** side by side, and rollback. |
| **Testing Guide** | Eight tests proving domain up, servers `RUNNING`, Node Manager reachable, data sources healthy, JVM args in effect — with pass criteria and a summary gate. |
| **Troubleshooting Guide** | Symptom → likely cause → resolution for the common domain, server, Node Manager, data-source, and JVM failures. |
| **Best Practices** | Domain layout, Node Manager, data sources, JVM/memory, security/ops, and continuous validation. |

## Automation scripts

Five scripts, authentic to WebLogic + C2M administration — **WLST (Jython), shell, and SQL, not
PowerShell**. Read-only tools are read-only; the only script that can change anything defaults to
**dry-run**.

| Script | Type | Mode | What it does |
|---|---|---|---|
| **OWLS14C-Discovery** | WLST / shell | Read-only | Inventories the environment — host, JDK, `ORACLE_HOME`/domains, servers & states, machine/Node Manager, data sources, free ports, DB reachability. Run before and after building the domain. |
| **OWLS14C-Validation** | WLST | Read-only | Asserts the pass criteria — servers `RUNNING`, Node Manager reachable, `C2MDataSource` Test-On-Reserve **passes** and not targeted at `AdminServer`, JVM args as configured, no `localhost`/placeholders. |
| **OWLS14C-Report** | WLST | Read-only | Produces a health/coverage snapshot of the whole foundation to attach to the change record and use as a regression baseline. |
| **OWLS14C-Remediation** | shell / WLST | **Dry-run default** | Previews and (with `--apply`) fixes common, safe config drift — Test-On-Reserve off, data source on `AdminServer`, `StartScriptEnabled=false`, machine on `localhost`. Backup + review before applying. |
| **OWLS14C-ScopeHelper** | shell | Read-only | Pins the targets the other scripts act on — domain name, server names/ports, machine, Node Manager host/port, data-source coordinates — into `owls14c-scope.env` for consistent, per-environment runs. |

Each script carries a native-comment header (`#`/`--`) stating **PURPOSE**, **HOW TO RUN**,
**EXPECTED RESULTS**, and **NOTES**, and uses placeholders **without angle brackets**
(`your-domain`, `your-db-host`).

## How the pieces work together

1. **ScopeHelper** captures your environment's names and coordinates → `owls14c-scope.env`.
2. **Discovery** inventories the host/domain (before build, and again after).
3. Build the domain per the **Implementation Guide** (install → domain → servers/Node Manager/
   machine → data source → JVM/startup).
4. **Validation** + **Report** prove the **Pilot**/**Validate** gates with evidence.
5. **Remediation** (dry-run → apply) fixes any flagged drift safely.
6. Re-run Validation/Report after each **Expand** step and every future change.

## What this solution does not include (pointed to, not reproduced)

- **Deploying the C2M/OUAF application** (`SPLWeb`/`SPLService`) onto the domain, and OUAF
  `configureEnv`/`initialSetup` — separate C2M installation/deployment solution.
- **Coherence / JMS / IWS** configuration, **batch threadpool** workers, **SSO / SSL / keystore**,
  and **WebLogic patching/upgrade** — each its own solution.
- **My-Oracle-Support-gated** notes, patches, and the exact certified WebLogic/JDK/DB versions — the
  solution points to MOS and flags version-specific values as **verify for your version** rather than
  reproducing gated content.

## Outcome

A correctly built **WebLogic 14c foundation for C2M** — `c2m_domain` created, `AdminServer` and the
managed server(s) `RUNNING`, the per-domain **Node Manager** in control, `C2MDataSource` healthy and
correctly targeted, and JVM / startup configured deliberately — **proven on a pilot before you
scale**.
