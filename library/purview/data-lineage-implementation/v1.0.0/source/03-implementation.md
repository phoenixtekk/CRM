# 3. Implementation Guide — Data Lineage Implementation (Microsoft Purview)

Follow these steps **in order**. Work is done in the **Microsoft Purview portal**, the **Data Map /
Unified Catalog**, and **PowerShell/REST** against the documented **Azure Purview data-plane APIs**
(catalog/Atlas, scanning, collections) authenticated with `Connect-AzAccount` /
`Get-AzAccessToken -ResourceUrl 'https://purview.azure.net'`. All writes are previewed with **`-WhatIf`**
before `-Commit`/`-Apply`. Artifact names follow the `<Purpose> – DGLINE – <Stage>` convention from the
Overview and are reused verbatim.

> **Model:** Assess the Data Map, design the coverage/connection map, configure connections + scans +
> custom lineage, prove it on a **pilot scope**, validate the graph and coverage, then expand across the
> estate. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
>
> **Portal paths and REST `api-version` values are cited as of authoring and this area is actively
> evolving (classic Data Map vs. the unified Unified Catalog experience) — verify each in your own
> tenant.** Data lineage is a **Data Governance (Data Map)** capability, separately provisioned and
> billed from E5 compliance (Requirement 2.1). Automatic lineage is captured only for **runs after** the
> connection exists — connect early; history is not back-filled.

## Step 1 — Assess the Data Map (Assess)
1. Open the **Purview portal** and confirm the account, the **Data Map**, and the **Collections** tree
   load. Note the account data-plane endpoint `https://<account>.purview.azure.com`.
2. Run `DGLINE-ScopeHealth.ps1 -Account <account>`. Read-only, it confirms the account endpoint is
   reachable, acquires a **data-plane token** (`purview.azure.net`), and lists the **collections** your
   token can enumerate — establishing you have the data-plane roles to proceed.
3. Run `DGLINE-Discovery.ps1 -Account <account> -CsvPath .\LineageDiscovery.csv`. Read-only, it captures:
   the **registered data sources**, their **last-scan status**, and — per source — whether it is
   **lineage-capable/connected** (ADF/Synapse/Data Share/Power BI report automatically) or will need
   **custom lineage**. It writes `Data Lineage Source Inventory – DGLINE – Discovery`.
4. **Pass/fail:** you have a complete inventory — for every in-scope source you can state "registered +
   scanned" and "automatic lineage / needs custom lineage".

## Step 2 — Design the coverage/connection map (Design)
1. From the discovery output and the stakeholders' **coverage target** (Requirement 2.7), build
   `Data Lineage Coverage Map – DGLINE – Design`: for each in-scope **source→report path**, record the
   assets at each hop (by qualified name), and **how lineage is produced** — an automatic connection
   (ADF/Synapse/Data Share/Power BI) or a **custom `Process`** pushed via the Atlas API.
2. Confirm each path's endpoints are (or will be) **registered and scanned** into the Data Map — a
   lineage edge needs both ends known (Requirement 2.4). Flag any endpoint not yet scanned as a
   prerequisite task.
3. Pick the **pilot scope** `Data Lineage Pilot Scope – DGLINE – Stage1`: one collection or a single
   representative source→report path (ideally one automatic and one custom, to prove both mechanisms).
4. **Pass/fail:** every in-scope path has a defined lineage-production method and confirmed endpoints; a
   pilot scope is named.

## Step 3 — Ensure the endpoints are scanned into the Data Map (Configure)
1. For each path endpoint not yet scanned, register the source to its collection and run a scan (Purview
   portal → **Data Map → Data sources → Register / New scan**, verify path). Re-run
   `DGLINE-Discovery.ps1` and confirm **completed** scans.
2. Confirm the assets are searchable in the catalog (portal search, or the catalog search API surfaced
   by `DGLINE-Validate.ps1`).
3. **Pass/fail + rollback:** every in-scope endpoint shows a completed scan and resolvable assets.
   Rollback for a mis-registered source is to **remove the scan/source** in the portal — no lineage has
   been drawn yet.

## Step 4 — Connect the automatic-lineage sources (Configure, pilot-first)
1. For the pilot path's automatic source, connect the integration system to **this Purview account**:
   ADF/Synapse workspace → connect to Purview; Power BI → register + scan the tenant/workspaces (Purview
   portal → **Data Map → Integration / connections**, verify path — classic vs. unified differ).
