# Solution Overview — SOA Integration for C2M (Web Services & APIs)

Oracle Utilities **Customer to Meter (C2M)** rarely stands alone. Even though C2M is a single-instance
product that folds **CC&B**, **MDM**, and service-order/device management into one **Oracle Utilities
Application Framework (OUAF)** stack, in the enterprise it still exchanges data with meters, billing,
analytics, CRM, and other systems. A great deal of that exchange runs through **Oracle SOA** and web
services/APIs. This solution defines a **consistent, supportable, observable SOA integration approach
for C2M**: the composites and adapters between C2M and other systems, the inbound/outbound web services
(**IWS**), and the API patterns — so integrations stop being one-off snowflakes and become a repeatable
platform capability.

> **What this solution is and is not.** This is an **integration architecture and administration**
> solution: how to design, name, deploy, secure, and observe the SOA/web-service integration surface of
> C2M using Oracle's supported mechanisms. It is **not** an Oracle SOA Suite internals course — deep
> BPEL/Mediator/OSB engine internals are deferred to Oracle's SOA Suite / Service Bus documentation and
> are cited, not reproduced.

## The C2M integration surface — three mechanisms

C2M exposes and consumes integration through three mechanisms that this solution treats as one coherent
surface:

| Mechanism | Direction | OUAF / SOA object | What it enables |
|-----------|-----------|-------------------|-----------------|
| **Inbound Web Services (IWS)** | **Into** C2M | OUAF **Inbound Web Service** metadata + the `spl-web-services` EAR on WebLogic | External systems call C2M business services as **SOAP or REST** endpoints. IWS is the supported replacement for the retired **XAI** inbound layer. |
| **Outbound Messages** | **Out of** C2M | OUAF **Outbound Message Type** + **External System** + **Message Sender**; for SOA the processing method is **SOA** | C2M emits events/requests to external systems — real-time (HTTP/web-service sender) or asynchronous (JMS, or the **OUAF Outbound Message** OSB transport). |
| **SOA composites / adapters** | Both | Oracle **SOA Suite / Service Bus** composites, **JCA adapters** (HTTP/SOAP, JMS, DB, File) and the **Oracle Utilities / SOA Suite adapters** | The middleware tier that mediates, transforms, routes, and orchestrates between C2M and other systems. |

### Inbound: IWS (SOAP & REST)
IWS is the OUAF mechanism that exposes C2M business services (business services, service scripts, BOs)
as web-service operations. Since C2M **no longer supports XAI**, all inbound integration into C2M is via
IWS. Inbound REST web services support **GET, PATCH, POST, PUT, DELETE**; SOAP inbound services are
described by a WSDL. The container is the `spl-web-services` Java EE application deployed to WebLogic with
the OUAF `iwsdeploy` utility. External callers — including SOA composites — invoke these endpoints.

### Outbound: Outbound Messages (real-time & asynchronous)
C2M initiates integration by creating an **Outbound Message** (typically from an algorithm, BO, or
service script). Routing is governed by the **External System** and the **Outbound Message Type**, whose
**processing method** selects the transport:

- **Real-time** — a **Message Sender** of a real-time class (an HTTP/SOAP sender that calls an external
  web service synchronously).
- **SOA/OSB** — the processing method **SOA**: the outbound message lands in the **outbound message
  staging table**, and Oracle Service Bus polls it asynchronously via the product's **OUAF Outbound
  Message** custom transport (a proxy service per outbound message type routes to a business service).
- **JMS** — a JMS message sender hands the payload to a queue/topic for asynchronous consumption.

### The middleware tier: SOA composites & adapters
Between C2M and the wider estate sits **Oracle SOA Suite / Oracle Service Bus**. Integrations are built
as **composites/services** that use **JCA adapters** (SOAP/HTTP, JMS, Database, File) and, where present,
the **Oracle Utilities Adapter** (a SOAP/REST catalog of OUAF inbound/outbound services) or the **SOA
Suite Adapter**. The middleware is where cross-system concerns live: transformation, routing, retry,
and correlation — so C2M stays clean and the integration logic is externalised and reusable.

## Naming convention used throughout

So the docs, scripts, and console/WLST steps line up, this solution refers to a single **named set of
objects** and reuses those names everywhere. **Substitute your own environment's standard names — but
pick them once and reuse them, exactly as shown here.**

