# Implementation Guide — Designing & Deploying C2M SOA Integration

This guide designs and deploys the C2M SOA/web-service integration surface end to end: the **named SOA
composites/adapters**, the **inbound (IWS)** and **outbound (Outbound Message)** flows, a **consistent
authN / error-handling / observability** standard, and validation of the integrations. It follows
**Assess → Configure → Pilot → Validate → Expand**, on the **pilot (non-production)** environment first,
with pass/fail gates and a rollback.

Object names below match the Overview naming convention and are reused throughout; substitute your
environment's standard names but keep them consistent across C2M config, WLST, and the SOA/OSB console.

> **Reference names:** External System `C2M-SOA-EXT`; Outbound Message Type `C2M-OMT-SOA` (processing
> method **SOA**); real-time sender `C2M-RTHTTP-SNDR`; JMS sender `C2M-JMS-SNDR`
> (`jms/C2MConnectionFactory` / `jms/C2MOutboundQueue`); Inbound Web Service `C2M-IWS-CustomerSync`; IWS
> EAR `spl-web-services`; composites `C2MInboundComposite` / `C2MOutboundComposite`; OSB proxy
> `C2M-OMT-SOA-Proxy` → business service `C2M-OMT-SOA-BizSvc`.

> **Safety rules for every phase.** Take config + SOA/OSB backups first (Requirement 8). IWS
> (re)deployment and some C2M metadata changes require redeploy/regeneration; do disruptive work in a
> maintenance window; keep the rollback (restore `config.xml` / `$SPLEBASE`, redeploy prior SOA
> projects) ready. **Never** put credentials or keystores in scripts or committed files.

---

## Phase 0 — Assess (read-only)

**Goal:** capture the current integration surface before changing anything.

1. Connect WLST read-only and record: managed-server states, whether `spl-web-services` is deployed and
   where, and any JMS resources used by integration.
2. Run **`OSOAC2M-Discovery`** (read-only) to snapshot the integration surface — deployed IWS/EAR,
   integration-relevant JMS, and (from the C2M schema) the External Systems, Outbound Message Types,
   Message Senders, and Inbound Web Service records — to an evidence file. Run
   **`OSOAC2M-ScopeHelper`** to fix the exact target set (which interfaces/servers/SOA projects you will
   touch) so later scripts act only in scope.
3. Confirm all Requirements pass on the pilot environment, and that the authN/error/observability
   standard (Requirement 7) is documented.

**Gate 0 (pass/fail):** you have a written baseline of the integration surface, an agreed target scope,
the integration inventory (Requirement 3), and a rollback point. Do not proceed until all pass.

---

## Phase 1 — Establish the integration standards (design once, reuse everywhere)

**Goal:** the consistent patterns that every subsequent interface will follow.

1. **Naming standard.** Adopt the Overview naming convention for External Systems, Outbound Message
   Types, Message Senders, Inbound Web Services, composites, and OSB proxy/business services. Record it
   so discovery/validation scripts can assert it.
2. **Authentication standard.** Decide one model and apply it to every interface: **TLS everywhere**;
   inbound IWS secured with HTTP Basic over TLS or **WS-Security/WS-Policy** (SOAP), OAuth where the
   release supports it (*verify for your version*); outbound senders authenticate to external systems
   with a dedicated service account/keystore. Import certificates into the OUAF trust store with
   `initialSetup -i`.
3. **Error-handling standard.** Define retry/redelivery limits, an **error destination** for JMS,
   **fault policies** for SOA composites, and how C2M **outbound-message error status** is monitored and
   retried. No interface silently drops on failure.
4. **Observability standard.** Turn on **SOA/OSB instance tracking** (composite instances, OSB pipeline
   reporting), rely on **C2M outbound-message status** for outbound flows, enable **IWS request logging**
   for inbound, and wire each into the environment's monitoring stack so every flow answers "did it work,
   and if not, where?".

**Gate 1:** the four standards are documented and a reference interface will be built to them.

---

## Phase 2 — Deploy & enable Inbound Web Services (inbound surface)

**Goal:** the `spl-web-services` EAR deployed and the in-scope inbound services responding to callers
(including SOA composites).

1. **Enable web services in the environment.** From `$SPLEBASE/bin`, run `configureEnv` (`-a`) and set
   the IWS parameters — the **IWS Deployment Target** and the **Web Admin Server Host**. Leave the
   development-environment (browser-deploy) flag **off** in production. Process the changes (`P`).
2. **Run initial setup.** From `$SPLEBASE/bin` run `initialSetup` so the templated config
   (`weblogic.xml`, `web.xml`, `spl.properties`, etc.) is regenerated for IWS.
