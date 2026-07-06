# Solution Overview

Oracle Utilities **Customer to Meter (C2M)** — and the Oracle Utilities Application Framework
(OUAF) beneath it — is a Java EE application that runs on **Oracle WebLogic Server**. Everything
above the middleware (online, web services, batch threadpools) depends on a WebLogic **domain**
that is built and configured correctly. A domain with a sloppy topology, no Node Manager, JVMs
sized by guesswork, or hand-typed connection strings for data sources will haunt every layer that
sits on top of it.

This solution installs and configures **Oracle WebLogic Server 14c (14.1.1)** as the C2M
middleware foundation: the **domain**, the **Administration Server** and **managed servers**, the
**Node Manager** that controls their lifecycle, the **JDBC data sources** to the C2M database, and
the **JVM / startup** configuration OUAF expects — built pilot-first and validated before it carries
production load.

> **Scope boundary.** This solution builds and configures the **WebLogic domain** that C2M is
> deployed onto (install WebLogic → create domain → servers → Node Manager → data sources → JVM /
> startup → validate). Deploying the C2M/OUAF EAR (`SPLWeb`, `SPLService`) onto the domain, batch
> threadpool workers, Coherence/JMS/IWS internals, SSO/SSL, and patching each have their own
> solutions and are pointed to, not reproduced here. Where a C2M release pins a specific WebLogic /
> JDK combination, that is a **"verify for your version"** check against Oracle's certification
> matrix (see the Requirements Guide) — never assumed.

## The named topology this solution builds

Every step, script, and check in this solution refers to the **same named objects**. Adopt these
names (or map them once to your site's convention and reuse yours consistently) so the domain,
scripts, and runbooks all speak the same language:

| Object | Name used throughout | Role |
|---|---|---|
| WebLogic domain | `c2m_domain` | The domain OUAF/C2M is deployed onto |
| Domain home | `DOMAIN_HOME` = `.../c2m_domain` | Config, `bin/` startup scripts, servers' state |
| Administration Server | `AdminServer` | Config authority + Admin Console / WLST target |
| Managed server(s) | `c2m_ms1` (and `c2m_ms2` for HA) | Where the C2M application runs |
| Cluster (HA topology) | `c2m_cluster` | Groups the managed servers for HA/scale |
| Machine | `c2m_machine1` | Ties servers to a host + its Node Manager |
| Node Manager | per-domain, in `DOMAIN_HOME/nodemanager` | Starts/stops/monitors servers |
| JDBC data source | `C2MDataSource` | Connection pool to the C2M database schema |
| OS product account | the OUAF product user (e.g. `cissys`) | Owns the WebLogic + OUAF file system |

`ORACLE_HOME` is the WebLogic 14c install (the Middleware / Fusion Middleware home); `DOMAIN_HOME`
is the domain, placed **outside** `ORACLE_HOME` per Oracle's guidance so an upgrade or reinstall of
the binaries does not disturb the domain.

## Domain topology — how C2M sits on WebLogic

```
                         c2m_machine1 (host)
                 ┌──────────────────────────────────────────┐
                 │  Node Manager (per-domain)                │
                 │     starts / stops / monitors servers     │
                 │                                            │
                 │  ┌───────────────┐    ┌──────────────────┐│
   Admin Console │  │  AdminServer  │    │  c2m_ms1         ││
   / WLST ──────►│  │  (config,     │    │  (C2M app:       ││
                 │  │   no app)     │    │   SPLWeb/Service) ││   ── C2MDataSource ──►  C2M
                 │  └───────────────┘    └──────────────────┘│                         database
                 │                        (c2m_cluster for HA)│                         schema
                 └──────────────────────────────────────────┘
```

- **Administration Server (`AdminServer`)** — the single point of configuration truth for the
  domain. You administer it through the **WebLogic Administration Console** and **WLST**. Best
  practice: **do not deploy the C2M application to the AdminServer** — keep it for administration
  and run C2M on the managed server(s).
- **Managed server(s) (`c2m_ms1`, optionally `c2m_ms2`)** — where the C2M/OUAF application
  (`SPLWeb` online + `SPLService` web services) actually runs and serves users and integrations. A
  single managed server is a valid pilot; two-in-a-cluster (`c2m_cluster`) is the usual production
  HA shape.
- **Node Manager** — the WebLogic utility that **starts, stops, restarts and monitors** the Admin
  and managed servers, including auto-restart of a crashed server. This solution uses the
  **per-domain** Node Manager (config lives under `DOMAIN_HOME/nodemanager`), which is the modern
  default and keeps each domain self-contained; the alternative **per-host** Node Manager is noted
  where it matters. Servers are enrolled with the `nmEnroll` WLST command so Node Manager can
  manage them.
- **Machine (`c2m_machine1`)** — the WebLogic representation of a host. Servers are assigned to a
  machine, and the machine points at that host's Node Manager listen address (a **specific IP /
  hostname, not `localhost`**), which is how the Admin Console/WLST reach Node Manager to control
  servers.
