# Troubleshooting — C2M SOA Integration

Common failures across the C2M integration surface, as **symptom → likely cause → resolution**. Start
from the read-only scripts (`OSOAC2M-Discovery` + the SQL companion, `OSOAC2M-Validation`,
`OSOAC2M-Report`) to localise the problem before changing anything. All fixes are non-production-first
with a rollback.

---

## Inbound Web Services (IWS)

**Symptom: `iwsdeploy` fails.**
- *Likely cause:* the WebLogic Admin Server (or target managed server) is not running, or the stored
  user-config/key files are missing/wrong.
- *Resolution:* start the Admin Server and target server; recreate `$SPLEBASE/etc/.wlsuserconfig` /
  `.wlsuserkey` with WLST `storeUserConfig`; re-run `iwsdeploy` from `$SPLEBASE/bin`.

**Symptom: EAR deploys but an inbound call returns 404 / service not found.**
- *Likely cause:* the specific Inbound Web Service record isn't enabled, or the EAR wasn't regenerated
  after enabling it.
- *Resolution:* enable the required Inbound Web Service in C2M (Requirement 4); run `initialSetup` and
  redeploy so the EAR reflects the service list.

**Symptom: legacy XAI inbound service no longer works.**
- *Likely cause:* XAI is retired — the release no longer supports it.
- *Resolution:* migrate the service to IWS per MOS **Doc ID 1644914.1**; define/enable the equivalent
  Inbound Web Service and redeploy.

**Symptom: inbound calls fail TLS/handshake or authentication.**
- *Likely cause:* the caller's certificate isn't trusted, or the endpoint's authN model doesn't match
  the caller.
- *Resolution:* import the certificate into the OUAF trust store with `initialSetup -i`; align the
  endpoint's TLS/WS-Policy/Basic/OAuth to the caller and the agreed authN standard (*verify for your
  version*).

**Symptom: browser-UI deploy works in Test but the option is missing in Prod.**
- *Cause (expected):* the development-environment flag is intentionally **off** in production.
- *Resolution:* deploy via `iwsdeploy` from `$SPLEBASE/bin` — the correct production path; leave the flag
  off.

---

## Outbound Messages

**Symptom: an outbound event is raised but nothing reaches the external system.**
- *Likely cause:* the Outbound Message Type's **processing method** doesn't match the intended transport,
  or no Message Sender is attached.
- *Resolution:* in C2M, confirm the External System (`C2M-SOA-EXT`) + Outbound Message Type
  (`C2M-OMT-SOA`) and that the processing method (SOA / real-time / JMS) matches a valid, attached
  Message Sender pointing at the right endpoint/queue (Requirement 5).

**Symptom: messages stack up in the outbound message staging table (SOA method).**
- *Likely cause:* Oracle Service Bus isn't polling — the OSB proxy (`C2M-OMT-SOA-Proxy`) is down, the
  **OUAF Outbound Message** transport isn't installed/configured, or the external system on the message
  can't be reached.
- *Resolution:* confirm the OSB proxy is deployed and running, the OUAF Outbound Message transport is
  installed, and the business service (`C2M-OMT-SOA-BizSvc`) target is reachable; check OSB instance
  tracking for faults.

**Symptom: a real-time sender times out or errors.**
- *Likely cause:* the external web service is unreachable/slow, or credentials/certificate are wrong.
- *Resolution:* verify connectivity and credentials from the C2M host to the external endpoint; check
  the outbound-message **error status** and the sender's retry settings; fix connectivity/auth and
  reprocess.

**Symptom: JMS outbound sender enqueues nothing / errors.**
- *Likely cause:* the sender's JNDI destination/connection factory doesn't match what exists in WebLogic,
  or the JMS server/store is down.
- *Resolution:* reconcile the sender's JNDI (`jms/C2MConnectionFactory` / `jms/C2MOutboundQueue`) against
  the module (`OSOAC2M-Report`); confirm the integration JMS server is **RUNNING** with a healthy
  persistent store.