2. **Run the pilot pipeline** (or refresh the Power BI dataset) so the activity **reports lineage**.
   Automatic lineage is captured on the **run after** the connection exists — a pre-existing run is not
   back-filled.
3. Re-run `DGLINE-Discovery.ps1` to confirm the connection is recognized. Record the connection in
   `Data Lineage Connections – DGLINE – Configure`.
4. **Pass/fail + rollback:** the pilot pipeline run produces a lineage edge (validated in Step 6).
   Rollback is to **disconnect** the integration source from Purview in the portal; no source data is
   altered.

## Step 5 — Push custom lineage for non-automatic paths (Configure, pilot-first)
1. For the pilot's custom path, dry-run first:
   `DGLINE-Configure.ps1 -Account <account> -MapPath .\LineageMap.csv -WhatIf`. With `-WhatIf` (the
   default) it makes **no changes** — it prints the **Atlas `Process` entity** it would push (the
   `inputs`/`outputs` qualified names, the process type/name) and flags any referenced asset it cannot
   resolve in the catalog.
2. Read every line against `Data Lineage Coverage Map – DGLINE – Design`. Confirm the input/output
   qualified names resolve to the intended scanned assets and no unintended entity would be created.
3. Apply to the **pilot path only**: `DGLINE-Configure.ps1 -Account <account> -MapPath .\LineageMap.csv
   -Commit`. It POSTs the `Process` entity to the catalog `/catalog/api/atlas/v2/entity` (or
   `/lineage`) endpoint (verify `api-version`), creating the lineage relationship. Updates
   `Data Lineage Connections – DGLINE – Configure`.
4. **Pass/fail + rollback:** the pilot custom-lineage `Process` is created and renders (Step 6). Rollback
   is to **delete the pushed `Process` entity** by GUID (the script prints the created GUID and the exact
   reverse `DELETE` call) — only the lineage entity is removed, never the underlying data assets.

## Step 6 — Validate the pilot lineage graph (Pilot → Validate)
1. Run `DGLINE-Validate.ps1 -Account <account> -Asset '<qualified-name>'` for a pilot sink asset.
   Read-only, it queries the **Atlas lineage endpoint** (`/catalog/api/atlas/v2/lineage/…`, verify
   `api-version`) and reports the **upstream** and **downstream** entities and the edge count.
2. In the portal, open the pilot asset's **Lineage** tab and confirm the graph matches — source →
   process → sink, correct hops.
3. Have a data owner confirm the pilot path's lineage is **correct** (right sources, right consumers) —
   not just present. **Pass/fail:** the pilot path's lineage renders and is confirmed accurate by the
   owner; complete the relevant **Testing Guide** gates on the pilot scope before expanding.

## Step 7 — Measure coverage (Validate)
1. Run `DGLINE-Report.ps1 -Account <account> -CsvPath .\LineageCoverage.csv`. Read-only, it enumerates
   the in-scope assets and reports **coverage** — assets **with** lineage vs. **without**, per collection
   / source — and the last-scan status. It writes `Data Lineage Coverage – DGLINE – Report`.
2. Compare coverage against the stakeholders' target (Requirement 2.7). Every gap is an explicit
   follow-up (a missing scan, a missing connection, or a custom-lineage `Process` to push) — **not** a
   silent hole.
3. **Pass/fail:** a dated coverage report exists; each gap is recorded as a named follow-up item.

## Step 8 — Expand across the estate (Expand)
1. Repeat Steps 3–7 for the remaining in-scope collections/sources: scan the endpoints, connect the
   automatic sources (`-WhatIf` → run the pipeline), push custom lineage (`-WhatIf` → `-Commit`), then
   validate and re-measure coverage.
2. Re-run `DGLINE-Report.ps1` after each wave and drive coverage toward the target, closing gaps
   deliberately.
3. **Determinations about what coverage is *required* (regulatory/records) and which source is
   authoritative remain the governance team's** — you deliver the capability, the graph, and the
   measured coverage. Hand off any classification/label/DLP/retention work to the dedicated Purview
   solutions; this solution delivers **lineage**.

---
### Order of operations
`Assess Data Map (sources, scans, lineage capability) → Design coverage/connection map + pilot scope →
Scan endpoints into the Data Map → Connect automatic sources (pilot; run the pipeline) → Push custom
lineage (-WhatIf → -Commit, pilot) → Validate the pilot graph → Measure coverage → Expand across the
estate, re-measuring coverage`
