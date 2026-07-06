# Implementation Guide — Configuring the C2M Runtime (Coherence · JMS · IWS)

This guide configures the C2M runtime layer end to end: the **Coherence cluster**, the **JMS server /
module / queues / topics / connection factory**, and **Inbound Web Services (IWS)** — then validates
clustering, messaging, and web-service calls. It follows **Assess → Configure → Pilot → Validate →
Expand**, on the **pilot (non-production)** environment first, with pass/fail gates and a rollback.

Object names below match the Overview naming convention and are reused throughout; substitute your
environment's standard names but keep them consistent across console, WLST, and C2M config.

> **Reference names:** cluster `c2m-coherence-cluster` (listen port 7574, *verify for your version*);
> JMS server `C2MJMSServer`; JMS system module `C2MJMSModule`; connection factory
> `C2MConnectionFactory` (JNDI `jms/C2MConnectionFactory`); queue `C2MRealTimeQueue` (JNDI
> `jms/C2MRealTimeQueue`); topic `C2MEventTopic` (JNDI `jms/C2MEventTopic`); subdeployment
> `C2MJMSSubDeployment`; IWS EAR `spl-web-services`.

> **Safety rules for every phase.** Take a config backup first (Requirement 8). Coherence and many
> JMS changes require a **server restart** to take effect — plan the restart into the change window.
> Do disruptive work in a maintenance window; keep the rollback (restore `config.xml` / product home)
> ready.

---

## Phase 0 — Assess (read-only)

**Goal:** capture the current runtime state before changing anything.

1. Connect WLST read-only and record: managed-server states, any existing Coherence cluster and its
   members, existing JMS servers/modules/destinations, and whether `spl-web-services` is already
   deployed.
2. Run **`OC2MRUNTIME-Discovery`** (read-only) to snapshot Coherence, JMS, and IWS configuration to a
   file, and **`OC2MRUNTIME-ScopeHelper`** to fix the exact target set (which servers/cluster you will
   touch) so later scripts act only in scope.
3. Confirm all Requirements pass on the pilot environment.

**Gate 0 (pass/fail):** you have a written baseline, an agreed target scope, and a rollback point.
Do not proceed until all pass.

---

## Phase 1 — Configure the Coherence cluster

**Goal:** a named Coherence cluster the managed servers reliably join.

1. **Create the Coherence cluster.** In the Administration Console: *Environment → Coherence Clusters
   → New*. Name it **`c2m-coherence-cluster`**. Choose **Configure within WebLogic Server**, select
   the transport (**unicast** — preferred — or multicast), and set the **cluster listen port**
   (default **7574**, *verify for your version*). (Console path per Oracle's *Create Coherence
   Clusters* task help.)

   Equivalent WLST (offline or online + `startEdit()`), illustrative:
   ```
   edit(); startEdit()
   cd('/')
   cmo.createCoherenceClusterSystemResource('c2m-coherence-cluster')
   cd('/CoherenceClusterSystemResources/c2m-coherence-cluster/CoherenceClusterResource/'
      'c2m-coherence-cluster/CoherenceClusterParams/c2m-coherence-cluster')
   cmo.setClusteringMode('unicast')        # unicast WKA preferred over multicast
   cmo.setUnicastListenPort(7574)          # verify for your version/topology
   save(); activate()
   ```

2. **Associate the cluster with the WebLogic server(s)/cluster.** Target
   **`c2m-coherence-cluster`** to the managed server(s) or the WebLogic cluster that runs C2M so they
   become Coherence members. For **unicast**, configure the **Well Known Addresses (WKA)** to the
   member hosts (deterministic discovery; firewall-friendly) rather than relying on multicast.

3. **Restart** the affected managed server(s). *All Coherence changes require a restart to take
   effect.*

4. **Verify formation** with **`OC2MRUNTIME-Validation`** (read-only): confirm the cluster is
   present, every in-scope server is a **member**, and the member count equals the expected node
   count.

**Gate 1:** cluster `c2m-coherence-cluster` exists, all in-scope servers are members, no discovery
errors in the server logs. If members are missing → check the listen port/firewall and unicast WKA
before proceeding.

