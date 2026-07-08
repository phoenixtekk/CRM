# 1. Solution Overview — Oracle Data Governance: Microsoft Purview

## What this solution is
Microsoft Purview has two related but distinct sides. The **compliance** side (labels, DLP,
retention, insider risk) governs Microsoft 365 content. This solution implements a focused slice of
the **data governance** side: **registering, scanning, and classifying your Oracle databases into the
Purview Data Map**, so Oracle data stops being a governance blind spot and becomes a mapped,
classified, cataloged part of your estate. It does not re-implement the whole Data Map / Unified
Catalog build; it delivers the **Oracle-source connector workflow** end-to-end: register the source,
prove the credential and network path, run a bounded pilot scan, review classifications, then expand.

> **Boundary.** This solution provides the technical method to *register, scan, classify, and catalog*
> Oracle sources. It does **not** make the business or regulatory determinations — which data is
> "confidential", what the retention or records schedule is, or who may access it — those belong to the
> organization's data owners, stewards, compliance, privacy, and legal functions. The solution gives
> them governed, discoverable Oracle data to make those decisions against.

## Why this matters
Many organizations govern Microsoft 365 well and their Oracle estate not at all. A customer master
lives in an Oracle schema, an ERP or a line-of-business application runs on Oracle, a data-warehouse
staging schema holds regulated extracts — and none of it appears in the data map. Nobody can answer
"is there PII in our Oracle databases?", "which schemas hold regulated data?", or "who owns this
database?" — because Oracle data was never registered, scanned, or classified. Ungoverned data is
un-securable data: you cannot protect, retain, or grant access to something you cannot see. This
solution brings Oracle into the same Purview Data Map that already governs the rest of the estate.

## How Purview reaches Oracle
Oracle databases are commonly on-premises or in a private network, so this connector is built around a
**self-hosted integration runtime (SHIR)** and a **credential referenced from Azure Key Vault by
name** — never a secret in a script. Availability and the exact configuration of the Oracle connector
are **evolving** in Microsoft Purview; every capability below is flagged "verify your
licensing/tenant".

1. **The source** — Purview registers an **Oracle** data source in the Data Map by its **host** and
   **service name** (or SID) and default listener **port `1521`** (verify your instance's port). One
   Purview source represents one Oracle server/service; a scan enumerates its **schemas → tables →
   columns**.
2. **Authentication** — Purview connects with **Basic authentication**: a least-privilege Oracle
   database login whose password is stored in an **Azure Key Vault** linked to the Purview account and
   referenced **by name**. **No credential is ever placed in a script or document.** (Verify the
   current supported authentication methods for the Oracle connector in your tenant.)
3. **Network + driver** — because Oracle typically sits behind a firewall, scanning runs through a
   **self-hosted integration runtime (SHIR)** installed on a machine with network line of sight to the
   Oracle listener. The SHIR machine historically requires the **Oracle JDBC driver** to be present for
   the scanner (place the `ojdbc` driver where Microsoft's current docs specify) — **verify whether
   your SHIR version bundles it or requires a manual driver install.** A managed VNet runtime may be an
   option for cloud-reachable instances — verify.
4. **Classification** — a scan applies **system classifications** (credit card, national ID, and the
   large built-in set) plus any **custom classification rule** you define in the scan rule set. Purview
   can also surface **lineage** from Oracle where supported — verify.

## The Data Map, collections, and roles
Oracle sources register into the **Data Map** under a **collection** hierarchy that also carries
access control. Each collection carries its own role assignments: **Collection admins** (manage the
collection and its roles), **Data source admins** (register sources and run scans), **Data curators**
(edit catalog metadata and classifications), and **Data readers** (browse the catalog).
Least-privilege role assignment is a first-class step, not an afterthought — the Implementation Guide
names each role at each stage.

## Credentials and network — safe by design
Scanning reaches into a live Oracle system, so it needs a credential and network line of sight — never
a secret in a script. This solution follows the safe-by-design pattern Microsoft documents:

- The Oracle login's secret is stored in an **Azure Key Vault** linked to the Purview account and
  referenced **by name** — no password in code, in a scan definition, or in a document.
- The database login is **least-privilege and read-only**: `CREATE SESSION` plus `SELECT` on the
  schemas/objects in scope and the data-dictionary views the scanner reads (verify the exact grant list
  in Microsoft's current Oracle-connector documentation). It is not a DBA account.
- Scans reach Oracle through a **self-hosted integration runtime (SHIR)** with line of sight to the
  listener; scans are always **piloted on a bounded scope first** (one database/a few schemas).

## Licensing and the evolving portal
Microsoft Purview Data Governance (the Data Map and its connectors) is billed through a **consumption /
pay-as-you-go** model tied to an **Azure subscription**, and the capability set is evolving — the
**Oracle** connector, its supported Oracle versions, the driver requirement, the supported
authentication methods, and the exact scan configuration may be in preview or may have changed name,
path, or availability. **Verify current pricing, availability, supported versions, and portal paths for
your tenant** in Microsoft's documentation and the Purview portal before you plan. This solution cites
the method; it never asserts a price, a version, or a portal path as permanent.

## What this is not
This is the *Oracle data-source governance* solution. It is **not** the full Data Map / Unified Catalog
build, and it is **not** the Microsoft 365 compliance configuration (sensitivity/retention labels,
DLP, insider risk) — those are separate Purview solutions in this category. It complements them by
pulling Oracle into the same governed map.

## The deployment model
> Assess Oracle readiness (account, roles, connector availability, credential, SHIR/network, driver),
> design the collection and role model and the credential path, configure the Oracle source
> registration, **pilot-scan a bounded scope** (one database / a few schemas), validate the results
> against the gate, then expand across the Oracle estate — moving scans from one-time to scheduled only
> after the pilot passes. The repeatable way: **Assess → Design → Configure → Pilot → Validate →
> Expand.**
