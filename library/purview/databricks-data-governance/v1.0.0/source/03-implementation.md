# 3. Implementation Guide — Databricks Data Governance (Unity Catalog / lakehouse): Microsoft Purview

Follow these steps in order. This guide assesses Databricks readiness, designs the collection and role
model, establishes the scan credential and network path safely, registers and **pilot-scans** a bounded
Databricks scope (one catalog/schema), reviews classifications and lineage, then expands across the
metastore. Artifact names are fixed — create them with the exact names shown and reuse them everywhere.
**Every scan is piloted on a bounded scope before the whole workspace is scanned.**

> Model: prove the Databricks connector, the credential/network path, classification, and lineage on a
> pilot scope, then expand. The repeatable way: **Assess → Design → Configure → Pilot (bounded scan) →
> Validate → Expand.** Verify current portal paths, the exact connector name (Azure Databricks Unity
> Catalog vs. Hive metastore), connector prerequisites, lineage support, and the data-plane
> `api-version` values for your tenant as you go — the Data Governance experience is evolving.

## Step 1 — Assess current state (read-only)
1. Run `DGDBX-Discovery.ps1` to capture readiness signals: the Purview account endpoint is reachable,
   which **collections** exist and their **role coverage** (especially Data source admin, needed to
   register/scan), which **integration runtimes** are registered, and how many **Azure Databricks /
   lakehouse** sources are already registered. No changes are made.
2. In the Purview portal (**Data Map → Sources → Register**) confirm the **Azure Databricks** source
   type is offered and note **which connector applies** — **Unity Catalog** (this solution's path) or
   **Hive metastore** — for your tenant. **Verify the exact connector name/availability**; it is evolving.
3. With the Databricks admins, confirm whether the workspace is **Unity Catalog-enabled** and the
   **metastore** it attaches to, the **workspace URL**, and the **network posture** (public vs.
   VNet-injected / Private Link).
4. Record gaps against the Requirements checklist. Do **not** proceed past a missing account, a missing
   connector, missing least-privilege roles, a missing scan credential, or a missing network path —
   remediate those first.

## Step 2 — Design the collection and role model
1. Decide the **collection** the Databricks source registers into. For the pilot, create one collection
   named `DGDBX-Collection-Pilot` under the root; plan the broader hierarchy (for example a `Lakehouse`
   branch by workspace, business unit, or sensitivity) on paper for the expansion phase.
2. Assign least-privilege data-plane roles at the narrowest scope: **Data source admin** on
   `DGDBX-Collection-Pilot` to whoever will register/scan the workspace, **Data curator** to the catalog
   editors (edit assets/classifications, read lineage), **Data reader** to browsers, and **Collection
   admin** to a small named group. Reserve root-collection admin for the few setup actions only.

## Step 3 — Establish the scan credential path (Key Vault, safe by design)
1. Link an **Azure Key Vault** to the Purview account (or confirm one is linked).
2. Provision the **Databricks scan identity** the connector requires — a **service principal** or a
   **personal access token (PAT)**, per the connector's requirement (**verify which your connector
   accepts**). Grant it **least-privilege metadata read** on the in-scope catalogs/schemas in Databricks
   (Unity Catalog grants such as `USE CATALOG` / `USE SCHEMA` / `SELECT` or the metadata equivalents the
   connector documents — verify), never workspace-admin.
3. Store the secret in the **Key Vault** and create a Purview credential **by name** — `DGDBX-Cred-Databricks-KV`
   — that references the Key Vault secret. **No credential is ever placed in a script or document.** This
   name is what the scripts reference; the secret is never inlined.

## Step 4 — Establish the integration runtime and network path
1. Confirm the **integration runtime** for the workspace: the **Azure (managed) integration runtime** for
   a **reachable/public** workspace, or install and register a **self-hosted integration runtime (SHIR)**
   named `DGDBX-SHIR` on an in-network host for a **VNet-injected / Private Link** workspace.
2. Confirm the runtime shows **Running/Available**, and open only the network rules the scanner needs to
   reach the workspace (and the Unity Catalog metastore endpoint) — no broader. **Verify current IR /
   networking requirements for the connector** in Microsoft's docs.

## Step 5 — Record the pilot scope
1. Run `DGDBX-Set-Scope.ps1` to record the pilot Databricks scope — the **workspace URL**, the **one
   catalog/schema** to scan first, the owner/steward, the collection, the credential name, the scan rule
   set intent, and the (previewed) **schedule**. It writes a local scope manifest and, by default, only
   **previews** the schedule; it changes nothing in the tenant unless you pass `-Commit`.

