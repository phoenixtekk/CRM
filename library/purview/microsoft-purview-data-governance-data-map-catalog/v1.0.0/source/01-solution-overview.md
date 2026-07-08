# 1. Solution Overview — Microsoft Purview Data Governance: Data Map, Scanning & Unified Catalog

## What this solution is
Microsoft Purview has two related but distinct sides. The **compliance** side (labels, DLP,
retention, insider risk) governs Microsoft 365 content. This solution implements the **data
governance** side: the **Data Map**, **scanning and classification**, and the **Unified Catalog** —
the experience that governs the *whole data estate*, not just Microsoft 365. That estate includes
Azure storage and databases, multicloud sources (AWS, GCP), and on-premises systems. This is the
evolution of what was formerly **Azure Purview / Microsoft Purview Data Catalog** — the portal,
experience names, and billing model are **actively evolving**, so every capability below is flagged
"verify your licensing/tenant" where availability or naming may have moved.

> **Boundary.** This solution provides the technical method to *map, scan, classify, catalog, and
> wire lineage* across the data estate. It does **not** make the business or regulatory
> determinations — which data is "confidential", what the retention or records schedule is, or who
> may access what — those belong to the organization's data owners, stewards, compliance, privacy,
> and legal functions. The solution gives them a governed, discoverable estate to make those
> decisions against.

## Why this matters
Beyond Microsoft 365, most organizations have no idea where their sensitive data actually lives.
Customer records sit in an Azure SQL database, financial extracts land in a data lake, a copy of a
table gets exported to an S3 bucket, and an analyst's report reads from three of them. Nobody can
answer "where is our PII?", "who owns this table?", or "if this column is wrong, what breaks
downstream?" — because there is no map, no classification, and no catalog. Ungoverned data is
un-securable data: you cannot protect, retain, or grant access to something you cannot see. This
solution builds the map and the catalog so the estate becomes discoverable, classified, and owned.

## The four building blocks
This solution stands up four things in order. Each is named once in the Implementation Guide and
reused everywhere.

1. **The Data Map** — a live inventory of your data sources and the assets inside them. You register
   sources (Azure Blob/ADLS, Azure SQL, Synapse, AWS S3, GCP, on-premises SQL, and more) into a
   **collection** hierarchy that also carries access control. The Data Map is the foundation; nothing
   else works without it.
2. **Scanning & classification** — scans connect to each registered source, enumerate its assets
   (databases, tables, files), and apply **classifications** (system classifications such as credit
   card or national ID number, plus any custom classifications you define). Classification is what
   turns a raw inventory into a *sensitivity-aware* map.
3. **The Unified Catalog** — the business-facing layer built on top of the map: **governance
   domains** (business groupings), **data products** (curated, published sets of assets with an
   owner and a use purpose), a **business glossary** (agreed terms and critical data elements), and
   **data quality**. This is where the estate becomes usable by the business, not just visible to IT.
4. **Lineage** — the wiring that shows how data flows from source to report. Lineage is captured
   automatically from supported systems (Azure Data Factory, Synapse, Power BI, and more) and from
   scans, so you can trace an asset upstream to its origin and downstream to its consumers.

## Collections, governance domains, and roles
Access in the Data Map is organized by **collections** — a hierarchy under the Purview account. Each
collection carries its own role assignments: **Collection admins** (manage the collection and its
roles), **Data source admins** (register sources and run scans), **Data curators** (edit catalog
metadata and classifications), and **Data readers** (browse the catalog). The Unified Catalog adds
**governance roles** (governance domain owners, data product owners, data stewards, data quality
stewards). Least-privilege role assignment is a first-class step, not an afterthought — the
Implementation Guide names each role at each stage.

## Credentials and network — safe by design
Scanning reaches into live systems, so it needs credentials and network paths. This solution follows
the safe-by-design pattern Microsoft documents: the Purview account's **managed identity** and an
**Azure Key Vault** hold source credentials; **no secret is ever stored in a script or document**.
Cloud sources are reached through the **Azure (managed) integration runtime**; on-premises and
network-restricted sources are reached through a **self-hosted integration runtime (SHIR)** you
install inside the network. Scans are always **piloted on a bounded scope first** before you scan the
whole estate.

## Licensing and the evolving portal
Microsoft Purview Data Governance (the Unified Catalog and Data Map) is billed through a
**consumption / pay-as-you-go** model tied to an **Azure subscription**, and the capability set is
evolving — some features (for example, **data quality** and certain **multicloud connectors**) may be
in preview or may have changed name or availability. **Verify current pricing, availability, and
portal paths for your tenant** in Microsoft's documentation and in the Purview portal before you
plan. This solution cites the method; it never asserts a price or a portal path as permanent.

## What this is not
This is the *data-estate governance* solution. It is **not** the Microsoft 365 compliance
configuration (sensitivity/retention labels, DLP, insider risk, records management) — those are
separate Purview solutions in this category. It complements them: labels and DLP protect M365
content; the Data Map and Unified Catalog govern everything else and tie the picture together.

## The deployment model
> Assess the estate and readiness, design the collection/domain and role model, configure the Data
> Map and scans, **pilot scanning on a bounded scope**, validate the results against the gate, then
> expand across the estate — enforcing broader scanning and catalog curation only after the pilot
> passes. The repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.**