---

## Phase 2 — Configure JMS (server → module → destinations → connection factory)

**Goal:** JMS resources C2M's message senders/integration can bind to and that survive restart.

1. **Create the JMS server + persistent store.** Create a **persistent store** (file store on a
   writable path owned by the product OS account, or a JDBC store), then a **JMS server**
   **`C2MJMSServer`** using that store, targeted to the managed server (single-server) — for a cluster
   you will target destinations via the subdeployment in step 5.

2. **Create the JMS system module.** *Services → Messaging → JMS Modules → New* →
   **`C2MJMSModule`**, targeted to the managed server or cluster running C2M.

3. **Create the connection factory.** In `C2MJMSModule`, create **`C2MConnectionFactory`** with JNDI
   name **`jms/C2MConnectionFactory`**. (This is the CF the C2M message senders / JMS consumers
   reference.)

4. **Create the destinations.** In `C2MJMSModule`, create the queue **`C2MRealTimeQueue`** (JNDI
   **`jms/C2MRealTimeQueue`**) and the topic **`C2MEventTopic`** (JNDI **`jms/C2MEventTopic`**). For a
   **clustered** deployment prefer **Uniform Distributed** destinations so every cluster member has a
   member destination.

5. **Create the subdeployment and target it.** Create subdeployment **`C2MJMSSubDeployment`** and
   target the connection factory and destinations to **`C2MJMSServer`** (single server) or to the
   cluster's JMS servers. A **subdeployment** is the mechanism that groups module resources and
   targets them to a JMS server / server / cluster — use it rather than the module default targets so
   targeting is explicit.

   Illustrative WLST (online, inside `startEdit()`), matching Oracle's *Using WLST to Manage JMS*
   examples:
   ```
   edit(); startEdit()
   cd('/JMSSystemResources/C2MJMSModule/JMSResource/C2MJMSModule')

   cf = cmo.createConnectionFactory('C2MConnectionFactory')
   cf.setJNDIName('jms/C2MConnectionFactory')
   cf.setSubDeploymentName('C2MJMSSubDeployment')

   q = cmo.createQueue('C2MRealTimeQueue')
   q.setJNDIName('jms/C2MRealTimeQueue')
   q.setSubDeploymentName('C2MJMSSubDeployment')

   t = cmo.createTopic('C2MEventTopic')
   t.setJNDIName('jms/C2MEventTopic')
   t.setSubDeploymentName('C2MJMSSubDeployment')

   save(); activate()
   ```

6. **Reconcile with C2M.** Confirm the JNDI names created here match what the C2M **Message Sender**
   configuration references (Requirement 5). A destination that does not match the sender's JNDI name
   will look healthy in WebLogic yet carry no traffic.

7. **Restart** if required and **verify** with `OC2MRUNTIME-Validation`: JMS server **RUNNING**,
   destinations present and bound to JNDI, connection factory resolvable.

**Gate 2:** `C2MJMSServer` running, `C2MConnectionFactory` + `C2MRealTimeQueue` + `C2MEventTopic`
present with the expected JNDI names, subdeployment targeting correct, and names reconciled with C2M
message senders.

---

## Phase 3 — Deploy & enable Inbound Web Services (IWS)

**Goal:** the `spl-web-services` EAR deployed and the in-scope inbound services responding.

1. **Enable web services in the environment.** From `$SPLEBASE/bin`, run `configureEnv` (`-a`) and set
   the IWS parameters — the **IWS Deployment Target** (the server the EAR deploys to) and the **Web
   Admin Server Host** (the WebLogic Admin Server host). In non-production you may also set the
   development-environment flag to allow deploying from the browser UI; leave it **off** in
   production. Process the changes (`P`).

2. **Run initial setup.** From `$SPLEBASE/bin` run `initialSetup` so the templated config
   (`weblogic.xml`, `web.xml`, `spl.properties`, etc.) is regenerated for IWS.

