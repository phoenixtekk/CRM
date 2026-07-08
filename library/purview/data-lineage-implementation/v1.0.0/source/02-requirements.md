# 2. Requirements Guide — Data Lineage Implementation (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance/governance licensing, least-privilege Purview roles, the PowerShell +
Graph/REST toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot
scope with change control) — those are referenced here, not repeated.

> **Read this first.** Data lineage is a **Microsoft Purview Data Map / Unified Catalog** capability
> (the data-governance side), **not** a Microsoft 365 E5 compliance feature. Its prerequisites are a
> **Purview (Data Governance) account**, **data-plane roles**, and **connected + scanned data sources**
> — different from the compliance-side prerequisites. Everything below is **cited as of authoring and
> flagged "verify in your tenant"**; provisioning, pricing, roles, portal paths, and REST `api-version`
> values in this area are actively evolving. Nothing is invented.

## 2.1 A Microsoft Purview (Data Governance) account with the Data Map / Unified Catalog available
**Description:** A provisioned **Microsoft Purview account** (Data Map / Unified Catalog) under an Azure
subscription, reachable at its data-plane endpoint `https://<account>.purview.azure.com`.
**Why:** Lineage is a Data Map capability — assets, scans, and the lineage graph live in this account.
Without it there is nothing to draw lineage in (extends Global Requirement 1 to the governance side).
**Verify:** In the **Purview portal** confirm the account/catalog loads and the **Data Map** is present;
`DGLINE-ScopeHealth.ps1` confirms the account endpoint is reachable and a data-plane token is obtainable.
**Implement:** Provision a Purview (Data Governance) account (Azure portal / `Az.Purview`) under change
control. **Verify the current provisioning model and pricing** (Data Map is Azure-metered /
consumption-based — capacity units / pay-as-you-go) against Microsoft's documentation before creating it.

## 2.2 Data-plane governance roles (least-privilege) on the collections in scope
**Description:** The **least-privilege Purview data-plane roles** the work needs, assigned **at the
collection scope**: **Collection admin** (to register sources / manage collections), **Data source
admin** (to register/scan sources and manage credentials), and **Data curator** (to read the catalog,
edit assets, and read/edit lineage). Reserve broad/root-collection admin for the few setup actions
(Global Requirement 2).
**Why:** Purview Data Map uses **collection-scoped** roles distinct from the M365 compliance role
groups; registering sources, running scans, and editing lineage each require the matching data-plane
role at the right collection.
**Verify:** Purview portal → **Data Map → Collections → <collection> → Role assignments** (verify path)
shows your account in the required roles; `DGLINE-ScopeHealth.ps1` reports the collections your token can
enumerate.
**Implement:** Assign the least-privilege data-plane roles at the pilot collection first, root-collection
admin only where genuinely required, under change control.

## 2.3 PowerShell + Azure REST toolchain (Az + data-plane token)
**Description:** A workstation with the **Az PowerShell** modules (`Az.Accounts`, and `Az.Purview` for
control-plane account operations), a modern-auth/MFA admin, and the ability to acquire a **Purview
data-plane token** via `Get-AzAccessToken -ResourceUrl 'https://purview.azure.net'` for
`Invoke-RestMethod` calls to the catalog/scanning APIs (Global Requirement 3).
**Why:** The provided scripts read and (with `-Commit`) configure lineage through the documented
Purview data-plane REST APIs, authenticated with an Azure AD token — no credentials in code.
**Verify:** `Get-Module -ListAvailable Az.Accounts, Az.Purview`; `Connect-AzAccount` succeeds and
`Get-AzAccessToken -ResourceUrl 'https://purview.azure.net'` returns a token. `DGLINE-ScopeHealth.ps1`
confirms connectivity.
**Implement:** `Install-Module Az.Accounts, Az.Purview -Scope CurrentUser`; sign in with a modern-auth
admin; **verify the current data-plane resource URL / `api-version` values** in Microsoft's docs.

