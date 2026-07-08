# 1. Solution Overview — Data Lineage Implementation (Microsoft Purview)

## What this solution is
"Where did this number come from?" is the question a data governance program has to be able to answer.
This solution implements **data lineage in Microsoft Purview** — end to end — so that for a given
asset (a report, a table, a file) you can trace it **back to its sources** and **forward to where it
is consumed**, across the ingestion and transformation systems that move data through the estate.

Lineage in Microsoft Purview is a capability of the **Microsoft Purview Data Map / Unified Catalog**
(the data-governance side of Purview, historically "Azure Purview"). Purview builds a lineage graph
by:

- **Scanning** registered data sources into the **Data Map** so the assets exist as catalog entities.
- **Automatically capturing lineage** reported by supported data-integration systems — **Azure Data
  Factory**, **Azure Synapse pipelines**, **Azure Data Share**, and **Power BI** — as those systems
  run copy/transform activities and push lineage to Purview.
- **Accepting custom lineage** pushed through the **Apache Atlas–compatible catalog REST API** for
  systems that don't report automatically (custom ETL, Spark/Hive via connectors, home-grown
  pipelines).
- **Visualizing** the result on each asset's **Lineage** tab in the Purview catalog — source → process
  → sink, hop by hop.

Everything is done with the **Microsoft Purview portal**, the **Purview Data Map / Unified Catalog**,
and **PowerShell/REST** against the documented **Azure Purview data-plane APIs** (catalog/Atlas,
scanning, collections) using **`Connect-AzAccount` / `Get-AzAccessToken`** — no third-party tooling and
no credentials stored in code.

> **Scope boundary — this is lineage, built on the Data Map foundation.** This solution configures and
> validates **lineage capture and visualization**. It assumes (or stands up just enough of) a Purview
> **Data Map / Unified Catalog** with the in-scope sources **registered and scanned** so assets exist
> to draw lineage between. Deep classification/label programs, DLP, retention/records, insider risk,
> and communication compliance are the subject of the **other Purview solutions** and are not
> duplicated here.

## Why this matters
- **Traceability is the governance gap.** Without lineage, nobody can prove where a figure came from,
  which reports break if a source changes, or which downstream consumers a data-quality issue touches.
  That is both a compliance exposure and an operational risk.
- **Impact analysis becomes possible.** Lineage turns "if we change this table, what breaks?" from a
  guess into a graph you can read — upstream dependencies and downstream consumers, visible.
- **Automatic lineage is only automatic if the source is connected the right way.** ADF, Synapse, and
  Power BI report lineage to Purview **only** when connected and running against registered assets;
  getting that connection right is most of the work, and it is easy to get subtly wrong.
- **Gaps must be found, not assumed.** A lineage graph with silent holes is worse than none — you
  trust it and it's wrong. This solution measures **coverage** so the gaps are explicit and closed
  deliberately (custom lineage, additional scans) rather than discovered during an incident.

## How it works
1. **Assess.** Read the Purview account, its **collections**, the **registered data sources**, and the
   **scan** status — and identify which sources produce lineage automatically (ADF/Synapse/Power BI)
   vs. which will need **custom lineage**. Read-only, no changes.
2. **Design.** Map the **lineage coverage** you need: for each in-scope pipeline/source→report path,
   decide how lineage is produced (automatic via a connection, or pushed via the Atlas API), and pick
   a **pilot scope** (one collection / a couple of representative sources) to prove it on first.
3. **Configure.** Register the lineage-producing **connections** (e.g. connect ADF/Synapse/Power BI to
   Purview), ensure the underlying assets are **scanned** into the Data Map, and — for sources that
   don't self-report — push **custom lineage** through the catalog Atlas API. Writes are previewed with
   **`-WhatIf`** before `-Commit`/`-Apply`.
4. **Pilot (test scope).** Prove lineage on the **pilot scope first**: run the pilot pipeline (or push
   the pilot custom lineage), then confirm the lineage graph renders correctly for the pilot assets
   before touching the rest of the estate. High-impact steps (connecting production sources, pushing
   lineage) are always exercised on the pilot scope before expansion.
5. **Validate.** Query the lineage graph for named assets through the Atlas lineage endpoint, confirm
   the **upstream/downstream edges** exist and are correct, and measure **coverage** (assets with
   lineage vs. without).
6. **Expand.** Extend the same pattern to the remaining collections/sources, re-measuring coverage and
   closing gaps until the in-scope estate is traceable.

