# 3. Implementation Guide — Microsoft Purview Data Governance: Data Map, Scanning & Unified Catalog

Follow these steps in order. This guide stands up the Data Map and roles, registers and scans a pilot
source set, curates the Unified Catalog, wires lineage and data quality, then expands across the
estate. Artifact names are fixed — create them with the exact names shown and reuse them everywhere.
**Every scan is piloted on a bounded scope before the estate is scanned.**

> Model: build the map, prove classification and curation on a pilot scope, then expand. The
> repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.** Verify current portal
> paths and capability availability for your tenant as you go — the Purview Data Governance experience
> is evolving.

## Step 1 — Assess current state (read-only)
1. Run `PURVGOV-Discovery.ps1` to capture readiness signals: the Purview account endpoint is
   reachable, which **collections** exist and their **role coverage**, which **integration runtimes**
   are registered, and how many sources/assets are already known. No changes are made.
2. Record gaps against the Requirements checklist. Do **not** proceed past a missing account, missing
   least-privilege roles, or a missing network path — remediate those first.

## Step 2 — Design the collection, domain, and role model
1. Decide the **collection hierarchy** under the account. For the pilot, create one collection named
   `DG-Collection-Pilot` under the root; plan the broader hierarchy (by business unit or by
   sensitivity) on paper for the expansion phase.
2. Decide the first **governance domain** named `DG-Domain-Pilot` (for example, Finance) in the
   Unified Catalog.
3. Assign least-privilege roles at the narrowest scope: **Collection admin** to a small named group on
   `DG-Collection-Pilot`, **Data source admin** to whoever will register/scan, **Data curator** to the
   catalog editors, **Data reader** to browsers; assign **governance domain owner** and **data product
   owner** in the Unified Catalog. Reserve account-level admin for a minimal named group.

## Step 3 — Establish credentials and network paths (safe by design)
1. Link an **Azure Key Vault** to the Purview account (or confirm the account's **managed identity**
   can read each source). **Do not put any secret in a script or document.**
2. For each pilot source, grant the least read role to the managed identity or store the secret in Key
   Vault.
3. Confirm the **integration runtime** for each source: the **Azure (managed) runtime** for reachable
   cloud sources, or install and register a **self-hosted integration runtime (SHIR)** for on-premises
   or private-network sources. Confirm it shows **Running/Available**.

## Step 4 — Register the pilot sources into the Data Map
1. Run `PURVGOV-Set-Scope.ps1` to record the pilot source set and the pilot domain/data-product intent
   (read-only; produces the scope manifest you register against).
2. Register the pilot sources (for example `sql-fin-01.contoso.com` Azure SQL and an ADLS Gen2
   container) into `DG-Collection-Pilot`. You may use the portal, or run
   `PURVGOV-Register-Source.ps1` which **defaults to `-WhatIf`** and prints exactly what it would
   register; re-run with `-Commit` to register.
3. Run **Test connection** for each registered source and confirm it passes before scanning.

## Step 5 — Configure and pilot the scan (bounded scope, pilot-first)
1. Define the scan configuration: a **scan rule set** named `DG-ScanRuleSet-Pilot` (start from the
   system default rule set), the **classifications** to apply (system classifications plus any custom
   rule named `DG-Classification-Custom-<name>`), and a **scoped** scan that targets only the pilot
   assets — not the whole source.
2. Trigger the scan **once** on the bounded scope (not scheduled yet). Use
   `PURVGOV-Register-Source.ps1 -ConfigureScan` (`-WhatIf` by default; `-Commit` to apply) or the
   portal. Pass/fail: the scan completes with **status Succeeded** and returns assets with
   classifications.
3. **Rollback:** if a scan misbehaves or over-reaches, cancel the run in the portal and set the scan to
   disabled; no source data is modified by a scan, but cancel to stop resource consumption. Re-scope
   and re-run.

## Step 6 — Review scanned assets and classifications
1. Run `PURVGOV-Report.ps1` to list the pilot assets discovered, the classifications applied, and any
   assets returned **unclassified**.
2. With the data owner, confirm the classifications are correct. Where a real internal pattern was
   missed, define a **custom classification rule** (`DG-Classification-Custom-<name>`), validate it
   against sample data, add it to `DG-ScanRuleSet-Pilot`, and re-scan the pilot scope.

## Step 7 — Curate the Unified Catalog (glossary, data product, ownership)
1. Create the initial **business glossary** term set named `DG-Glossary-Pilot` with the 5–10 agreed
   terms / critical data elements; use `PURVGOV-Curate-Catalog.ps1 -Glossary` (`-WhatIf` by default;
   `-Commit` to write).
2. Create the first **data product** named `DG-DataProduct-Pilot` in `DG-Domain-Pilot`: add the
   relevant scanned assets, set its **owner**, **use purpose**, and **terms of use**; use
   `PURVGOV-Curate-Catalog.ps1 -DataProduct` (`-WhatIf`/`-Commit`).
3. Assign **ownership and stewardship** on the assets and the data product so every published asset has
   a named owner and steward.

## Step 8 — Wire lineage
1. Confirm **lineage** is captured for the pilot's supported systems (for example, an Azure Data
   Factory or Synapse pipeline, or a Power BI dataset that reads the pilot source). Lineage populates
   automatically from these systems and from scans.
2. In the catalog, open a pilot asset and confirm you can trace it **upstream** to its source and
   **downstream** to its consumers. Record any gaps where a system is not a lineage source.

## Step 9 — Establish data quality (verify availability)
1. If **data quality** is available in your tenant (this feature may be preview — verify), define a
   small **data-quality rule set** named `DG-DQ-Ruleset-Pilot` against the pilot data product's
   critical data elements (for example, completeness or format rules on a key column).
2. Run the data-quality assessment and record the baseline **quality score**. If the feature is not
   available in your tenant, record that and defer this step to the expansion phase.

## Step 10 — Validate against the pilot gate
1. Complete the Testing Guide. The pilot passes only when: the pilot sources are registered and
   **Test connection** passes; the scan **Succeeded** and returned classified assets; the Unified
   Catalog has `DG-Glossary-Pilot` and `DG-DataProduct-Pilot` with owners assigned; and lineage
   resolves for at least one pilot asset.
2. Remediate any gaps and re-run the relevant validation before proceeding. Do **not** widen scope
   until the gate passes.

## Step 11 — Expand across the estate (enforce)
1. After the pilot passes, add collections and register further sources one grouping at a time,
   re-running `PURVGOV-Set-Scope.ps1`, `PURVGOV-Register-Source.ps1`, and `PURVGOV-Report.ps1` for each
   new scope.
2. Move scans from one-time to **scheduled** only once a scope is validated, so classifications stay
   current as data changes.
3. Curate each newly scanned scope into governance domains and data products, extend `DG-Glossary-*`,
   and keep ownership assigned. Track coverage with `PURVGOV-Report.ps1`.

---
### Order of operations
`Assess -> Design (collections/domain/roles) -> Credentials & network -> Register pilot sources -> Pilot scan (bounded) -> Review classifications -> Curate catalog (glossary/data product/ownership) -> Wire lineage -> Data quality -> Validate gate -> Expand (scheduled scans)`
