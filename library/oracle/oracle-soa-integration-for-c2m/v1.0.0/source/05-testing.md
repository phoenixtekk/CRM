# Testing — Validating C2M SOA Integration

These tests prove the integration surface works **individually and together** — inbound (IWS), outbound
(Outbound Messages), and the SOA/OSB middleware — on the pilot environment first. Each test states the
**objective**, **steps**, and an explicit **pass criterion**. Run the read-only scripts
(`OSOAC2M-Discovery`, `OSOAC2M-Validation`, `OSOAC2M-Report`) for repeatable evidence; capture output as
change-record proof.

> Run tests on **non-production first**. A failing gate here is a stop — fix the cause (see
> 06-troubleshooting.md) before promoting.

---

## A. Inbound Web Services (IWS)

### A1 — EAR deployed and active
- **Objective:** the web-services container is live on the IWS Deployment Target.
- **Steps:** run `OSOAC2M-Validation`; or console *Deployments*.
- **Pass:** `spl-web-services` is **Active/OK** on the intended target server.

### A2 — Inbound service responds and is secured
- **Objective:** an enabled inbound service answers an authenticated call.
- **Steps:** retrieve the WSDL/endpoint for **`C2M-IWS-CustomerSync`**; issue a well-formed test request
  (SOAP or REST) with **valid** credentials over TLS, then repeat with **invalid**/missing credentials.
- **Pass:** the valid call returns a well-formed, expected response (or the WSDL loads); the
  unauthenticated/invalid call is **rejected** (authN standard enforced); disabled/out-of-scope services
  are not exposed.

### A3 — REST method coverage (where REST is used)
- **Objective:** the inbound REST service honours only its defined operations.
- **Steps:** call the defined HTTP methods (from **GET/PATCH/POST/PUT/DELETE**) for the service and one
  undefined method.
- **Pass:** defined operations behave as specified; an undefined method is refused — no unintended
  surface.

---

## B. Outbound Messages

### B1 — Outbound configuration reconciles
- **Objective:** the external system, outbound message type, and sender are consistent.
- **Steps:** run `OSOAC2M-Report`; review **`C2M-SOA-EXT`**, **`C2M-OMT-SOA`** (processing method), and
  the referenced Message Sender.
- **Pass:** the External System, Outbound Message Type, and Message Sender all exist and reconcile; the
  processing method matches the interface's intended transport (SOA / real-time / JMS).

### B2 — Real-time outbound dispatches synchronously
- **Objective:** a real-time interface calls the external web service and returns.
- **Steps:** trigger the C2M action that raises an outbound message on a **real-time** type using
  **`C2M-RTHTTP-SNDR`**; observe the outbound-message status and the external system's receipt.
- **Pass:** the message dispatches synchronously, the outbound-message status shows success, and the
  external system received it; a forced failure is captured as an **error status** (not a silent drop).

### B3 — SOA/OSB outbound is polled and dispatched
- **Objective:** an asynchronous (processing method **SOA**) message is picked up by OSB.
- **Steps:** trigger an outbound message on **`C2M-OMT-SOA`**; confirm it lands in the **outbound message
  staging table**; confirm the OSB **`C2M-OMT-SOA-Proxy`** polls it (OUAF Outbound Message transport) and
  routes via **`C2M-OMT-SOA-BizSvc`** to the external system.
- **Pass:** the staged message is consumed by OSB in near-real-time and delivered; the OSB instance is
  visible in tracking; no message is left staged-but-undispatched.

### B4 — JMS outbound hand-off (where JMS is used)
- **Objective:** an asynchronous JMS interface enqueues correctly.
- **Steps:** trigger an outbound message on the **JMS** sender **`C2M-JMS-SNDR`**; observe
  `jms/C2MOutboundQueue` pending/consumed counts.
- **Pass:** the message is enqueued and then consumed (pending returns to baseline); the JNDI destination
  matches what the sender references.

---

## C. SOA composites / middleware

### C1 — Composites deployed and active
- **Objective:** the named middleware artifacts are live.
- **Steps:** run `OSOAC2M-Validation`; or the SOA Enterprise Manager / OSB console.
- **Pass:** **`C2MInboundComposite`**, **`C2MOutboundComposite`**, and the OSB proxy/business service are
  deployed and **active**.

### C2 — Instance tracking & fault handling work
- **Objective:** flows are observable and faults are handled per the standard.
- **Steps:** run a normal instance and a deliberately faulting instance (e.g. bad payload / unreachable
  target); inspect instance tracking and the configured **fault policy** / error destination.
- **Pass:** the normal instance is traceable end to end in tracking; the faulting instance is caught by
  the fault policy / lands in the error destination and is retried per the standard — **not** lost.

---

## D. End-to-end integration

### D1 — Inbound path drives real C2M behaviour
- **Objective:** an external call through the middleware changes C2M.
- **Steps:** call **`C2MInboundComposite`** from the external system; confirm it invokes
  **`C2M-IWS-CustomerSync`** and the expected C2M record/outcome results.
- **Pass:** the C2M business outcome is correct and the flow is traceable in SOA/OSB tracking and IWS
  logging.

### D2 — Outbound path reaches the external system
- **Objective:** a C2M event reaches the external system through the correct transport.
- **Steps:** trigger the C2M event; follow it through the outbound message → sender/OSB → external system;
  confirm receipt.
- **Pass:** the external system received the correct payload; the outbound-message status and SOA/OSB
  tracking corroborate success end to end.

---

## E. Consolidated health

### E1 — Full integration report is clean
- **Objective:** one artifact proving inbound + outbound + middleware are healthy across scope.
- **Steps:** run `OSOAC2M-Report` across the in-scope interfaces; review coverage (IWS enabled/responding,
  outbound configs reconciled, composites active, no staged-but-undispatched messages).
- **Pass:** report shows the whole surface healthy with no gaps for any in-scope interface — the pilot
  validation gate. Retain the report as change evidence.

---

*Exit criteria for the pilot:* A1–A3, B1–B4, C1–C2, D1–D2, and E1 all pass (for the mechanisms in
scope), with saved script output as evidence. Only then expand to the next environment.
