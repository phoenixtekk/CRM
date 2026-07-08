# 2. Requirements Guide — Databricks Data Governance (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance/governance licensing, least-privilege Purview roles, the PowerShell +
Graph/REST toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot
scope with change control) — those are referenced here, not repeated.

> **Read this first.** Governing Databricks is a **Microsoft Purview Data Map / Unified Catalog**
> capability (the data-governance side), **not** a Microsoft 365 E5 compliance feature. Its
> prerequisites are a **Purview (Data Governance) account**, **data-plane roles**, a **Databricks
> workspace with a reachable credential**, and an **integration runtime with network line-of-sight** —
> different from the compliance-side prerequisites. Everything below is **cited as of authoring and
> flagged "verify in your tenant"**; the Databricks connector(s), provisioning, pricing, roles, portal
> paths, and REST `api-version` values in this area are actively evolving. Nothing is invented.

## 2.1 A Microsoft Purview (Data Governance) account with the Data Map / Unified Catalog available
**Description:** A provisioned **Microsoft Purview account** (Data Map / Unified Catalog) under an Azure
subscription, reachable at its data-plane endpoint `https://<account>.purview.azure.com`.
**Why:** The Databricks workspace is registered, scanned, and cataloged **inside** this account; without
it there is nothing to register the lakehouse into (extends Global Requirement 1 to the governance side).
**Verify:** In the **Purview portal** confirm the account/catalog loads and the **Data Map** is present;
`DGDBX-Set-Scope.ps1` confirms the account endpoint is reachable and a data-plane token is obtainable.
**Implement:** Provision a Purview (Data Governance) account (Azure portal / `Az.Purview`) under change
control. **Verify the current provisioning model and pricing** — Data Governance is Azure-metered /
consumption-based (pay-as-you-go) — against Microsoft's documentation before creating it.

## 2.2 Data-plane governance roles (least-privilege) on the collection in scope
**Description:** The **least-privilege Purview data-plane roles**, assigned **at the collection scope**
where Databricks will be registered: **Collection admin** (create/manage the collection), **Data source
admin** (register the source, manage scan credentials, run scans), and **Data curator** (read the
catalog, edit assets/classifications, read lineage). Reserve root-collection admin for the few setup
actions (Global Requirement 2).
**Why:** Purview Data Map uses **collection-scoped** data-plane roles distinct from the M365 compliance
role groups; registering the workspace, running the scan, and editing catalog assets each require the
matching role at the right collection.
**Verify:** Purview portal → **Data Map → Collections → `Lakehouse – DGDBX – Pilot` → Role assignments**
(verify path) shows your account in the required roles; `DGDBX-Set-Scope.ps1` reports the collections
your token can enumerate.
**Implement:** Assign the least-privilege data-plane roles at the pilot collection first, root-collection
admin only where genuinely required, under change control.

## 2.3 PowerShell + Azure REST toolchain (Az + data-plane token)
**Description:** A workstation with the **Az PowerShell** modules (`Az.Accounts`, and `Az.Purview` for
control-plane account operations), a modern-auth/MFA admin, and the ability to acquire a **Purview
data-plane token** via `Get-AzAccessToken -ResourceUrl 'https://purview.azure.net'` for
`Invoke-RestMethod` calls to the scanning/catalog APIs (Global Requirement 3).
**Why:** The provided scripts read and (with `-Commit`) register/scan Databricks through the documented
Purview data-plane REST APIs, authenticated with an Entra ID token — no credentials in code.
**Verify:** `Get-Module -ListAvailable Az.Accounts, Az.Purview`; `Connect-AzAccount` succeeds and
`Get-AzAccessToken -ResourceUrl 'https://purview.azure.net'` returns a token. `DGDBX-Set-Scope.ps1`
confirms connectivity.
**Implement:** `Install-Module Az.Accounts, Az.Purview -Scope CurrentUser`; sign in with a modern-auth
admin; **verify the current data-plane resource URL / `api-version` values** in Microsoft's docs.

## 2.4 An Azure Databricks workspace and the correct connector (Unity Catalog vs. Hive metastore)
**Description:** The **Azure Databricks workspace** to be governed, and confirmation of **which
connector applies** — **Azure Databricks Unity Catalog** (workspace is Unity Catalog-enabled; the
lineage-rich path this solution is written for) or **Azure Databricks (Hive metastore)** (legacy). You
must know the workspace URL and, for Unity Catalog, the **metastore** it is attached to.
**Why:** The registration shape, what gets enumerated (Unity Catalog `catalogs → schemas → tables` vs.
Hive databases/tables), and whether lineage flows depend on the connector. Choosing the wrong one
produces an empty or partial scan.
**Verify:** In the Databricks admin console confirm whether Unity Catalog is enabled and the metastore;
**verify the current connector name and availability for your tenant** in Microsoft's documentation
(the Data Governance connector set is evolving).
**Implement:** Confirm the workspace's catalog architecture with the Databricks admins before
registering; select the matching Purview connector.