3. **Prepare headless WebLogic credentials.** Ensure `$SPLEBASE/etc/.wlsuserconfig` and
   `.wlsuserkey` exist (created with the WLST `storeUserConfig` command) so the deploy runs without an
   interactive password. Import the WebLogic certificate into the OUAF trust store with
   `initialSetup -i` if TLS is in play.

4. **Ensure the Admin Server (and managed server) are running**, then **deploy the EAR** from
   `$SPLEBASE/bin`:
   ```
   cd $SPLEBASE/bin
   ksh ./iwsdeploy.sh        # deploys the spl-web-services EAR to the IWS Deployment Target
   ```
   (On Windows the equivalent is `iwsdeploy.cmd`.) The Admin Server **must be up** before running
   the deploy.

5. **Enable the required inbound services.** In C2M, activate the **Inbound Web Service** metadata
   records that are in scope (Requirement 7) and redeploy if the service list changed. Enable **only**
   the services integrations need.

6. **Verify** with `OC2MRUNTIME-Validation`: the `spl-web-services` application is **deployed/active**
   on the target server, and the in-scope inbound service endpoints respond (WSDL/endpoint
   reachable).

**Gate 3:** `spl-web-services` active on the IWS Deployment Target; each in-scope inbound service is
enabled and returns a well-formed response (or WSDL) to a test call.

---

## Phase 4 — Validate the runtime end to end (Pilot)

**Goal:** prove clustering + messaging + web services together on the pilot before expanding.

1. Run **`OC2MRUNTIME-Validation`** across all in-scope servers for a single consolidated pass on
   Coherence membership, JMS destination health, and IWS deployment status.
2. Run **`OC2MRUNTIME-Report`** (read-only) to produce a health/coverage report (which servers are
   Coherence members, which destinations exist and their consumer/pending counts, which inbound
   services are enabled and responding).
3. Execute the functional checks in **05-testing.md** (cluster formed, JMS message round-trips, an
   inbound web-service call succeeds end to end).
4. If anything is off, correct with **`OC2MRUNTIME-Remediation`** (**dry-run by default** — review the
   planned actions, then re-run with the explicit apply flag inside the change window).

**Gate 4:** the report shows all three layers healthy on the pilot and the functional tests pass.

---

## Phase 5 — Expand to remaining environments

1. Repeat Phases 1–4 per environment (Test → Prod), each behind its own change window, backup, and
   rollback.
2. Use `OC2MRUNTIME-ScopeHelper` to retarget the scripts to each environment's server set so you run
   the **same** validated steps everywhere.
3. In production, keep the development-environment IWS flag **off**, enable only required inbound
   services, and confirm the report is clean before closing the change.

**Final gate:** every target environment shows a clean `OC2MRUNTIME-Report` — Coherence formed, JMS
flowing, IWS responding — with a captured rollback point.

---

## Rollback

- **Coherence/JMS:** restore the previous domain `config.xml` (from the Requirement 8 backup) and
  restart; or remove the newly created cluster/JMS objects via WLST and restart.
- **IWS:** undeploy `spl-web-services` (or redeploy the prior EAR) and disable the newly enabled
  inbound services.
- Re-run `OC2MRUNTIME-Validation` to confirm the environment is back to its pre-change baseline.

## Sources

- Oracle® Fusion Middleware — *Create Coherence Clusters* (task help) and *Configuring and Managing
  Coherence Clusters*:
  https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlach/taskhelp/coherence/CreateCoherenceClusters.html
- Oracle® Fusion Middleware — *Using WLST to Manage JMS Servers and JMS System Module Resources*
  (WebLogic 14.1.1): https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/jmsad/wlst.html
- Oracle Utilities CCB — *Deploying Inbound Web Services (IWS)*:
  https://docs.oracle.com/en/industries/energy-water/ccb/29011/ccb-installation-guide/CCB-INSTALLATION-GUIDE/CCB_Install_Postinstall.09.09.html
- Oracle Utilities Application Framework — *Server Administration Guide* (Web Application Server
  Configuration): https://docs.oracle.com/en/industries/energy-water/framework/254/server-admin-guide/OUAF_SERVER_ADMIN_254/OUAF_Server_Admin_Configuration.06.4.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
