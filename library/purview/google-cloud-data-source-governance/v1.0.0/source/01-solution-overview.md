# 1. Solution Overview — Google Cloud Data-Source Governance: Microsoft Purview

## What this solution is
Microsoft Purview has two related but distinct sides. The **compliance** side (labels, DLP,
retention, insider risk) governs Microsoft 365 content. This solution implements a focused slice of
the **data governance** side: **registering, scanning, and classifying your Google Cloud data into
the Purview Data Map**, so Google Cloud data stops being a governance blind spot and becomes a
mapped, classified, cataloged part of your estate. It does not re-implement the whole Data Map /
Unified Catalog build; it delivers the **Google Cloud source connector workflow** end-to-end:
register the source, prove the service-account trust/credential path, run a bounded pilot scan,
review classifications, then expand.

> **Boundary.** This solution provides the technical method to *register, scan, classify, and
> catalog* Google Cloud sources. It does **not** make the business or regulatory determinations —
> which data is "confidential", what the retention or records schedule is, or who may access it —
> those belong to the organization's data owners, stewards, compliance, privacy, and legal
> functions. The solution gives them governed, discoverable Google Cloud data to make those
> decisions against.

## Why this matters
Most organizations govern Microsoft 365 well and their Google Cloud estate not at all. Analytics
land in a BigQuery dataset, an application replicates a customer table into a warehouse, an analyst
materializes an extract — and none of it appears in the data map. Nobody can answer "is there PII in
our BigQuery datasets?", "which tables hold regulated data?", or "who owns this dataset?" — because
Google Cloud data was never registered, scanned, or classified. Ungoverned data is un-securable
data: you cannot protect, retain, or grant access to something you cannot see. This solution brings
Google Cloud into the same Purview Data Map that already governs the rest of the estate.

## The Google Cloud source this covers
The documented Google Cloud data source in the Microsoft Purview Data Map is **Google BigQuery** —
Google Cloud's managed data warehouse. This solution stands up the **Google BigQuery** connector
workflow end-to-end. Availability of specific multicloud connectors and their exact configuration is
**evolving** in Microsoft Purview — every capability below is flagged "verify your
licensing/tenant", and any additional Google Cloud source types you need (beyond BigQuery) must be
**confirmed as registerable in your tenant** before you plan for them rather than assumed.

**Google BigQuery** — projects, datasets, tables, and views. Purview connects to BigQuery using a
**Google Cloud service account**: you create a service account in the project, grant it **read-only**
BigQuery access, and generate a **service-account key**. The key's **private key** is stored in an
**Azure Key Vault** linked to the Purview account and referenced **by name** — no key material is ever
placed in a script or document. Scanning enumerates projects, datasets, tables, and views and applies
**classifications** (system classifications such as credit-card or national-ID number, plus any custom
classification you define).

## The Data Map, collections, and roles
Google Cloud sources register into the **Data Map** under a **collection** hierarchy that also
carries access control. Each collection carries its own role assignments: **Collection admins**
(manage the collection and its roles), **Data source admins** (register sources and run scans),
**Data curators** (edit catalog metadata and classifications), and **Data readers** (browse the
catalog). Least-privilege role assignment is a first-class step, not an afterthought — the
Implementation Guide names each role at each stage.

## Credentials and network — safe by design
Scanning reaches into live Google Cloud systems, so it needs a trust path and network line of sight
— never a secret in a script. This solution follows the safe-by-design pattern Microsoft documents:

- **Google BigQuery** authenticates with a **Google Cloud service account**. You generate the
  service-account key in Google Cloud, then store its **private key** in an **Azure Key Vault** linked
  to the Purview account and register it as a Purview credential **by name** (for example
  `DGGCP-Cred-BQ-KV`). **No key material is stored in a script or document.**
- BigQuery scans run through a **self-hosted integration runtime (SHIR)** — a machine you control with
  network line of sight to Google Cloud and the **BigQuery JDBC driver prerequisites** installed
  (historically a **Java Runtime Environment / JDK**; **verify the current driver and Java
  prerequisites** for your tenant). The SHIR is where the scan executes.
- Scans are always **piloted on a bounded scope first** (one project / one or two datasets) before any
  estate-wide scan.

## Licensing and the evolving portal
Microsoft Purview Data Governance (the Data Map and its multicloud connectors) is billed through a
**consumption / pay-as-you-go** model tied to an **Azure subscription**, and the capability set is
evolving — the **Google BigQuery** connector, the exact service-account/credential configuration, and
the SHIR/driver prerequisites may be in preview or may have changed name, path, or availability.
**Verify current pricing, availability, required GCP IAM roles, and portal paths for your tenant** in
Microsoft's documentation and the Purview portal before you plan. This solution cites the method; it
never asserts a price, a GCP project ID, or a portal path as permanent.

## What this is not
This is the *Google Cloud data-source governance* solution. It is **not** the full Data Map / Unified
Catalog build, and it is **not** the Microsoft 365 compliance configuration (sensitivity/retention
labels, DLP, insider risk) — those are separate Purview solutions in this category. It complements
them by pulling Google BigQuery into the same governed map.

## The deployment model
> Assess Google Cloud readiness (project, service account, connector availability, SHIR/network),
> design the collection and role model and the service-account/credential path, configure the Google
> Cloud source registration, **pilot scanning on a bounded scope** (one project / a couple of
> datasets), validate the results against the gate, then expand across the Google Cloud estate —
> moving scans from one-time to scheduled only after the pilot passes. The repeatable way:
> **Assess → Design → Configure → Pilot → Validate → Expand.**
