# Requirements — C2M Coherence, JMS & IWS Configuration

These are the **solution-specific** prerequisites for configuring the C2M runtime layer. They are in
addition to the **Global Requirements** for every Oracle solution (licensed C2M + WebLogic
entitlement, certified platform stack, Dev/Test/Prod topology, WLST/shell/SQL tooling, change control
+ backup + non-prod pilot, and collaborating teams) — verify those first.

Each requirement below states **Description**, **Why it's required**, **How to verify**, and **How to
implement if missing**.

---

## 1. A running WebLogic domain hosting the C2M/OUAF managed servers

- **Description:** An installed and startable OUAF/C2M WebLogic domain with the Administration Server
  and at least one managed server hosting the C2M application.
- **Why required:** Coherence membership, JMS servers, and the IWS EAR are all domain-scoped
  WebLogic objects — there is nothing to configure without a domain.
- **How to verify:** Start the Admin Server and connect with WLST (`connect()`); confirm the managed
  server(s) reach **RUNNING** and the C2M application is targeted to them.
- **How to implement if missing:** Complete the WebLogic/OUAF domain install and configuration
  (the *WebLogic 14c C2M Install & Configure* solution) before starting here.

## 2. Managed-server / cluster topology decision (single vs. clustered)

- **Description:** A decided topology — a single managed server, or a WebLogic **cluster** of managed
  servers — and, for clustered deployments, the intended member list.
- **Why required:** Coherence cluster association, JMS targeting (single server vs. cluster via a
  subdeployment), and IWS deployment targets all depend on whether you are clustered.
- **How to verify:** In the Administration Console under *Environment → Clusters* / *Servers*, confirm
  the intended servers/cluster exist and their membership.
- **How to implement if missing:** Define the cluster and assign managed servers before configuring
  Coherence/JMS targeting.

## 3. Network & ports for Coherence discovery

- **Description:** Network reachability between managed servers on the Coherence cluster listen
  address/port (unicast **Well Known Addresses (WKA)** are strongly preferred; the default Coherence
  cluster listen port is **7574** — *verify for your version/topology*), with any host firewalls open
  for that port and, if multicast is used, multicast enabled on the segment.
- **Why required:** Coherence members discover and join the cluster over this transport; blocked ports
  or disabled multicast are the most common reason a cluster "won't form".
- **How to verify:** From each host, confirm the listen port is open to the other members (for
  example a TCP reachability check to the WKA hosts:port); confirm the chosen transport (unicast WKA
  vs. multicast) is permitted on the segment.
- **How to implement if missing:** Open the port between members and standardise on **unicast WKA**
  (deterministic, firewall-friendly) rather than multicast for most enterprise networks.

## 4. Persistent store location for JMS (file or JDBC)

- **Description:** A decided persistence backing for the JMS server — a **file store** on a path
  reachable by the target server(s), or a **JDBC store** in the database — so persistent messages
  survive restarts.
- **Why required:** A JMS server needs a persistent store for persistent/durable messaging; a missing
  or unreachable store prevents the JMS server from starting or loses messages.
- **How to verify:** Confirm the file-store directory exists and is writable by the WebLogic OS
  account, or the JDBC store's data source and schema exist.
- **How to implement if missing:** Create the file-store directory (owned by the product OS account)
  or the JDBC store / data source before creating the JMS server.

## 5. C2M message senders / JMS integration requirements defined

- **Description:** The list of JMS destinations C2M actually needs — queues/topics for outbound
  message senders, real-time hand-offs, and any JMS consumers — with their intended **JNDI names**.
- **Why required:** Creating arbitrary queues is not the goal; the destinations must match what the
  C2M **Message Sender** / integration configuration references, or messages will not flow.
- **How to verify:** In C2M, review the **Message Sender** configuration and any JMS-based
  integration to list the JNDI names expected; reconcile against the JMS module you will create.
- **How to implement if missing:** Agree the destination list and JNDI naming with the integration
  team before creating JMS resources.

## 6. IWS enabled and the web-services EAR deployable

- **Description:** The OUAF environment configured for **Inbound Web Services** (the web-services
  functionality enabled via `configureEnv`), with the ability to run `initialSetup` and deploy the
  **`spl-web-services`** EAR, plus the WebLogic user-config/key files
  (`$SPLEBASE/etc/.wlsuserconfig`, `.wlsuserkey`) for headless deployment.
- **Why required:** IWS is deployed as a Java EE web application through the OUAF `iwsdeploy` utility;
  it will not deploy unless the environment is configured for web services and the Admin Server is up.
- **How to verify:** Confirm the IWS parameters are set in `configureEnv` (the *IWS Deployment
  Target* and *Web Admin Server Host*), that `$SPLEBASE/etc/.wlsuserconfig` / `.wlsuserkey` exist,
  and that `iwsdeploy` is present under `$SPLEBASE/bin`.
- **How to implement if missing:** Run `configureEnv` to enable web services and set the IWS
  parameters, create the WebLogic user-config/key files with `storeUserConfig`, then `initialSetup`,
  before deploying. See MOS **Doc ID 1644914.1** for XAI → IWS migration where legacy XAI services
  are still in use.

## 7. Inventory of inbound services to enable

- **Description:** The specific OUAF **Inbound Web Service** metadata records that must be *active/
  enabled* for the integrations in scope (the annotated services that IWS exposes).
- **Why required:** Deploying the EAR makes the container available, but each inbound service must be
  defined and enabled to actually respond; enabling everything expands the attack/support surface
  needlessly.
- **How to verify:** In C2M, list the **Inbound Web Service** records and their status; confirm each
  in-scope service exists and note its endpoint/operation.
- **How to implement if missing:** Define/enable the required Inbound Web Service records (and
  redeploy so the EAR reflects them) — enabling only what integrations need.

## 8. Backups and a rollback point before changes

- **Description:** A captured baseline — domain `config.xml` (and JMS/Coherence config), the
  `$SPLEBASE` product/config, and any JMS persistent-store state — plus a change window for
  production.
- **Why required:** Coherence, JMS, and deployment changes are domain-level and high-impact; a clean
  restore path is the rollback.
- **How to verify:** Confirm a current backup of the domain config and product home, and that you can
  restore them.
- **How to implement if missing:** Take the backups and secure the change approval before proceeding
  (per the global change-control requirement).

---

*Gate to begin implementation:* all eight items above pass on the **pilot (non-production)**
environment, the object names are agreed (Overview naming convention), and a rollback is in hand.