## 2.4 In-scope data sources registered and scanned into the Data Map
**Description:** The **data sources** that make up each in-scope source→report path (e.g. Azure Data
Lake / Blob, Azure SQL / Synapse SQL, Power BI) **registered** to a collection and **scanned**, so the
assets exist as catalog entities to be lineage endpoints (Global Requirement 4).
**Why:** A lineage edge only renders when **both** ends are known to the Data Map. Un-scanned sources
produce half-drawn or missing lineage.
**Verify:** Purview portal → **Data Map → Data sources** shows the sources registered with **completed**
scans; `DGLINE-Discovery.ps1` lists registered sources and last-scan status. Assets are searchable in
the catalog.
**Implement:** Register the sources to the in-scope collection and run (or schedule) scans; confirm the
assets appear before expecting lineage between them.

## 2.5 Lineage-producing connections for the automatic sources
**Description:** The **connections** that make ADF / Synapse / Data Share / Power BI report lineage to
Purview — the ADF/Synapse workspace connected to this Purview account, and the Power BI tenant/workspaces
registered and scanned.
**Why:** Automatic lineage is produced **only** when the integration system is connected to Purview and
runs against registered assets; the connection is the switch that turns lineage on.
**Verify:** Purview portal → **Data Map → Integration runtimes / connections** (verify path) shows the
ADF/Synapse connection; a pipeline run subsequently shows a lineage edge on the affected asset.
`DGLINE-Discovery.ps1` flags which in-scope sources are lineage-capable and connected.
**Implement:** Connect ADF/Synapse to Purview and register/scan Power BI, per the capture-model table in
the Overview; verify the current connection path in your tenant (classic vs. unified experience differ).

## 2.6 A custom-lineage plan for sources that don't self-report
**Description:** For pipelines/systems **not** covered by an automatic connector (custom ETL,
Spark/Hive without a supported hook, home-grown movers), a plan to push **custom lineage** via the
**Atlas catalog REST API** (`Process` entities with `inputs`/`outputs` referencing scanned assets by
qualified name).
**Why:** Coverage of unsupported systems is achieved with custom lineage — it does not appear on its own;
this is deliberate work, scoped in the Design step.
**Verify:** The list of non-automatic paths is recorded in `Data Lineage Coverage Map – DGLINE – Design`;
`DGLINE-Configure.ps1 -WhatIf` shows the `Process` entity it would push for a pilot path.
**Implement:** Identify the qualified names of the source/sink assets and author the custom-lineage
`Process` payloads; push them (pilot first) with `DGLINE-Configure.ps1`.

## 2.7 Data-governance stakeholders and the coverage target
**Description:** Engagement with the **data-governance, records, privacy, and business-data owners**
(Global Requirement 5) who define **which source→report paths must be traceable** (the coverage target)
and **which source is authoritative** for a data element.
**Why:** The lineage program aligns to governance requirements, not technical convenience; what "fully
traceable" means, and which regulatory/records obligation drives it, is the stakeholders' determination.
**Verify:** Named owners and an agreed coverage target (the in-scope paths) are recorded.
**Implement:** Identify the owners and capture the coverage target before configuring; you deliver the
capability and the measured coverage, they own the target and the determination.

## 2.8 A pilot scope and change control
**Description:** A **pilot scope** (`Data Lineage Pilot Scope – DGLINE – Stage1`) — one collection or a
couple of representative sources / one source→report path — and a **change-control** process, per Global
Requirement 6.
**Why:** Connecting production integration sources, running scans, and pushing lineage are high-impact;
they are proven on the pilot scope before the estate. The model is **Assess → Design → Configure →
Pilot → Validate → Expand**.
**Verify:** The pilot scope is named and a change window/approval path exists.
**Implement:** Define the pilot scope and agree change control before connecting production sources or
pushing lineage tenant-wide.

---
## Checklist
- [ ] Microsoft Purview (Data Governance) account provisioned; Data Map / Unified Catalog available (pricing/model verified)
- [ ] Data-plane roles (Collection admin / Data source admin / Data curator) assigned least-privilege at the in-scope collections
- [ ] `Az.Accounts` + `Az.Purview` installed; `Connect-AzAccount` and `Get-AzAccessToken` (purview.azure.net) succeed
- [ ] In-scope sources registered **and scanned** into the Data Map (assets exist as lineage endpoints)
- [ ] Lineage-producing connections in place for automatic sources (ADF / Synapse / Data Share / Power BI)
- [ ] Custom-lineage plan recorded for non-automatic paths (Atlas `Process` entities)
- [ ] Data-governance/business owners named; coverage target (in-scope paths) agreed
- [ ] `Data Lineage Pilot Scope – DGLINE – Stage1` defined; change control agreed
