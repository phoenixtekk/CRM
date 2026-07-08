# 1. Solution Overview — Databricks Data Governance in Microsoft Purview

## What this solution is
Your lakehouse is almost certainly your largest concentration of sensitive data — customer records,
financial extracts, PII, model features — and it very often sits **outside** the governance that
covers Microsoft 365. This solution governs **Azure Databricks / lakehouse** data *from* Microsoft
Purview: you **register** the Databricks workspace as a data source in the Purview **Data Map**,
**scan** it to enumerate and **classify** its catalogs, schemas, tables, and columns, **catalog** the
assets into the Unified Catalog with owners and glossary terms, and surface **lineage** so an asset
can be traced from source to consumer. The result is a lakehouse that is discoverable, classified,
owned, and governed alongside the rest of your estate — not a blind spot.

> **Boundary.** This solution provides the technical method to *register, scan, classify, catalog, and
> wire lineage* for Databricks/lakehouse assets. It does **not** make the business or regulatory
> determinations — which table is "confidential", what the retention/records schedule is, or who may
> access what. Those belong to the organization's data owners, stewards, compliance, privacy, and
> legal functions. The solution gives them a governed, discoverable lakehouse to decide against.

## Why this matters
Analysts and data engineers create tables in Databricks faster than any governance process can track
them. A notebook joins three tables and writes a fourth; a job exports a table to a downstream report;
a copy of a regulated dataset lands in a new schema. Nobody can answer "where is our PII in the
lakehouse?", "who owns this table?", or "if this column changes, what breaks downstream?" — because
the lakehouse was never registered, scanned, or cataloged in the tool that governs everything else.
Ungoverned lakehouse data is un-securable lakehouse data. This solution registers Databricks into
Purview so the lakehouse becomes part of the governed estate.

## Databricks and the Purview connectors
Microsoft Purview registers and scans Azure Databricks through a **data-source connector**. There are
two shapes, and which one fits depends on how your workspace is configured — **verify current
availability and the exact connector for your tenant** in Microsoft's documentation, as the Data
Governance experience is evolving and some connectors are newer than others:

1. **Azure Databricks Unity Catalog** — the modern connector. It reads the workspace's **Unity Catalog
   metastore** and enumerates its **catalogs → schemas → tables/views** into the Data Map, applies
   **classifications**, and brings **Unity Catalog lineage** (the table/column lineage Unity Catalog
   tracks) into Purview. Use this where the workspace is Unity Catalog-enabled.
2. **Azure Databricks (Hive Metastore)** — the connector for workspaces using the legacy **Hive
   metastore**. It enumerates and classifies Hive metastore databases/tables. Use this where Unity
   Catalog is not enabled.

This solution is written for the **Unity Catalog** path (the recommended, lineage-rich one) and notes
where the Hive-metastore path differs. Confirm which your workspace uses before you register.

## The building blocks
This solution stands up, in order:

1. **The Data Map registration** — the Databricks workspace registered as a source inside a **Purview
   collection** (which also carries access control). Nothing else works until the workspace is
   registered and reachable.
2. **Scanning & classification** — a **scoped scan** connects to the workspace, enumerates its
   catalogs/schemas/tables, and applies **classifications** (built-in system classifications such as
   credit-card or national-ID number, plus any custom classification rule you define). Classification
   turns the raw table inventory into a *sensitivity-aware* map.
3. **The Unified Catalog** — the business layer: a **governance domain**, one or more curated **data
   products** (published sets of lakehouse assets with an owner and a use purpose), a **business
   glossary**, and (where available) **data quality**.
4. **Lineage** — the wiring that shows how lakehouse data flows. The Unity Catalog connector brings
   Databricks lineage into the Data Map so you can trace an asset upstream to its origin and
   downstream to its consumers. Lineage availability/depth is connector- and tenant-dependent —
   verify.

## Credentials and network — safe by design
Scanning reaches into the live Databricks workspace, so it needs a credential and a network path. This
solution follows the safe-by-design pattern Microsoft documents: a **Databricks credential** (a
service principal or personal access token, per the connector's requirement) is stored in an **Azure
Key Vault** linked to the Purview account and referenced **by name** — **no secret is ever placed in a
script or document**. Reachable (public) workspaces are scanned through the **Azure (managed)
integration runtime**; **VNet-injected / private-link** workspaces are scanned through a **self-hosted
integration runtime (SHIR)** with network line-of-sight. Scans are always **piloted on a bounded
scope** (one catalog/schema) before the whole workspace is scanned.

## Licensing and the evolving portal
Microsoft Purview Data Governance (the Data Map and Unified Catalog) is billed through a
**consumption / pay-as-you-go** model tied to an **Azure subscription**, and the capability set —
including specific connectors, lineage depth, and **data quality** — is evolving, with some features in
preview. **Verify current pricing, connector availability, and portal paths for your tenant** in
Microsoft's documentation and the Purview portal before you plan. This solution cites the method; it
never asserts a price, a connector name, or a portal path as permanent.

## What this is not
This is the *lakehouse data-governance* solution. It is **not** the Microsoft 365 compliance
configuration (sensitivity/retention labels, DLP, insider risk, records management) — those are
separate Purview solutions in this category. It is also **not** Databricks-side governance (Unity
Catalog grants/ACLs remain configured in Databricks); this brings the Databricks estate *into* Purview
so it is mapped, classified, cataloged, and lineage-wired next to everything else.

## The deployment model
> Assess the workspace and readiness, design the collection/domain/role model, configure the source
> and scan safely, **pilot the scan on one catalog/schema**, validate against the gate, then expand
> across the metastore — enabling scheduled scans only after a scope passes. The repeatable way:
> **Assess → Design → Configure → Pilot (bounded scan) → Validate → Expand.**