3. **Prepare headless WebLogic credentials.** Ensure `$SPLEBASE/etc/.wlsuserconfig` and `.wlsuserkey`
   exist (created with WLST `storeUserConfig`) so deploys run without an interactive password. Import the
   WebLogic certificate into the OUAF trust store with `initialSetup -i` if TLS is in play.
4. **Deploy the EAR.** With the Admin Server (and target managed server) **RUNNING**, from
   `$SPLEBASE/bin`:
   ```
   cd $SPLEBASE/bin
   ksh ./iwsdeploy.sh        # deploys the spl-web-services EAR to the IWS Deployment Target
   ```
   (On Windows the equivalent is `iwsdeploy.cmd`.) The Admin Server **must be up** before deploying.
5. **Define and enable the required Inbound Web Services.** In C2M, create/activate the **Inbound Web
   Service** records for the in-scope inbound integrations (reference **`C2M-IWS-CustomerSync`**),
   backed by the intended business service/service script/BO — SOAP or REST as designed. Enable **only**
   what integrations need; redeploy if the service list changed.
6. **Apply the authN standard** to each IWS endpoint (TLS + Basic/WS-Security/OAuth per Phase 1).
7. **Verify** with **`OSOAC2M-Validation`**: `spl-web-services` is **deployed/active** on the target, and
   each in-scope inbound service's WSDL/endpoint responds to a well-formed, authenticated test call.

**Gate 2:** `spl-web-services` active; each in-scope inbound service enabled, secured, and returning a
well-formed response (or WSDL); disabled/out-of-scope services are not exposed.

---

## Phase 3 — Configure Outbound Messages (outbound surface)

**Goal:** C2M emits outbound integration through the correct transport per interface.

1. **Create the External System.** In C2M, define the external system **`C2M-SOA-EXT`** representing the
   integration target (or one external system per real target).
2. **Create the Outbound Message Type & set the processing method.** Define **`C2M-OMT-SOA`** and set the
   **processing method**:
   - **SOA** — for asynchronous/near-real-time flows polled by Oracle Service Bus. The outbound message
     lands in the **outbound message staging table**; OSB polls it via the **OUAF Outbound Message**
     custom transport (Phase 4).
   - **Real-time** — attach the HTTP/SOAP **Message Sender** **`C2M-RTHTTP-SNDR`** for a synchronous call
     to an external web service.
   - **JMS** — attach the JMS **Message Sender** **`C2M-JMS-SNDR`** (connection factory
     `jms/C2MConnectionFactory`, destination `jms/C2MOutboundQueue`) for asynchronous queue hand-off.
3. **Create the Message Sender(s)** referenced above, pointing at the correct endpoint URL / JNDI
   destination, with the agreed authN and the error/retry settings from the standard.
4. **Wire the trigger.** Confirm the C2M algorithm/BO/service script that raises the outbound message
   references **`C2M-OMT-SOA`** and **`C2M-SOA-EXT`** so events actually stage.
5. **Reconcile transport vs. design.** A real-time interface must use a real-time sender; an
   asynchronous one the SOA/OSB or JMS path. A mismatch stages messages that never dispatch.
6. **Verify** with `OSOAC2M-Validation` / `OSOAC2M-Report`: the External System, Outbound Message Type
   (processing method), and Message Sender exist and reconcile; for SOA flows, staged messages are
   visible for OSB to poll.

**Gate 3:** outbound configuration in place and reconciled — external system, outbound message type
(correct processing method), and sender all consistent with the interface's direction and timing.

---

## Phase 4 — Build & deploy the SOA composites / adapters (middleware tier)

**Goal:** named, reusable composites/services that mediate between C2M and external systems, using
standard adapters and the agreed patterns.

1. **Inbound composite (`C2MInboundComposite`).** In SOA Suite / Service Bus, build a composite that
   receives from the external system (SOAP/HTTP or JCA adapter), transforms, and **invokes the C2M IWS**
   **`C2M-IWS-CustomerSync`** — using the **Oracle Utilities Adapter** (a SOAP/REST catalog of OUAF
   inbound/outbound services) where available, or a plain SOAP/HTTP reference otherwise. Keep
   transformation in the composite, not in C2M.
2. **Outbound composite / OSB pipeline (`C2MOutboundComposite`).** For the **SOA** processing method,
   build the **OUAF Outbound Message** flow on OSB: a **proxy service** **`C2M-OMT-SOA-Proxy`** (one per
   outbound message type) that polls the staging table via the OUAF Outbound Message transport, performs
   transformation, and routes through the **business service** **`C2M-OMT-SOA-BizSvc`** to the external
   system.
3. **Use standard JCA adapters** (SOAP/HTTP, JMS, Database, File) for external connectivity so the
   integration stays on open, portable mechanisms rather than bespoke code.