## 2.5 A scan credential stored in Key Vault and referenced by name (no secret in code)
**Description:** The **credential** the scan uses to authenticate to Databricks — a **service principal**
or **personal access token (PAT)** per the connector's requirement — stored as a secret in an **Azure
Key Vault linked to the Purview account** and referenced in Purview **by name**. The credential's
Databricks-side identity needs read/metadata access to the catalogs/schemas in scope.
**Why:** Scanning reaches into the live workspace, so it needs a credential and least-privilege access;
Microsoft's documented pattern keeps the secret in Key Vault and never in a script or document —
**no secret is ever placed in code here**.
**Verify:** The Key Vault connection exists in Purview (**Management → Credentials / Key Vault
connections**, verify path) and the credential resolves; the Databricks identity can read the in-scope
catalogs. `DGDBX-Set-Scope.ps1` confirms a named Key Vault connection is present (it never reads the
secret value).
**Implement:** Create the Key Vault connection and store the Databricks secret; grant the scan identity
least-privilege metadata read in Databricks (Unity Catalog grants / workspace ACLs) before scanning.

## 2.6 An integration runtime with network line-of-sight to the workspace
**Description:** The **integration runtime (IR)** the scan runs on: the **Azure (managed) IR** for a
**reachable/public** workspace, or a **self-hosted integration runtime (SHIR)** on a host with network
line-of-sight for a **VNet-injected / Private Link** workspace.
**Why:** The scan connects from the IR to the workspace; a private workspace is unreachable from the
managed IR, so the scan fails or times out without a SHIR that can route to it.
**Verify:** Confirm the workspace's network posture (public vs. private) with the Databricks/network
admins; if private, a SHIR (`SHIR – DGDBX`) is installed and shows **running**. `DGDBX-Set-Scope.ps1`
reports whether a self-hosted IR is registered when one is required.
**Implement:** Install and register a SHIR on an in-network host for a private workspace; otherwise the
Azure managed IR is used. **Verify current IR requirements for the connector** in Microsoft's docs.

## 2.7 Data-governance stakeholders, classification intent, and the catalog target
**Description:** Engagement with the **data-governance, records, privacy, and business-data owners**
(Global Requirement 5) who define **which catalogs/schemas are in scope**, the **classification intent**
(which built-in/custom classifications matter for this lakehouse), and the **catalog target** (which
assets become curated **data products** with owners and glossary terms).
**Why:** Purview provides the technical map; **which table is "confidential", what the retention/records
obligation is, and who may access what are business/regulatory determinations** the owners make — not
technical defaults.
**Verify:** Named owners, an in-scope catalog/schema list, and a classification/catalog intent are
recorded.
**Implement:** Identify the owners and capture scope + intent before scanning; you deliver the governed,
classified, cataloged lakehouse and the evidence — they own the determinations.

## 2.8 A bounded pilot scope and change control
**Description:** A **bounded pilot scan scope** (`Lakehouse Scan – DGDBX – Stage1` limited to **one
catalog/schema**) and a **change-control** process, per Global Requirement 6.
**Why:** A first full-workspace scan against a large lakehouse is high-impact (load, cost, and blast
radius); it is proven on one catalog/schema first. The model is **Assess → Design → Configure → Pilot
(bounded scan) → Validate → Expand**.
**Verify:** The pilot scope (one catalog/schema) is named and a change window/approval path exists.
**Implement:** Define the bounded pilot scope and agree change control before scanning the whole
metastore or enabling scheduled scans.

---
## Checklist
- [ ] Microsoft Purview (Data Governance) account provisioned; Data Map / Unified Catalog available (pricing/model verified)
- [ ] Data-plane roles (Collection admin / Data source admin / Data curator) assigned least-privilege at `Lakehouse – DGDBX – Pilot`
- [ ] `Az.Accounts` + `Az.Purview` installed; `Connect-AzAccount` and `Get-AzAccessToken` (purview.azure.net) succeed
- [ ] Databricks workspace identified; connector confirmed (Unity Catalog vs. Hive metastore)
- [ ] Scan credential (service principal / PAT) stored in **Key Vault**, referenced by name; Databricks-side read access granted
- [ ] Integration runtime with line-of-sight (Azure managed for public; `SHIR – DGDBX` for private)
- [ ] Governance/business owners named; in-scope catalogs/schemas, classification intent, and catalog target agreed
- [ ] `Lakehouse Scan – DGDBX – Stage1` bounded to one catalog/schema; change control agreed
