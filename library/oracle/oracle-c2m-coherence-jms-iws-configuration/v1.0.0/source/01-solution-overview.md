# Solution Overview — C2M Runtime: Coherence, JMS & Inbound Web Services

Oracle Utilities **Customer to Meter (C2M)** runs on the **Oracle Utilities Application Framework
(OUAF)** deployed on **Oracle WebLogic Server**. Beyond the base install, three runtime layers
determine whether C2M actually clusters, messages, and integrates in real time:

1. **Oracle Coherence clustering** — the in-memory data grid WebLogic/OUAF uses for cache
   coordination and (in clustered topologies) cross-node coherence. If the Coherence cluster does
   not form cleanly, managed servers behave as isolated nodes and cache-dependent behaviour is
   inconsistent.
2. **JMS queues, topics & connection factories** — the WebLogic JMS resources that carry
   asynchronous work (outbound message dispatch, real-time integration hand-offs, and any JMS
   consumers wired to OUAF). Misconfigured JMS servers, modules, or subdeployments cause messages to
   pile up, mis-target, or silently drop.
3. **Inbound Web Services (IWS)** — the OUAF mechanism (the replacement for the legacy **XAI**
   inbound services) that exposes C2M business services as SOAP/REST endpoints deployed as a Java EE
   web application on WebLogic. If IWS is not deployed and enabled, external systems cannot call into
   C2M.

This solution configures **all three runtime layers** as one coherent unit, because in practice they
are interdependent: IWS rides on the same managed servers that participate in the Coherence cluster,
and many real-time flows terminate in JMS. Getting one right while another is broken still leaves the
platform unintegrated.

## What "the C2M runtime" means here

| Layer | WebLogic/OUAF object | What it enables | Symptom when wrong |
|-------|----------------------|-----------------|--------------------|
| Coherence | Coherence cluster + managed Coherence membership | Cache coordination, clustered scale-out | Cluster won't form; nodes act alone |
| JMS | JMS server, JMS system module, queues/topics, connection factory, subdeployment | Asynchronous messaging & real-time hand-off | Queues back up; messages mis-target |
| IWS | `spl-web-services` EAR deployed via `iwsdeploy` + enabled inbound services | Inbound SOAP/REST integration into C2M | External calls fail / 404 |

> **Naming convention used throughout.** So that the docs, scripts, and console steps line up, this
> solution refers to a single **named set of objects** and reuses those names everywhere: the
> Coherence cluster **`c2m-coherence-cluster`**, the JMS server **`C2MJMSServer`**, the JMS system
> module **`C2MJMSModule`**, the connection factory **`C2MConnectionFactory`** (JNDI
> `jms/C2MConnectionFactory`), a representative queue **`C2MRealTimeQueue`** (JNDI
> `jms/C2MRealTimeQueue`), a representative topic **`C2MEventTopic`** (JNDI `jms/C2MEventTopic`), the
> subdeployment **`C2MJMSSubDeployment`**, and the inbound web-service EAR **`spl-web-services`**.
> Substitute your own environment's standard names — but pick them once and reuse them, exactly as
> shown here.

## How the layers support batch, real-time, and integration

- **Batch** relies on a healthy domain and, in clustered deployments, on Coherence membership so that
  batch threadpools and cache behaviour are consistent across nodes.
- **Real-time** flows (online screens, service scripts) use IWS to receive inbound calls and JMS to
  hand off asynchronous work without blocking the caller.
- **Integration** with SOA/middleware and external systems is inbound via IWS and (frequently)
  asynchronous via JMS queues/topics — the two together are the C2M "integration surface".

## Deployment model

Like every Oracle solution in this catalogue, work proceeds **Assess → Configure → Pilot → Validate →
Expand**, on a **non-production environment first**, with explicit pass/fail gates and a documented
rollback before any production change. The included automation is **WLST (Jython), shell, and SQL** —
never PowerShell — because that is the authentic C2M/WebLogic toolchain.

## Version note

- **C2M 25.4** (minimum **v2.9**) on **Oracle WebLogic Server 14c** is the reference stack; earlier
  releases differ (notably the XAI → IWS transition and Coherence packaging). Where a menu path,
  utility flag, or default differs by release, the step is flagged **"verify for your version"**.
- Some Coherence/IWS notes and patches are entitlement-gated on **My Oracle Support (MOS)** (for
  example, **Doc ID 1644914.1 — Migrating from XAI to IWS**); this solution points to them rather than
  reproducing gated content.

## Sources

- Oracle® Fusion Middleware — *Configuring and Managing Coherence Clusters* (WebLogic Server 12.2.1.4 /
  14.1.1): https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/clust/coherence.html
- Oracle® Fusion Middleware — *Using WLST to Manage JMS Servers and JMS System Module Resources*
  (WebLogic 14.1.1): https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/jmsad/wlst.html
- Oracle Utilities Application Framework — *Server Administration Guide* (Web Application Server
  Configuration; IWS): https://docs.oracle.com/en/industries/energy-water/framework/254/server-admin-guide/OUAF_SERVER_ADMIN_254/OUAF_Server_Admin_Configuration.06.4.html
- Oracle Utilities CCB — *Deploying Inbound Web Services (IWS)* (installation guide):
  https://docs.oracle.com/en/industries/energy-water/ccb/29011/ccb-installation-guide/CCB-INSTALLATION-GUIDE/CCB_Install_Postinstall.09.09.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