4. **Apply fault policies and instance tracking** (the error-handling + observability standards) to every
   composite/pipeline: retry/fault handling on faults, instance tracking on so flows are traceable in
   Enterprise Manager / the OSB console.
5. **Deploy** the composite(s)/OSB project(s) to the middleware tier (keep the exported SAR/JAR/configjar
   as the rollback artifact), configure endpoints/credentials from the environment/secret store — **not**
   in the project — and enable.
6. **Verify** with `OSOAC2M-Validation`: `spl-web-services` reachable from the middleware host, the
   composites/proxies deployed and active, and a test instance flows end to end.

**Gate 4:** `C2MInboundComposite`, `C2MOutboundComposite` (and the OSB proxy/business service) deployed
and active, using standard adapters, fault policies, and instance tracking; endpoints/credentials sourced
securely.

---

## Phase 5 — Validate the integration end to end (Pilot)

**Goal:** prove inbound + outbound + middleware together on the pilot before expanding.

1. Run **`OSOAC2M-Validation`** across all in-scope interfaces for one consolidated pass on IWS
   deployment/health, outbound-message configuration reconciliation, and composite/proxy status.
2. Run **`OSOAC2M-Report`** (read-only) to produce a health/coverage report — which IWS are enabled and
   responding, which External System/Outbound Message Type/Sender sets reconcile, which composites are
   active, and any staged-but-undispatched outbound messages.
3. Execute the functional checks in **05-testing.md** (an inbound call drives C2M; an outbound event
   dispatches through the correct transport; the authN/error/observability standard holds).
4. If anything is off, correct with **`OSOAC2M-Remediation`** (**dry-run by default** — review the
   planned actions, then re-run with the explicit apply flag inside the change window).

**Gate 5:** the report shows the inbound, outbound, and middleware surfaces healthy on the pilot and the
functional tests pass.

---

## Phase 6 — Expand to remaining environments

1. Repeat Phases 2–5 per environment (Test → Prod), each behind its own change window, backup, and
   rollback. Promote the **same named objects** and redeploy the **same** SOA/OSB project exports.
2. Use `OSOAC2M-ScopeHelper` to retarget the scripts to each environment's interface/server set so you
   run the **same** validated steps everywhere.
3. In production, keep the development-environment IWS flag **off**, enable only required inbound
   services, source all credentials from the secret store, and confirm the report is clean before closing
   the change.

**Final gate:** every target environment shows a clean `OSOAC2M-Report` — IWS responding, outbound
dispatching through the right transport, composites active — with a captured rollback point.

---

## Rollback

- **IWS:** undeploy `spl-web-services` (or redeploy the prior EAR) and disable the newly enabled inbound
  services.
- **Outbound Messages:** revert the External System / Outbound Message Type / Message Sender metadata
  from the `$SPLEBASE` backup (or disable the newly added ones).
- **SOA/OSB:** redeploy the previous composite/OSB project export (SAR/JAR/configjar); undeploy the new
  one.
- Re-run `OSOAC2M-Validation` to confirm the environment is back to its pre-change baseline.

## Sources

- Oracle Utilities — *Polling Outbound Messages Using OSB* (processing method SOA, OUAF Outbound Message
  transport, proxy/business service, outbound message staging table):
  https://docs.oracle.com/en/industries/utilities/meter-solution-cloud-service/264/mscs-user-guides/Topics/F1_93XAI_Polling_Outbound_Message_Using_OSB.html
- Oracle Utilities C2M — *Deploying Inbound Web Services (IWS)* (`iwsdeploy`, `spl-web-services`,
  `configureEnv`/`initialSetup`):
  https://docs.oracle.com/en/industries/energy-water/advanced-meter/29011/c2m-installation-guide/C2M-INSTALLATION-GUIDE/C2M_Install_Postinstall.09.09.html
- Oracle Utilities C2M — *Inbound REST Web Services* (IWS SOAP/REST; HTTP methods; XAI retired):
  https://docs.oracle.com/en/industries/energy-water/advanced-meter/2.9.0.0.0/c2m-user-guides/C2M_29000/F1_93XAI_REST_Inbound_Web_Service_Overview.html
- Oracle® Fusion Middleware — *Understanding Technology Adapters* / JCA adapters (SOAP/HTTP, JMS, DB,
  File) for SOA composites:
  https://docs.oracle.com/en/middleware/soa-suite/integration-adapters/12.2.1.3/develop-soa-adapters/overview3.html
- Oracle — *Using the Oracle Utilities Adapter with Oracle Integration* (SOAP/REST catalog; trigger
  consumes outbound message, invoke calls inbound web services):
  https://docs.oracle.com/en/cloud/paas/application-integration/utilities-adapters/oracle-utilities-adapter-capabilities.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
