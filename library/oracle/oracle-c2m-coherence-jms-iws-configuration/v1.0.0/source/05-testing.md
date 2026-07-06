# Testing — Validating Coherence, JMS & IWS

These tests prove the three runtime layers work **individually and together**, on the pilot
environment first. Each test states the **objective**, **steps**, and an explicit **pass criterion**.
Run the read-only scripts (`OC2MRUNTIME-Discovery`, `OC2MRUNTIME-Validation`, `OC2MRUNTIME-Report`)
for repeatable evidence; capture output as change-record proof.

> Run tests on **non-production first**. A failing gate here is a stop — fix the cause (see
> 06-troubleshooting.md) before promoting.

---

## A. Coherence clustering

### A1 — Cluster exists and is targeted
- **Objective:** the named cluster is defined and associated with the right servers.
- **Steps:** run `OC2MRUNTIME-Validation`; or in the console *Environment → Coherence Clusters* open
  `c2m-coherence-cluster` and review its targets.
- **Pass:** `c2m-coherence-cluster` exists, transport/listen port match the design (default 7574,
  *verify for your version*), and it is targeted to every in-scope server/cluster.

### A2 — All nodes are members
- **Objective:** every in-scope managed server actually joined the cluster.
- **Steps:** with all in-scope managed servers **RUNNING**, run `OC2MRUNTIME-Validation` and read the
  member list/count; corroborate with "member joined/left" entries in each server log.
- **Pass:** member count equals the expected node count; no missing members; no repeated
  join/leave churn.

### A3 — No discovery errors after restart
- **Objective:** the cluster forms cleanly on a cold start (changes need a restart).
- **Steps:** restart the in-scope servers; scan logs for Coherence discovery/timeout errors; re-run
  `OC2MRUNTIME-Validation`.
- **Pass:** clean formation, no unicast WKA/multicast discovery errors, stable membership.

---

## B. JMS messaging

### B1 — JMS server and destinations present
- **Objective:** the JMS objects exist and are bound to JNDI.
- **Steps:** run `OC2MRUNTIME-Validation`; or console *Services → Messaging → JMS Modules →
  C2MJMSModule*.
- **Pass:** `C2MJMSServer` is **RUNNING**; `C2MConnectionFactory` (`jms/C2MConnectionFactory`),
  `C2MRealTimeQueue` (`jms/C2MRealTimeQueue`), `C2MEventTopic` (`jms/C2MEventTopic`) all present with
  the expected JNDI names and correct subdeployment targeting.

### B2 — Message round-trip (produce → consume)
- **Objective:** a message actually flows through the queue.
- **Steps:** on `C2MRealTimeQueue`, note the current/pending counts (Monitoring tab or
  `OC2MRUNTIME-Report`); send a test message (a controlled C2M message-sender test, or WebLogic's JMS
  test facility on the destination); observe the count increment then drain as it is consumed.
- **Pass:** the test message is enqueued and then consumed (pending returns to baseline); no messages
  land in an error/pending-forever state.

### B3 — JNDI names reconcile with C2M message senders
- **Objective:** what C2M sends to is what exists in WebLogic.
- **Steps:** compare the JNDI names in the C2M **Message Sender** config against the module's
  destinations (from `OC2MRUNTIME-Report`).
- **Pass:** every JNDI name the C2M senders reference resolves to a real destination — no orphans on
  either side.

### B4 — Persistence survives restart
- **Objective:** persistent messages are not lost on restart.
- **Steps:** enqueue a persistent test message, do **not** consume it, restart the JMS server's host,
  re-check the queue.
- **Pass:** the persistent message is still present after restart (file/JDBC store intact).

---

## C. Inbound Web Services (IWS)

### C1 — EAR deployed and active
- **Objective:** the web-services application is live on the IWS Deployment Target.
- **Steps:** run `OC2MRUNTIME-Validation`; or console *Deployments*.
- **Pass:** `spl-web-services` is **Active/OK** on the intended target server.

### C2 — Inbound service responds
- **Objective:** an enabled inbound service answers a call.
- **Steps:** retrieve the WSDL/endpoint for an in-scope Inbound Web Service; issue a well-formed test
  request (SOAP/REST as applicable) with valid credentials.
- **Pass:** the service returns a well-formed, expected response (or the WSDL loads); disabled/out-of-
  scope services are **not** exposed.

### C3 — End-to-end integration path
- **Objective:** an inbound call drives real C2M behaviour, including any JMS hand-off.
- **Steps:** call an inbound service that triggers downstream work; confirm the C2M record/outcome and,
  where the flow hands off asynchronously, confirm the message appears on `C2MRealTimeQueue` and is
  consumed.
- **Pass:** the business outcome is correct **and** the asynchronous hand-off flows through JMS —
  proving the three layers work together.

---

## D. Consolidated runtime health

### D1 — Full runtime report is clean
- **Objective:** one artifact proving Coherence + JMS + IWS are healthy across scope.
- **Steps:** run `OC2MRUNTIME-Report` across the in-scope servers; review coverage (members present,
  destinations healthy, inbound services enabled/responding).
- **Pass:** report shows all three layers healthy with no gaps for any in-scope server — the pilot
  validation gate. Retain the report as change evidence.

---

*Exit criteria for the pilot:* A1–A3, B1–B4, C1–C3, and D1 all pass, with saved script output as
evidence. Only then expand to the next environment.
