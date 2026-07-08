# 1. Solution Overview — SAP Data Governance: Microsoft Purview

## What this solution is
Microsoft Purview has two related but distinct sides. The **compliance** side (labels, DLP,
retention, insider risk) governs Microsoft 365 content. This solution implements a focused slice of
the **data governance** side: **registering, scanning, and classifying your SAP data into the Purview
Data Map**, so SAP stops being a governance blind spot and becomes a mapped, classified, cataloged
part of your estate. It does not re-implement the whole Data Map / Unified Catalog build; it delivers
the **SAP-source connector workflow** end-to-end: register the source, stand up the scanner and driver
path, run a bounded pilot scan, review classifications, then expand.

> **Boundary.** This solution provides the technical method to *register, scan, classify, and catalog*
> SAP sources. It does **not** make the business or regulatory determinations — which SAP data is
> "confidential", what the retention or records schedule is, or who may access it — those belong to
> the organization's data owners, stewards, compliance, privacy, and legal functions. The solution
> gives them governed, discoverable SAP metadata to make those decisions against.

## Why this matters
Most organizations govern Microsoft 365 well and their SAP estate not at all. Customer master data,
financial documents, HR/payroll records, and material/vendor data all live in SAP — and none of it
appears in the data map. Nobody can answer "where does PII live in SAP?", "which SAP tables hold
regulated data?", or "who owns this data source?" — because SAP was never registered, scanned, or
classified. Ungoverned data is un-securable data: you cannot protect, retain, or grant access to
something you cannot see. This solution brings SAP into the same Purview Data Map that already governs
the rest of the estate — cataloging the SAP **metadata** (systems, tables/objects, fields) and
applying classifications so SAP becomes discoverable and sensitivity-aware.

## The SAP sources this covers
This solution stands up the SAP connector workflow. The specific SAP source types offered, their
supported versions, and their exact configuration are **evolving** in Microsoft Purview — every
capability below is flagged "verify your licensing/tenant". Microsoft has historically documented SAP
source connectors including **SAP ECC**, **SAP S/4HANA**, **SAP BW**, and **SAP HANA**. **Confirm the
current list, supported versions, and driver requirements for your tenant** in Microsoft's
documentation and the Purview registration UI before you plan.

1. **SAP ECC / SAP S/4HANA / SAP BW** — Purview reaches these application systems over **RFC** using
   the **SAP Connector (SAP JCo — the Java Connector, `sapjco3.jar` + `sapjco3.dll`)** installed on
   the scanning machine, plus a **64-bit Java runtime**. The scan authenticates with an **SAP user**
   (username/password) whose secret is stored in **Azure Key Vault** and referenced **by name**, then
   reads **metadata** (the data dictionary — tables, structures, fields) and applies **classifications**
   (system classifications plus any custom classification you define).
2. **SAP HANA** — Purview connects to the HANA database with the **SAP HANA JDBC driver (`ngdbc.jar`)**
   on the scanning machine, again authenticating with a Key-Vault-referenced database login and
   enumerating schemas/tables/columns for classification.

> **Metadata, not bulk data extraction.** These SAP scans read the **catalog/metadata** (system,
> tables, fields) and sample to classify — they map and classify SAP; they are not a data-export tool.

## The Data Map, collections, and roles
SAP sources register into the **Data Map** under a **collection** hierarchy that also carries access
control. Each collection carries its own role assignments: **Collection admins** (manage the
collection and its roles), **Data source admins** (register sources and run scans), **Data curators**
(edit catalog metadata and classifications), and **Data readers** (browse the catalog).
Least-privilege role assignment is a first-class step, not an afterthought — the Implementation Guide
names each role at each stage.

## Credentials, drivers, and network — safe by design
Scanning reaches into a live SAP system, so it needs a driver path, a least-privilege SAP login, and
network line of sight — never a secret in a script. This solution follows the safe-by-design pattern
Microsoft documents:

- **The scan runs on a self-hosted integration runtime (SHIR).** SAP systems are almost always
  behind the corporate network, so the Azure (managed) runtime cannot reach them — a **SHIR** installed
  on a Windows machine with **line of sight to SAP** is required (**verify** the current runtime
  requirement for your connector).
- **The SAP driver is provided by you, from SAP.** The **SAP JCo** libraries (for ECC/S4HANA/BW) and
  the **SAP HANA JDBC driver** (for HANA) are downloaded from the **SAP Support Portal under your SAP
  license** (an S-user) and placed on the SHIR machine with a supported **Java runtime**. These are
  **SAP's** deliverables under **your** SAP entitlement — the solution documents where they go and how
  to verify them; it does not (and cannot) ship SAP's drivers.
- **Authentication uses a least-privilege SAP login held in Azure Key Vault, referenced by name.**
  The SAP username/password is stored in an **Azure Key Vault** linked to the Purview account and
  referenced as a Purview credential **by name** — **no SAP secret is ever placed in a script or
  document.**
- Scans are always **piloted on a bounded scope first** (one SAP system/client, a scoped set of
  tables).

## Licensing and the evolving portal
Microsoft Purview Data Governance (the Data Map and its connectors) is billed through a
**consumption / pay-as-you-go** model tied to an **Azure subscription**, and the capability set is
evolving — the **SAP** connectors, the supported SAP versions, the driver/runtime requirements, and
the exact configuration may be in preview or may have changed name, path, or availability. **Verify
current pricing, availability, supported versions, driver requirements, and portal paths for your
tenant** in Microsoft's documentation and the Purview portal before you plan. This solution cites the
method; it never asserts a price, a driver version, or a portal path as permanent.

## What this is not
This is the *SAP data-source governance* solution. It is **not** the full Data Map / Unified Catalog
build, and it is **not** the Microsoft 365 compliance configuration (sensitivity/retention labels,
DLP, insider risk) — those are separate Purview solutions in this category. It complements them by
pulling SAP into the same governed map.

## The deployment model
> Assess SAP readiness (connector availability, SHIR, drivers, SAP login, network), design the
> collection and role model and the driver/credential path, configure the SAP source registration,
> **pilot scanning on a bounded scope** (one system/client, a scoped table set), validate the results
> against the gate, then expand across the SAP estate — moving scans from one-time to scheduled only
> after the pilot passes. The repeatable way: **Assess → Design → Configure → Pilot → Validate →
> Expand.**