**Symptom: outbound messages pile up on the JMS queue (pending count rising, zero consumers).**
- *Likely cause:* no consumer (SOA/external) is attached, or the consumer errors.
- *Resolution:* confirm the consumer/OSB pipeline is running and error-free; check destination quota and
  error state; drain/redeliver once the consumer is healthy. `OSOAC2M-Report` flags "backlog & 0
  consumer".

---

## SOA composites / middleware

**Symptom: a composite/OSB project won't deploy.**
- *Likely cause:* a missing adapter/JCA connection factory, an unresolved reference (e.g. the C2M IWS
  endpoint), or the wrong environment target.
- *Resolution:* confirm the JCA adapter and connection factory exist on the SOA/OSB domain, the
  referenced IWS endpoint is reachable, and the deploy targets the intended server; redeploy the exported
  SAR/JAR/configjar.

**Symptom: the composite runs but the flow can't be traced.**
- *Likely cause:* instance tracking/auditing is off.
- *Resolution:* enable instance tracking (composite auditing / OSB pipeline reporting) per the
  observability standard so every flow is visible in Enterprise Manager / the OSB console.

**Symptom: a faulting instance disappears with no retry.**
- *Likely cause:* no fault policy / no error destination is configured.
- *Resolution:* attach a fault policy (SOA) or route to an error destination (OSB/JMS) with bounded
  retries per the error-handling standard; make retries idempotent-safe (correlate on a business key).

**Symptom: the composite calls C2M but authentication is rejected.**
- *Likely cause:* the composite uses credentials/policy that don't match the IWS endpoint's authN.
- *Resolution:* align the composite's outbound security (Basic/WS-Security/OAuth + TLS trust) to the IWS
  endpoint and the agreed authN standard.

---

## Cross-cutting

**Symptom: it works in Test but fails in Prod.**
- *Likely cause:* environment-specific endpoints/credentials were hard-coded, or names differ between
  environments.
- *Resolution:* source endpoints/credentials from the environment/secret store (never the
  composite/script), and reuse the **same named objects** across environments (retarget with
  `OSOAC2M-ScopeHelper`).

**Symptom: C2M config and the deployed surface disagree.**
- *Likely cause:* the C2M metadata (external system / outbound type / sender / inbound service) and the
  WebLogic/SOA endpoints drifted.
- *Resolution:* run `OSOAC2M-Discovery.sql` (C2M side) and `OSOAC2M-Discovery.py` (WebLogic side) and
  reconcile the names/JNDI/endpoints so both sides agree.

---

## Escalation

If IWS deployment, outbound dispatch, or a composite still fails after the above, gather the
`OSOAC2M-Discovery` snapshot (WLST + SQL), `OSOAC2M-Validation` output, the relevant server logs, and the
SOA/OSB instance-tracking detail, and raise a My Oracle Support case referencing the certified version
matrix (C2M ↔ WebLogic ↔ SOA/OSB ↔ DB ↔ Java) — some integration notes, adapters, and patches are
MOS-gated (e.g. XAI → IWS, Doc ID 1644914.1).

## Sources

- Oracle Utilities — *Polling Outbound Messages Using OSB* (processing method SOA; OUAF Outbound Message
  transport; proxy/business service; staging table):
  https://docs.oracle.com/en/industries/utilities/meter-solution-cloud-service/264/mscs-user-guides/Topics/F1_93XAI_Polling_Outbound_Message_Using_OSB.html
- Oracle Utilities C2M — *Deploying Inbound Web Services (IWS)*:
  https://docs.oracle.com/en/industries/energy-water/advanced-meter/29011/c2m-installation-guide/C2M-INSTALLATION-GUIDE/C2M_Install_Postinstall.09.09.html
- Oracle Utilities C2M — *Inbound REST Web Services* (XAI retired):
  https://docs.oracle.com/en/industries/energy-water/advanced-meter/2.9.0.0.0/c2m-user-guides/C2M_29000/F1_93XAI_REST_Inbound_Web_Service_Overview.html
- Oracle® Fusion Middleware — *Understanding Technology Adapters* (JCA adapters):
  https://docs.oracle.com/en/middleware/soa-suite/integration-adapters/12.2.1.3/develop-soa-adapters/overview3.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