## Step 6 — Register the pilot Databricks source into the Data Map
1. Register the workspace into `DGDBX-Collection-Pilot`. You may use the portal
   (**Register → Azure Databricks**), or run `DGDBX-Register-DatabricksSource.ps1` which **defaults to
   `-WhatIf`** and prints exactly what it would register (the connector kind, the workspace URL, the
   metastore, the collection, and the credential name); re-run with `-Commit` to register.
2. Run **Test connection** on the registered source and confirm it passes (the scan identity authenticates
   to the workspace, the metastore is reachable over the chosen IR) before scanning. Do not scan until
   Test connection passes.

## Step 7 — Configure and pilot the scan (bounded scope, pilot-first)
1. Define the scan configuration: a **scan rule set** named `DGDBX-ScanRuleSet-Pilot` (start from the
   system default rule set), the **classifications** to apply (system classifications plus any custom
   rule named `DGDBX-Classification-Custom-<name>`), and a **scoped** scan that targets only the pilot
   **catalog/schema** — not every catalog in the metastore.
2. Trigger the scan **once** on the bounded scope (not scheduled yet) via
   `DGDBX-Register-DatabricksSource.ps1 -ConfigureScan` (`-WhatIf` by default; `-Commit` to apply) or the
   portal. Pass/fail: the scan completes with **status Succeeded** and returns assets
   (catalogs → schemas → tables/views) with classifications.
3. **Rollback:** if a scan misbehaves, over-reaches, or runs up Databricks/Azure cost, cancel the run in
   the portal and set the scan to disabled; a scan does not modify source data, but cancel to stop
   resource/cost consumption. Re-scope and re-run on a smaller set (a single schema).

## Step 8 — Review scanned assets, classifications, and lineage
1. Run `DGDBX-Report.ps1` to export the pilot Databricks assets discovered (catalogs, schemas,
   tables/columns), the classifications applied, any assets returned **unclassified**, and **lineage
   coverage** (assets with lineage relationships) to CSV.
2. With the data owner, confirm the classifications are correct. Where a real internal pattern was missed,
   define a **custom classification rule** (`DGDBX-Classification-Custom-<name>`), validate it against
   sample data, add it to `DGDBX-ScanRuleSet-Pilot`, and re-scan the pilot scope.
3. Confirm **Unity Catalog lineage** is surfacing in the Data Map (table/column lineage where Unity
   Catalog tracks it). **Lineage availability and depth are connector- and tenant-dependent — verify**;
   if lineage is absent, confirm the connector version and Unity Catalog lineage prerequisites before
   assuming a defect.

## Step 9 — Curate the catalog and assign ownership
1. Assign the **data owner** and **steward** recorded in the scope manifest to the scanned catalog/schema/
   tables so every governed lakehouse asset has a named owner — ownership is what makes classification
   and later access decisions accountable.
2. In the **Unified Catalog**, create the governance domain `DGDBX-Domain-Lakehouse` and publish the
   pilot assets as a curated **data product** (`DGDBX-DataProduct-<name>`) with an owner, a use purpose,
   and glossary terms. **Verify current Unified Catalog paths and data-quality availability for your
   tenant** — the catalog experience is evolving and some capabilities are in preview.

## Step 10 — Validate against the pilot gate
1. Complete the Testing Guide. Run `DGDBX-Test-Readiness.ps1` for a consolidated PASS/GAP gate check. The
   pilot passes only when: the account is reachable and roles are assigned; the integration runtime is
   present and the Key Vault credential resolves; the Databricks source is registered and **Test
   connection** passes; the scan **Succeeded** and returned classified assets; and every scanned pilot
   asset has an owner assigned.
2. Remediate any gaps and re-run the relevant validation before proceeding. Do **not** widen scope until
   the gate passes.

## Step 11 — Expand across the metastore (enforce)
1. After the pilot passes, register/scan further catalogs and schemas one grouping at a time, re-running
   `DGDBX-Set-Scope.ps1`, `DGDBX-Register-DatabricksSource.ps1`, and `DGDBX-Report.ps1` for each new
   scope. Reuse the same Key Vault credential pattern (extending the Databricks-side metadata read grants
   to the new catalogs/schemas).
2. Move scans from one-time to **scheduled** only once a scope is validated — set the schedule with
   `DGDBX-Set-Scope.ps1 -Commit` (or in the portal) — so classifications and lineage stay current as
   lakehouse data changes. Watch Databricks compute / Azure metered cost as scope grows.
3. Keep ownership assigned on every newly scanned asset, keep curating data products, and track coverage
   (classification and lineage) with `DGDBX-Report.ps1`.

---
### Order of operations
`Assess -> Design (collection/roles) -> Scan credential (Key Vault) -> Integration runtime & network -> Record scope -> Register Databricks source -> Pilot scan (bounded catalog/schema) -> Review classifications + lineage -> Curate catalog & assign ownership -> Validate gate -> Expand (scheduled scans)`
