# 1. Solution Overview — AWS Data-Source Governance (S3/RDS): Microsoft Purview

## What this solution is
Microsoft Purview has two related but distinct sides. The **compliance** side (labels, DLP,
retention, insider risk) governs Microsoft 365 content. This solution implements a focused slice of
the **data governance** side: **registering, scanning, and classifying your AWS data — Amazon S3
buckets and Amazon RDS databases — into the Purview Data Map**, so AWS data stops being a governance
blind spot and becomes a mapped, classified, cataloged part of your estate. It does not re-implement
the whole Data Map / Unified Catalog build; it delivers the **AWS-source connector workflow**
end-to-end: register the source, prove the trust/credential path, run a bounded pilot scan, review
classifications, then expand.

> **Boundary.** This solution provides the technical method to *register, scan, classify, and catalog*
> AWS S3 and RDS sources. It does **not** make the business or regulatory determinations — which data
> is "confidential", what the retention or records schedule is, or who may access it — those belong to
> the organization's data owners, stewards, compliance, privacy, and legal functions. The solution
> gives them governed, discoverable AWS data to make those decisions against.

## Why this matters
Most organizations govern Microsoft 365 well and their AWS estate not at all. A copy of a customer
table lands in an S3 bucket, an application database runs on Amazon RDS, an analyst exports extracts
to another bucket — and none of it appears in the data map. Nobody can answer "is there PII in our S3
buckets?", "which RDS databases hold regulated data?", or "who owns this bucket?" — because AWS data
was never registered, scanned, or classified. Ungoverned data is un-securable data: you cannot
protect, retain, or grant access to something you cannot see. This solution brings AWS S3 and RDS
into the same Purview Data Map that already governs the rest of the estate.

## The two AWS sources this covers
This solution stands up the AWS connector workflow for two source types. Availability of specific
multicloud connectors and their exact configuration is **evolving** in Microsoft Purview — every
capability below is flagged "verify your licensing/tenant".

1. **Amazon S3** — object storage buckets. Purview reaches S3 by assuming a **cross-account AWS IAM
   role** you create: the role trusts Microsoft's Purview AWS account and is conditioned on an
   **external ID**, and it grants **read-only** access to the buckets in scope (plus **KMS decrypt**
   for encrypted buckets). Scanning enumerates objects and applies **classifications** (system
   classifications such as credit-card or national-ID number, plus any custom classification you
   define).
2. **Amazon RDS** — managed relational databases (the RDS engines Purview supports — **verify the
   current supported engine list for your tenant**, historically SQL Server and PostgreSQL). Purview
   connects with a **database credential referenced from Azure Key Vault by name** over a network path
   to the instance, enumerates databases/schemas/tables, and applies classifications the same way.

## The Data Map, collections, and roles
AWS sources register into the **Data Map** under a **collection** hierarchy that also carries access
control. Each collection carries its own role assignments: **Collection admins** (manage the
collection and its roles), **Data source admins** (register sources and run scans), **Data curators**
(edit catalog metadata and classifications), and **Data readers** (browse the catalog).
Least-privilege role assignment is a first-class step, not an afterthought — the Implementation Guide
names each role at each stage.

## Credentials and network — safe by design
Scanning reaches into live AWS systems, so it needs a trust path and network line of sight — never a
secret in a script. This solution follows the safe-by-design pattern Microsoft documents:

- **Amazon S3** uses a **role-based trust** (an AWS IAM role ARN + external ID) rather than a
  long-lived key; Purview assumes the role. The role ARN is referenced as a Purview credential **by
  name**; **no AWS secret is stored in a script or document**.
- **Amazon RDS** uses a **database credential stored in an Azure Key Vault** linked to the Purview
  account and referenced **by name** — again, no secret in code.
- Cloud-reachable sources are scanned through the **Azure (managed) integration runtime**; RDS
  instances in a private VPC require a **self-hosted integration runtime (SHIR)** (or managed VNet
  runtime — verify) with network line of sight. Scans are always **piloted on a bounded scope first**.

## Licensing and the evolving portal
Microsoft Purview Data Governance (the Data Map and its multicloud connectors) is billed through a
**consumption / pay-as-you-go** model tied to an **Azure subscription**, and the capability set is
evolving — the **Amazon S3** and **Amazon RDS** connectors, the supported RDS engines, and the exact
trust/credential configuration may be in preview or may have changed name, path, or availability.
**Verify current pricing, availability, supported engines, and portal paths for your tenant** in
Microsoft's documentation and the Purview portal before you plan. This solution cites the method; it
never asserts a price, an AWS account ID, or a portal path as permanent.

## What this is not
This is the *AWS data-source governance* solution. It is **not** the full Data Map / Unified Catalog
build, and it is **not** the Microsoft 365 compliance configuration (sensitivity/retention labels,
DLP, insider risk) — those are separate Purview solutions in this category. It complements them by
pulling AWS S3 and RDS into the same governed map.

## The deployment model
> Assess AWS readiness (account, roles, connector availability, network), design the collection and
> role model and the trust/credential path, configure the AWS source registration, **pilot scanning on
> a bounded scope** (a few buckets / one RDS database), validate the results against the gate, then
> expand across the AWS estate — moving scans from one-time to scheduled only after the pilot passes.
> The repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.**