- **JDBC data source (`C2MDataSource`)** — the WebLogic-managed connection pool to the C2M
  database schema. OUAF connects to the database **through** this data source, so its driver, URL,
  credentials, pool sizing, and **Test-On-Reserve** health check are domain configuration, not
  application code. On an Oracle RAC database, this is typically an **Active GridLink** data source.
- **JVM / startup configuration** — heap and GC flags, `USER_MEM_ARGS` / `setDomainEnv`
  customization, production mode, and a boot-identity file so servers start unattended under Node
  Manager. C2M is memory- and GC-sensitive; this is set deliberately, not left at template defaults.

## The deployment model — Assess → Configure → Pilot → Validate → Expand

Consistent with every Oracle-category solution, the domain is built with explicit gates and a
documented rollback, always on a **non-production environment first**:

1. **Assess** — confirm entitlement, a **certified** OS/JDK/DB/WebLogic combination for the target
   C2M release, host resources, DB connectivity, and access (OS product account, WebLogic admin,
   schema). *Gate: certified stack + reachable database, or stop.* (See Requirements Guide.)
2. **Configure** — install WebLogic 14c, create `c2m_domain`, configure `AdminServer` + managed
   server(s) + `c2m_machine1`, stand up the per-domain **Node Manager**, create `C2MDataSource`,
   and set JVM / startup. *Gate: config valid, no template placeholders left in.*
3. **Pilot** — bring the domain up on **one** non-production environment / node: Node Manager
   running, `AdminServer` and `c2m_ms1` in `RUNNING`, `C2MDataSource` test **passes**. *Gate: a
   clean single-node domain before any horizontal scale.*
4. **Validate** — run the Validation and Report scripts: servers healthy, data source reserving
   connections, Node Manager reachable, JVM args as intended, logs clean. *Gate: evidence, not
   assumption.*
5. **Expand** — add the second managed server / cluster, additional machines/nodes, and promote the
   pattern across environments (Dev → Test → Prod) under change control, re-validating at each step.

## What's inside this solution

- **Requirements Guide** — each prerequisite (entitlement, certified stack, host sizing, DB
  connectivity, access & tooling, change control) with how to **verify** and **implement**.
- **Implementation Guide** — the exact, ordered steps: install WebLogic 14c → create `c2m_domain` →
  configure Admin/managed servers + Node Manager + machine → create `C2MDataSource` → tune
  JVM/startup → validate the domain, with Admin Console navigation and WLST alongside.
- **5 automation scripts (WLST/Jython, shell, SQL)** — read-only **Discovery**, read-only
  **Validation**, a read-only **Report**, a **Remediation** helper (dry-run by default), and a
  **ScopeHelper** that pins the domain/server/data-source targets the other scripts act on.
- **Testing, Troubleshooting, and Best Practices** guides — prove the domain is up, managed servers
  running, and data sources healthy; diagnose the common failures; and lay the domain out for the
  long run.

## Outcome

A correctly built **WebLogic 14c foundation for C2M** — `c2m_domain` created, `AdminServer` and the
managed server(s) `RUNNING`, the per-domain **Node Manager** in control, `C2MDataSource` healthy,
and JVM / startup configured deliberately — **proven on a pilot before you scale**, so every layer
C2M adds on top starts from solid ground.
