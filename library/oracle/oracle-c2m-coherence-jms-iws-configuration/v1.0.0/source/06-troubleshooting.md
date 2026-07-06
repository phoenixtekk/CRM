# Troubleshooting — Coherence, JMS & IWS

Common failures across the C2M runtime, as **symptom → likely cause → resolution**. Start from the
read-only scripts (`OC2MRUNTIME-Discovery`, `OC2MRUNTIME-Validation`, `OC2MRUNTIME-Report`) to
localise the problem before changing anything. All fixes are non-production-first with a rollback.

---

## Coherence

**Symptom: cluster won't form / a node never becomes a member.**
- *Likely cause:* the Coherence listen port is blocked between hosts, or multicast is disabled on the
  segment.
- *Resolution:* confirm the listen port (default 7574, *verify for your version*) is open host-to-host;
  switch from multicast to **unicast WKA** listing the member hosts explicitly; restart and re-verify
  with `OC2MRUNTIME-Validation`.

**Symptom: members join then drop (join/leave churn).**
- *Likely cause:* network latency/packet loss, or clock skew between member hosts.
- *Resolution:* put members on a low-latency segment; enforce NTP so clocks agree; check logs for
  timeout entries and raise the relevant timeouts only if the network is known-good.

**Symptom: changes don't take effect.**
- *Likely cause:* Coherence changes require a server restart and it wasn't done.
- *Resolution:* restart the affected managed server(s); re-run `OC2MRUNTIME-Validation`.

**Symptom: extra/wrong servers appear as members.**
- *Likely cause:* the cluster is associated with more servers than intended.
- *Resolution:* correct the cluster targeting so only in-scope servers are members; restart affected
  nodes.

---

## JMS

**Symptom: JMS server won't start.**
- *Likely cause:* the persistent store path is missing/not writable by the product OS account, or the
  JDBC store's data source is down.
- *Resolution:* create/repair the file-store directory (correct ownership) or fix the JDBC store/data
  source; restart the JMS server.

**Symptom: a queue exists in WebLogic but no messages ever arrive.**
- *Likely cause:* the destination's JNDI name does not match what the C2M **Message Sender**
  references.
- *Resolution:* reconcile JNDI names with `OC2MRUNTIME-Report`; align the C2M message-sender JNDI or
  the destination JNDI so they match exactly.

**Symptom: messages pile up (pending count keeps rising).**
- *Likely cause:* no consumer is attached, the consumer errors, or a quota/backlog limit is hit.
- *Resolution:* confirm the consumer (C2M/IWS) is running and error-free; check destination quota and
  error state; drain/redeliver once the consumer is healthy.

**Symptom: persistent messages lost on restart.**
- *Likely cause:* messages were non-persistent, or the persistent store was not used/was recreated.
- *Resolution:* ensure the connection factory/destination use persistent delivery and a stable
  file/JDBC store that is backed up.

**Symptom: destinations don't appear on all cluster members.**
- *Likely cause:* standalone (not Uniform Distributed) destinations, or subdeployment targeting only
  one server.
- *Resolution:* use **Uniform Distributed** destinations and target the subdeployment
  (`C2MJMSSubDeployment`) to the cluster's JMS servers; re-verify.

---

## Inbound Web Services (IWS)

**Symptom: `iwsdeploy` fails.**
- *Likely cause:* the WebLogic Admin Server (or target managed server) is not running, or the stored
  user-config/key files are missing/wrong.
- *Resolution:* start the Admin Server and target server; recreate `$SPLEBASE/etc/.wlsuserconfig` /
  `.wlsuserkey` with `storeUserConfig`; re-run `iwsdeploy` from `$SPLEBASE/bin`.

**Symptom: EAR deploys but inbound calls return 404 / service not found.**
- *Likely cause:* the specific Inbound Web Service record isn't enabled, or the EAR wasn't
  regenerated after enabling it.
- *Resolution:* enable the required Inbound Web Service in C2M (Requirement 7); run `initialSetup` and
  redeploy so the EAR reflects the service list.

**Symptom: web-services functionality unavailable / config missing.**
- *Likely cause:* IWS not enabled in `configureEnv`, or `initialSetup` not run after enabling it.
- *Resolution:* run `configureEnv` to enable web services and set the **IWS Deployment Target** /
  **Web Admin Server Host**; run `initialSetup`; redeploy.

**Symptom: inbound calls fail TLS/handshake.**
- *Likely cause:* the WebLogic certificate isn't in the OUAF trust store.
- *Resolution:* import it with `initialSetup -i`; confirm the endpoint's TLS/WS-Policy matches the
  caller.

**Symptom: browser-UI deploy works in Test but the option is missing in Prod.**
- *Cause (expected):* the development-environment flag is intentionally **off** in production.
- *Resolution:* deploy via `iwsdeploy` from `$SPLEBASE/bin` — the correct production path; leave the
  flag off.

**Symptom: legacy XAI inbound service no longer works.**
- *Likely cause:* XAI has been superseded by IWS.
- *Resolution:* migrate the service to IWS per MOS **Doc ID 1644914.1**; define/enable the equivalent
  Inbound Web Service and redeploy.

---

## Escalation

If Coherence membership, JMS binding, or IWS deployment still fails after the above, gather the
`OC2MRUNTIME-Discovery` snapshot, `OC2MRUNTIME-Validation` output, and the relevant server logs, and
raise a My Oracle Support case referencing the certified version matrix (C2M ↔ WebLogic ↔ DB ↔ Java) —
some Coherence/IWS notes and patches are MOS-gated.

## Sources

- Oracle® Fusion Middleware — *Configuring and Managing Coherence Clusters*:
  https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/clust/coherence.html
- Oracle® Fusion Middleware — *Using WLST to Manage JMS Servers and JMS System Module Resources*:
  https://docs.oracle.com/en/middleware/standalone/weblogic-server/14.1.1.0/jmsad/wlst.html
- Oracle Utilities CCB — *Deploying Inbound Web Services (IWS)*:
  https://docs.oracle.com/en/industries/energy-water/ccb/29011/ccb-installation-guide/CCB-INSTALLATION-GUIDE/CCB_Install_Postinstall.09.09.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
