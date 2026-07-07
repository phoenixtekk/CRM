# Requirements

These are the **solution-specific** prerequisites for deploying and running **Google Workspace
Migrate** at scale. They build on the shared **Global Requirements — Google Workspace & Gemini
Solutions** (`global-requirements-google.md`): a provisioned **Google Workspace / Cloud Identity
tenant with super-admin** (GR-1), administrative access to the source **Microsoft 365 / Entra**
environment (GR-2), **DNS control** for routed domains (GR-3), an **identity source of truth** and
provisioning model (GR-4), a **pilot OU/group and change control** (GR-5), and engagement with
**security/compliance stakeholders** (GR-6). Do not re-verify those here; confirm them, then verify
the items below.

> Where a requirement depends on Google Workspace Migrate's current release (supported node OS,
> supported source/target scope, sizing guidance), **verify against Google's Google Workspace
> Migrate documentation for your version** — those specifics change and are not restated here.

---

## R1. Node platform infrastructure (Windows Server hosts + database)

- **Description:** Windows Server hosts to run the **platform node** (management service + web
  console + platform database) and one or more **worker nodes**, each meeting Google Workspace
  Migrate's current CPU/RAM/disk and supported-OS requirements, inside the organization's network.
- **Why required:** Google Workspace Migrate is self-hosted; scan/transfer throughput is a direct
  function of node count and node sizing. Under-provisioning is the most common cause of missed
  migration timelines.
- **How to verify:** Confirm the provisioned hosts meet Google's **current** minimum spec (verify
  for your version) and that the platform node's database volume has headroom for project state and
  scan results across all planned waves. Run `node-sizing-assessment.py` (this solution) against the
  source inventory to get a recommended node count for the target throughput.
- **How to implement if missing:** Provision the hosts (physical or IaaS), install the supported OS,
  and reserve a dedicated encrypted volume for the platform database. Size to the recommendation
  from `node-sizing-assessment.py`, rounding up for delta passes and headroom.

## R2. Microsoft 365 source app registration + scopes (`Connection – Microsoft 365 – Source`)

- **Description:** An **Entra ID app registration** with the Microsoft Graph / SharePoint
  application permissions Google Workspace Migrate requires to read Exchange Online, OneDrive, and
  SharePoint at scale, plus admin consent granted tenant-wide.
- **Why required:** The Microsoft 365 connection authenticates as this app to scan and read source
  content; missing or unconsented scopes are the top cause of scan/transfer permission failures.
- **How to verify:** In the Entra admin center, confirm the app registration exists, the required
  application permissions are present, and **admin consent** is granted (green status). Confirm the
  client secret/certificate is current and stored in a secret manager, not in code.
- **How to implement if missing:** Register the app, add the permissions Google Workspace Migrate's
  documentation specifies **for your version**, grant admin consent, and record the client ID +
  secret reference for the connection. Use least privilege the tool supports.

## R3. Google target Cloud project + delegated service account (`Connection – Google Workspace – Target`)

- **Description:** A **Google Cloud project** with the required Workspace APIs enabled (Admin SDK
  Directory, Drive, Gmail, Groups) and a **service account with domain-wide delegation** authorized
  for the scopes Migrate uses to write into Drive/Shared Drives and Gmail.
- **Why required:** The Google connection impersonates target users via the delegated service
  account to create content and set ownership/permissions on the target side.
- **How to verify:** In the Google Admin console under **Security → Access and data control → API
  controls → Domain-wide delegation**, confirm the service account's client ID is present with the
  exact OAuth scopes required. Confirm the APIs are enabled in the Cloud project.
- **How to implement if missing:** Create the Cloud project, enable the APIs, create the service
  account, and authorize its client ID for the required scopes in Domain-wide delegation. Store the
  key in a secret manager; **never commit the key**.

## R4. Network path, bandwidth, and firewall egress

- **Description:** Reliable, sized network egress from the node platform to **both** Microsoft 365
  and Google endpoints, with any required firewall/proxy allow-listing, and enough sustained
  bandwidth to move the assessed data volume within the migration window.
- **Why required:** Every byte transits the nodes; bandwidth and firewall egress cap real
  throughput regardless of node count.
- **How to verify:** Confirm the platform/worker nodes can reach the Microsoft and Google service
  endpoints (verify the current endpoint/URL list for your version) through the corporate
  proxy/firewall. Compare available sustained bandwidth against the assessed volume ÷ window.
- **How to implement if missing:** Allow-list the required egress, provision bandwidth (or place
  nodes where bandwidth is best), and schedule bulk pre-stage passes for off-peak windows.

## R5. Source inventory / discovery baseline

- **Description:** A **quantified inventory** of the source: user/mailbox counts and sizes,
  OneDrive/SharePoint site and library counts, item counts, largest objects, and sharing/permission
  complexity — the baseline every wave is validated against.
- **Why required:** Node sizing, wave scoping, throttling budgets, and validation gates all key off
  real numbers. Without a baseline you cannot prove parity after a wave.
- **How to verify:** Run `node-sizing-assessment.py` (reads Microsoft Graph, read-only) to produce
  the inventory and volume/throughput estimate; sanity-check against the Microsoft admin center
  reports.
- **How to implement if missing:** Grant the assessment app read scopes and run the discovery before
  designing waves; store the baseline as the validation reference.

## R6. Mapping and identity-bridge source data (`Mapping – … `, `Bridge – Identity – Corp`)

- **Description:** Authoritative **source→target mapping data** (which source user/site maps to which
  target user/Shared Drive) and the **identity bridge** data that resolves source identities to
  target identities so ownership/sharing survive.
- **Why required:** Mappings and the bridge are what Google Workspace Migrate consumes to route
  content and preserve permissions; wrong or incomplete mappings misplace data or drop sharing.
- **How to verify:** Run `connection-mapping-generator.py --dry-run` (this solution) to produce and
  validate the mapping CSV + bridge from the directory data; confirm every in-scope source object
  resolves to exactly one target.
- **How to implement if missing:** Reconcile the directories (see GR-4 source of truth), then
  generate the mapping/bridge artifacts and review before import.

## R7. Migration service accounts and least-privilege operations

- **Description:** Dedicated, named service identities for the migration platform (the M365 app, the
  Google delegated service account) with least privilege, plus a defined **change window** for
  cutover waves (mail routing changes are high-impact — GR-3/GR-5).
- **Why required:** Migration runs with powerful cross-tenant access; scoping it to dedicated,
  auditable identities and gating cutover under change control limits blast radius.
- **How to verify:** Confirm the identities are dedicated (not a person's admin account), documented,
  and revocable; confirm a change/approval path exists for cutover.
- **How to implement if missing:** Create the dedicated identities, document them, and agree the
  cutover change window and rollback with the owners before scheduling production waves.
