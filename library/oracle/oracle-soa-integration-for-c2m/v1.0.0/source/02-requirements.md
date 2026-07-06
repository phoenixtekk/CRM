# Requirements — SOA Integration for C2M

These are the **solution-specific** prerequisites for defining and deploying the C2M SOA/web-service
integration surface. They are in addition to the **Global Requirements** for every Oracle solution
(licensed C2M + WebLogic entitlement, certified platform stack, Dev/Test/Prod topology, WLST/shell/SQL
tooling, change control + backup + non-prod pilot, and collaborating teams) — verify those first.

Each requirement states **Description**, **Why it's required**, **How to verify**, and **How to
implement if missing**.

---

## 1. A running C2M/OUAF WebLogic domain with IWS deployable

- **Description:** An installed, startable OUAF/C2M WebLogic domain with the Administration Server and at
  least one managed server hosting the C2M application, and the environment configured so the
  **`spl-web-services`** (IWS) EAR can be deployed with the OUAF `iwsdeploy` utility.
- **Why required:** IWS is the inbound integration surface; SOA composites call C2M through it. There is
  nothing to integrate into if the domain and IWS container are not in place.
- **How to verify:** Connect with WLST (`connect()`); confirm managed server(s) reach **RUNNING** and
  the C2M application is targeted. Confirm web services are enabled in `configureEnv` and
  `$SPLEBASE/bin/iwsdeploy.sh` exists.
- **How to implement if missing:** Complete the *WebLogic 14c C2M Install & Configure* and enable IWS
  (`configureEnv` → `initialSetup`) before starting here. XAI is retired — use IWS.

## 2. Oracle SOA middleware tier available (SOA Suite / Service Bus) — where SOA is used

- **Description:** Where the integration design uses SOA/OSB, a reachable **Oracle SOA Suite / Oracle
  Service Bus** domain (Enterprise Manager / OSB console accessible) certified alongside the C2M release,
  with deployment access to it.
- **Why required:** Composites, proxy/business services, and the **OUAF Outbound Message** OSB transport
  live in the middleware tier; you cannot deploy or observe them without it. (Purely IWS/direct-HTTP
  integrations may not need SOA — scope this per interface.)
- **How to verify:** Log in to the SOA/OSB Enterprise Manager / Service Bus console; confirm you can list
  and deploy composites/projects; confirm the **OUAF Outbound Message** transport is installed on OSB if
  the SOA processing method will be used.
- **How to implement if missing:** Stand up / obtain access to the SOA Suite / Service Bus environment
  and install the OUAF Outbound Message transport, or design the interface to use IWS/real-time HTTP
  instead (a valid lower-lock-in choice for many flows).

## 3. Integration inventory & direction defined (what talks to what)

- **Description:** A written inventory of the integrations in scope — for each, the **direction**
  (inbound to C2M / outbound from C2M / both), the **external system**, the **payload**, and the
  required **timing** (real-time synchronous vs. asynchronous/near-real-time).
- **Why required:** The mechanism (IWS vs. outbound message vs. SOA composite vs. JMS) follows from
  direction and timing. Building endpoints without this inventory produces the snowflake interfaces this
  solution exists to prevent.
- **How to verify:** Confirm an integration register exists listing each interface, its direction, its
  external system, and its timing requirement.
- **How to implement if missing:** Work with the integration and business teams to produce the register
  before designing endpoints; the `OSOAC2M-ScopeHelper` script consumes this to fix the target set.

## 4. Inbound Web Service records defined and enabled (for inbound flows)

- **Description:** The specific OUAF **Inbound Web Service** metadata records for the in-scope inbound
  integrations (SOAP and/or REST), each **active/enabled**, backed by the intended business
  service/service script/BO, e.g. the reference **`C2M-IWS-CustomerSync`**.
- **Why required:** Deploying `spl-web-services` makes the container available, but each inbound service
  must be defined and enabled to respond; enabling everything needlessly expands the attack/support
  surface.
- **How to verify:** In C2M, list the **Inbound Web Service** records and their status; retrieve the
  WSDL/endpoint for each in-scope service and confirm it loads.