| Role | Reference name |
|------|----------------|
| C2M External System (SOA target) | **`C2M-SOA-EXT`** |
| Outbound Message Type (SOA) | **`C2M-OMT-SOA`** (processing method **SOA**) |
| Real-time HTTP/SOAP Message Sender | **`C2M-RTHTTP-SNDR`** |
| JMS Message Sender | **`C2M-JMS-SNDR`** (connection factory `jms/C2MConnectionFactory`, queue `jms/C2MOutboundQueue`) |
| Representative Inbound Web Service | **`C2M-IWS-CustomerSync`** |
| IWS container application (EAR) | **`spl-web-services`** |
| SOA composite (inbound → C2M) | **`C2MInboundComposite`** |
| SOA composite (C2M → external) | **`C2MOutboundComposite`** |
| Oracle Service Bus proxy (per OMT) | **`C2M-OMT-SOA-Proxy`** → business service **`C2M-OMT-SOA-BizSvc`** |

## How the mechanisms work together

A typical **inbound** flow: an external system calls **`C2MInboundComposite`** → the composite transforms
and invokes the C2M IWS **`C2M-IWS-CustomerSync`** on `spl-web-services` → C2M processes it. A typical
**outbound** flow: C2M raises an **Outbound Message** on type **`C2M-OMT-SOA`** → OSB's
**`C2M-OMT-SOA-Proxy`** polls the staging table via the **OUAF Outbound Message** transport → transforms →
routes through **`C2M-OMT-SOA-BizSvc`** to the external system. Real-time flows instead use the
**`C2M-RTHTTP-SNDR`** sender to call an external web service synchronously; asynchronous flows use
**`C2M-JMS-SNDR`** onto a JMS queue.

## Consistent, supportable, observable — the point of the solution

- **Consistent** — one naming standard, one authN model, one error-handling pattern, one observability
  approach applied to every integration, rather than per-interface improvisation.
- **Supportable** — named, inventoried composites/services/IWS that an operator can discover, validate,
  and reason about; the automation scripts inventory and check exactly these.
- **Observable** — every flow emits enough (SOA/OSB instance tracking, C2M outbound-message status, IWS
  request logging) to answer "did it work, and if not, where did it fail?".
- **Low lock-in** — favour standard SOAP/REST over WebLogic and open JCA adapters, keep transformation in
  the middleware tier (not buried in C2M), and name/document interfaces so the middleware could be
  swapped (e.g. to Oracle Integration / OIC) without re-engineering C2M.

## Deployment model

Like every Oracle solution in this catalogue, work proceeds **Assess → Configure → Pilot → Validate →
Expand**, on a **non-production environment first**, with explicit pass/fail gates and a documented
rollback before any production change. The included automation is **WLST (Jython), shell, and SQL** —
never PowerShell — because that is the authentic C2M/WebLogic/SOA toolchain.

## Version note

- **C2M 25.4** (minimum **v2.9**) on **Oracle WebLogic Server 14c** is the reference stack; Oracle SOA
  Suite / Oracle Service Bus versions are those certified alongside it. Earlier releases differ (notably
  the **XAI → IWS** transition — XAI is no longer supported). Where a menu path, utility flag, adapter
  capability, or default differs by release, the step is flagged **"verify for your version"**.
- Some integration notes, adapter downloads, and patches are entitlement-gated on **My Oracle Support
  (MOS)** — for example **Doc ID 1644914.1 — Migrating from XAI to IWS**; this solution points to them
  rather than reproducing gated content.

## Sources

- Oracle Utilities — *Polling Outbound Messages Using OSB* (OUAF Outbound Message transport, processing
  method SOA, proxy/business service, outbound message staging table):
  https://docs.oracle.com/en/industries/utilities/meter-solution-cloud-service/264/mscs-user-guides/Topics/F1_93XAI_Polling_Outbound_Message_Using_OSB.html
- Oracle Utilities C2M — *Inbound REST Web Services* (IWS overview; HTTP methods; XAI retired):
  https://docs.oracle.com/en/industries/energy-water/advanced-meter/2.9.0.0.0/c2m-user-guides/C2M_29000/F1_93XAI_REST_Inbound_Web_Service_Overview.html
- Oracle Utilities C2M — *Deploying Inbound Web Services (IWS)* (installation guide; `iwsdeploy`,
  `spl-web-services`): https://docs.oracle.com/en/industries/energy-water/advanced-meter/29011/c2m-installation-guide/C2M-INSTALLATION-GUIDE/C2M_Install_Postinstall.09.09.html
- Oracle® Fusion Middleware — *Understanding Technology Adapters* / *Oracle JCA Adapter for JMS* (SOA
  Suite JCA adapters): https://docs.oracle.com/en/middleware/soa-suite/integration-adapters/12.2.1.3/develop-soa-adapters/overview3.html
- Oracle — *Using the Oracle Utilities Adapter with Oracle Integration* (SOAP/REST catalog of OUAF
  inbound/outbound services; trigger consumes outbound message, invoke calls inbound web services):
  https://docs.oracle.com/en/cloud/paas/application-integration/utilities-adapters/oracle-utilities-adapter-capabilities.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