## Where lineage comes from (the capture model)
| Source system | How lineage is captured | What you configure |
|---|---|---|
| **Azure Data Factory** | Automatic — copy/data-flow activities report lineage to Purview | Connect the ADF account to Purview (Purview account → **Data Map → Integration / connections**, verify path) |
| **Azure Synapse pipelines** | Automatic — pipeline activities report lineage | Connect the Synapse workspace to Purview |
| **Power BI** | Automatic — datasets/reports report lineage on scan | Register + scan the Power BI tenant/workspaces into the Data Map |
| **Azure Data Share** | Automatic — share snapshots report lineage | Connect Data Share to Purview |
| **Custom ETL / Spark / Hive / home-grown** | **Custom lineage** pushed via the **Atlas catalog REST API** (`/catalog/api/atlas/v2/…`) | Push `Process` entities with `inputs`/`outputs` referencing scanned assets |

> **Lineage needs the endpoints to exist.** An automatic-lineage edge only renders if **both** ends —
> the source asset and the sink asset — are registered/scanned into the Data Map (or referenced by
> qualified name). "Connect the pipeline" and "scan the stores" go together; one without the other
> produces a half-drawn graph.

## Naming convention (used in every doc and script)
Artifacts follow `<Purpose> – DGLINE – <Stage>` and are reused verbatim across the docs, scripts, and
portal.

| Artifact | Name |
|---|---|
| Source + scan + lineage-capability inventory | `Data Lineage Source Inventory – DGLINE – Discovery` |
| Coverage/connection design (per source→report path) | `Data Lineage Coverage Map – DGLINE – Design` |
| Registered lineage connections + custom-lineage config | `Data Lineage Connections – DGLINE – Configure` |
| Lineage graph validation (upstream/downstream edges) | `Data Lineage Validation – DGLINE – Validate` |
| Lineage coverage report (with/without lineage) | `Data Lineage Coverage – DGLINE – Report` |
| Pilot scope (collection / pilot sources) | `Data Lineage Pilot Scope – DGLINE – Stage1` |

## What you can control
- Which **collections** and **data sources** are in scope for lineage.
- How lineage is produced per path — **automatic connection** vs. **custom lineage** via the Atlas API.
- The **pilot scope** used to prove lineage before expanding to the estate.
- The **coverage target** (which source→report paths must be traceable) — the *business* target is set
  with the data owners; you deliver the technical capability and the measured coverage against it.

## Limitations (be honest with buyers)
- **Purview Data Governance is separately provisioned and billed.** Data lineage lives in the **Data
  Map / Unified Catalog**, which is an **Azure-metered / consumption-based** service (capacity units /
  pay-as-you-go under an Azure subscription) — **distinct** from the Microsoft 365 E5 / E5 Compliance
  capabilities. It requires a **Purview (Data Governance) account** and appropriate **data-plane roles**
  (Collection admin / Data source admin / Data curator). **Verify the current provisioning model,
  pricing, and role model against Microsoft's documentation and your own tenant** — this area is
  actively evolving (the classic Data Map and the new Unified Catalog experience).
- **Automatic lineage depends on the source and on Microsoft's connectors.** Only supported systems
  (ADF, Synapse, Data Share, Power BI, and Atlas-hook connectors) report lineage automatically, and
  **only for supported activities/asset types**. Coverage for unsupported systems is achieved with
  **custom lineage** via the Atlas API — real work, not automatic.
- **Lineage is not retroactive for runs before the connection existed.** Automatic lineage is captured
  as pipelines **run after** they are connected to Purview; historical runs are not back-filled. Connect
  early.
- **API versions and portal paths evolve.** The data-plane REST `api-version` values and portal
  navigation change over time and differ across the classic vs. unified experience — every one is
  **cited as of authoring and flagged "verify in your tenant."** No endpoint or path is invented.
- **Governance determinations are deferred.** What lineage coverage is *required* for a given
  regulatory/records obligation, and what the authoritative source of a data element *is*, are
  decisions for the **data-governance, records, privacy, and compliance** functions — this solution
  provides the technical capability, the graph, and the coverage evidence, not the determination.

## The standard deployment model
> Assess the Data Map (sources, scans, lineage capability) → design the coverage/connection map →
> configure connections + scans + custom lineage (preview with `-WhatIf` first) → pilot on a small
> scope → validate the graph and coverage → expand across the estate.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