- **How to implement if missing:** Define/enable only the required Inbound Web Service records and
  redeploy `spl-web-services` so the EAR reflects them. Migrate any legacy XAI inbound service to IWS
  (MOS **Doc ID 1644914.1**).

## 5. Outbound Message configuration defined (for outbound flows)

- **Description:** For each outbound integration, the OUAF **External System** (reference
  **`C2M-SOA-EXT`**), **Outbound Message Type** (reference **`C2M-OMT-SOA`**), and the **Message Sender**
  with the correct **processing method** — **SOA** for OSB-polled asynchronous flows, a **real-time
  HTTP/SOAP** sender (**`C2M-RTHTTP-SNDR`**) for synchronous calls, or a **JMS** sender
  (**`C2M-JMS-SNDR`**) for asynchronous queue hand-off.
- **Why required:** C2M routes outbound messages by external system + outbound message type; the
  processing method selects the transport. A mismatch means messages stage but never dispatch, or
  dispatch to the wrong place.
- **How to verify:** In C2M, review the **External System**, **Outbound Message Type**, and **Message
  Sender** definitions; confirm the processing method matches the intended transport and that the sender
  points at the right endpoint/queue.
- **How to implement if missing:** Define the External System, Outbound Message Type (processing method
  SOA/real-time/JMS as designed), and Message Sender before wiring the middleware.

## 6. Endpoints, credentials & connectivity for each integration

- **Description:** For every interface, the **endpoint URL** (C2M IWS endpoints for inbound; external
  system URLs/queues for outbound), the **credentials** (service accounts / keystores), and confirmed
  **network reachability** (firewall/proxy) between C2M, the SOA/OSB tier, and the external systems.
- **Why required:** Integrations fail most often on connectivity and credentials, not logic. These must
  be known and reachable before deployment, and secrets must be handled securely (never in source).
- **How to verify:** From the SOA/OSB host, confirm the C2M IWS endpoint is reachable and authenticates;
  from C2M, confirm the outbound endpoint/queue is reachable; confirm certificates are trusted
  (OUAF trust store / `initialSetup -i`).
- **How to implement if missing:** Open the connectivity, provision the service accounts and keystores,
  and store credentials in the environment/secret store — not in scripts or committed files.

## 7. Consistent authN, error-handling & observability standard agreed

- **Description:** A single agreed standard applied to **every** integration: the **authentication**
  model (HTTP Basic over TLS, WS-Security/WS-Policy, OAuth where supported — *verify for your version*),
  the **error-handling** pattern (retry/redelivery limits, error queues, C2M outbound-message error
  status handling, fault policies in SOA), and the **observability** approach (SOA/OSB instance tracking,
  C2M outbound-message status, IWS request logging, and the monitoring stack the environment uses).
- **Why required:** Consistency is the whole point — one standard makes every integration supportable and
  observable instead of each one behaving differently. Ad-hoc per-interface choices are unsupportable.
- **How to verify:** Confirm the standard is documented and that a reference integration already conforms
  to it (authN enforced, errors captured, flow observable end to end).
- **How to implement if missing:** Agree and document the standard (authN + error-handling +
  observability) **before** building interfaces, then apply it to every one; the Best Practices guide
  gives the recommended defaults.

## 8. Backups and a rollback point before changes

- **Description:** A captured baseline before changes — domain `config.xml`, the `$SPLEBASE`
  product/config (IWS, external system, outbound message, message sender metadata), and the SOA/OSB
  project/composite exports (SAR/JAR/configjar) — plus a change window for production.
- **Why required:** IWS deployment, C2M integration metadata, and SOA/OSB deployments are all
  production-impacting; a clean restore path is the rollback.
- **How to verify:** Confirm current backups of the domain config, product home, and SOA/OSB project
  exports, and that you can restore/redeploy them.
- **How to implement if missing:** Take the backups (export the SOA/OSB projects) and secure the change
  approval before proceeding (per the global change-control requirement).

---

*Gate to begin implementation:* all eight items above pass on the **pilot (non-production)**
environment, the object names are agreed (Overview naming convention), the authN/error/observability
standard is documented, and a rollback is in hand.
