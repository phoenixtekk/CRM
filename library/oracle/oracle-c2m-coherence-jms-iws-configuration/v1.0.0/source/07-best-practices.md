# Best Practices — Coherence, JMS & IWS on C2M

Production-safe practices for the C2M runtime layer. They complement the implementation steps and
keep the three layers healthy over time.

---

## Coherence

- **Prefer unicast Well Known Addresses (WKA) over multicast.** Unicast WKA is deterministic and
  firewall-friendly; multicast is fragile across enterprise segments and a leading cause of
  "cluster won't form". List the member hosts explicitly.
- **Standardise the cluster listen port and open it between all members.** Use one agreed port
  (default 7574, *verify for your version*) and confirm host firewalls allow it host-to-host.
- **One named cluster, associated to the right servers.** Keep a single, clearly named cluster
  (`c2m-coherence-cluster`) targeted only to the servers that must be members — don't leave stray
  associations.
- **Plan the restart.** All Coherence changes require a server restart; batch changes into one
  restart in the change window rather than repeated bounces.
- **Verify membership after every change and after every restart** with `OC2MRUNTIME-Validation` —
  member count must equal expected node count. Watch logs for join/leave churn (a sign of network or
  timeout issues).
- **Keep member clocks in sync (NTP)** and member hosts on a low-latency segment; clock skew and
  latency destabilise membership.

## JMS

- **Always back destinations with a persistent store** (file store on a writable, backed-up path
  owned by the product account, or a JDBC store) so persistent messages survive restarts.
- **Target with an explicit subdeployment, not module defaults.** A named subdeployment
  (`C2MJMSSubDeployment`) makes targeting deliberate and auditable, and is required for clean cluster
  targeting.
- **Use Uniform Distributed destinations in a cluster** so every member has a member destination and
  no single node is a bottleneck or single point of failure.
- **Make JNDI names match C2M message senders exactly.** The most common "silent" JMS failure is a
  healthy-looking destination whose JNDI name does not match what C2M sends to. Reconcile on every
  change (`OC2MRUNTIME-Report`).
- **Set quotas and monitor pending/error counts.** Configure destination/quota limits so a backlog is
  bounded, and alert on rising pending counts or messages parked in error state.
- **Name resources consistently** (`C2MJMSServer` / `C2MJMSModule` / `C2MConnectionFactory` /
  `C2MRealTimeQueue` / `C2MEventTopic`) across environments so the same scripts and runbooks apply
  everywhere.

## Inbound Web Services (IWS)

- **Migrate off XAI to IWS** where legacy XAI inbound services remain; IWS uses the container's
  clustering/HA and per-service monitoring. See MOS Doc ID 1644914.1 for the migration path.
- **Deploy headless and repeatably.** Use `iwsdeploy` with the stored WebLogic user-config/key files
  (`$SPLEBASE/etc/.wlsuserconfig` / `.wlsuserkey`) so deploys are scriptable and identical across
  environments — no interactive passwords.
- **Turn the development-environment flag OFF in production.** The "deploy from browser UI" option is
  a non-production convenience; leaving it on in production is an unnecessary exposure.
- **Enable only the inbound services integrations actually need.** Every enabled service is surface
  area to secure, monitor, and support; enable by inventory (Requirement 7), not by default.
- **Confirm the Admin Server is up before deploying.** `iwsdeploy` requires the Admin Server (and the
  target managed server) running; a stopped Admin Server is the classic deploy failure.
- **Secure the endpoints** (TLS via the OUAF trust store / `initialSetup -i`, plus WS-Policy /
  authentication as required) and monitor each service — with Enterprise Manager if available — for
  latency and errors.

## Cross-cutting

- **Non-production first, always.** Configure and validate on the pilot, then promote the *same*
  named objects and *same* scripts to Test and Prod.
- **Back up before disruptive changes** (domain `config.xml`, `$SPLEBASE`, JMS store) and keep the
  restore path as the rollback.
- **Reuse names across environments** so discovery/validation/report scripts are portable — retarget
  with `OC2MRUNTIME-ScopeHelper` rather than re-authoring per environment.
- **Keep remediation dry-run by default.** Review `OC2MRUNTIME-Remediation`'s planned actions before
  applying, and apply only inside a change window.
- **Retain script output as evidence** for change records and audits; a clean `OC2MRUNTIME-Report` is
  the sign-off artifact.

## Sources

- Oracle® Fusion Middleware — *Configuring and Managing Coherence Clusters*:
  https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/clust/coherence.html
- Oracle® Fusion Middleware — *Using WLST to Manage JMS Servers and JMS System Module Resources*:
  https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/jmsad/wlst.html
- Oracle Utilities CCB — *Deploying Inbound Web Services (IWS)*:
  https://docs.oracle.com/en/industries/energy-water/ccb/29011/ccb-installation-guide/CCB-INSTALLATION-GUIDE/CCB_Install_Postinstall.09.09.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
