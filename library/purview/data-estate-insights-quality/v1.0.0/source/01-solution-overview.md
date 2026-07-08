# 1. Solution Overview — Data Estate Insights & Data Quality (Microsoft Purview)

## What this solution is
Once a data estate is mapped, scanned, and catalogued in Microsoft Purview, two questions remain:
*"how healthy is the estate as a whole?"* and *"can I trust the data inside it?"* This solution
delivers both. It stands up **Data Estate Insights** — the reporting and analytics layer that shows
the health of the governed estate (asset coverage, classification distribution, ownership coverage,
scan and glossary health) — and **Data Quality** in the Unified Catalog: **data-quality rules and
scoring** across the governed estate's critical data, so a data product carries a measurable quality
score, not just a classification.

> **Boundary.** This solution provides the technical method to *measure and report* estate health and
> data quality — configure insights/analytics, define data-quality rules, run scoring on a bounded
> scope, and read the results. It does **not** make the business or regulatory determinations: what a
> "critical data element" is, which quality threshold is acceptable, whether a low score is a
> compliance problem, or what remediation the business must take — those belong to the organization's
> **data owners, stewards, compliance, privacy, and legal** functions. The solution gives them a
> measured, evidenced estate to make those decisions against.

## Why this matters
A mapped and classified estate can still be full of data nobody trusts. A customer table has 12%
missing emails, a finance extract carries dates in three formats, an account-ID column has
duplicates, and a "gold" data product is quietly stale. Leaders cannot see this: they have no
single view of estate health and no quality score to point at. The result is a **compliance gap**
(you cannot evidence the health of the data you govern) and a **data-risk exposure** (decisions,
reports, and AI are built on data of unknown quality). This solution makes the estate's health and
quality **visible, scored, and defensible** — configured, piloted on a bounded scope, and validated.

## The two building blocks
This solution stands up two capabilities on top of an already-governed estate (a Purview account with
sources mapped, scanned, and curated into the Unified Catalog — see the *Data Governance: Data Map,
Scanning & Unified Catalog* solution if that foundation is not yet in place).

1. **Data Estate Insights** — the analytics/reporting layer over the governed estate. It aggregates
   what scanning and cataloguing produced into an estate-level picture: how many assets are known and
   scanned, the **classification distribution** (where the regulated data is), **ownership coverage**
   (assets with a named owner vs unowned), scan health, and glossary/data-product coverage. In the
   evolving Purview portal this appears as **reports / analytics / Health management** over the
   Unified Catalog; classic Purview called it **Data Estate Insights**. Names and paths are evolving —
   **verify current availability and portal paths for your tenant**.
2. **Data Quality** — the Unified Catalog capability that measures whether the data itself is fit for
   use. You bind **critical data elements** (the columns that matter) inside a **data product** to
   **data-quality rules**, run a **data-quality scan** that profiles and evaluates the data, and get a
   **quality score** per rule, per data asset, per data product, and rolled up per governance domain.
   Rules are grouped by **quality dimensions** Microsoft documents — for example **Completeness,
   Conformity, Consistency, Accuracy, Uniqueness/Validity, and Timeliness**. Data Quality is
   licensing-/consumption-dependent and parts may be in **preview** — **verify your licensing/tenant**.

## Governance domains, data products, and roles
Both capabilities are organized by the Unified Catalog's structure: **governance domains** (business
groupings), **data products** (curated, published sets of assets with an owner and a use purpose), and
the **critical data elements** inside them. Access uses least-privilege governance roles — for example
a **Data Governance / catalog reader** to view insights, a **governance domain owner** and **data
steward** to curate, and a **data-quality steward** to author and run data-quality rules. Global or
account-level roles are used only where account-level changes are required. Exact role names are
evolving — **verify current role names for your tenant**; the Implementation Guide names the
least-privilege role at each step.

## Data-quality scanning reads live data — safe by design
A data-quality scan **profiles and reads the actual data** in the bound source to evaluate the rules
(unlike a classification scan, which samples for pattern-matching). That has two consequences this
solution treats as first-class: **privacy** (the scan reads real values, so it runs least-privilege,
on a bounded scope, with the data owner's agreement) and **credentials** (the scan authenticates to
the live source via the Purview account's **managed identity** or an **Azure Key Vault**–stored
secret — **never a secret in a script or document**). Rules are always **validated on a bounded pilot
data product first**, and the score is reviewed with the owner before the estate is scored at scale.

## What a "pilot" means here
Data Quality does not *enforce* anything on the data — it **measures** it. So piloting means running
rules and scoring on **one bounded data product first**, in a **test/limited** scope: validate that
each rule matches the owner's intent, that the score is meaningful, and that the scan cost and runtime
are acceptable — *before* pointing data-quality scoring at the whole estate or scheduling it. Estate
Insights is read-only reporting, so it is safe to view at any time; the pilot discipline applies to
**data-quality rule authoring and scanning**, which consume compute and read live data.

## Licensing and the evolving portal
Data Estate Insights / analytics and Unified Catalog **Data Quality** are **licensing-/plan- and
consumption-dependent** (advanced Purview capabilities typically require **Microsoft 365 E5 / E5
Compliance** and/or **consumption billing on an Azure subscription**), and some features may be in
**preview**. The portal experience, feature names (Insights vs Analytics vs Health management), and
billing are **actively evolving**. This solution **cites the method and flags every capability
"verify your licensing/tenant"** — it never asserts a portal path, an API version, or a price as
permanent.

## What this is not
This is the *measure-and-report* solution for a governed estate. It is **not** the foundational Data
Map / scanning / cataloguing solution (that builds the estate this one measures), and it is **not** a
records, retention, DLP, or insider-risk configuration. It complements them: the estate is mapped and
classified elsewhere; this solution tells you **how healthy and how trustworthy** that estate is.

## The deployment model
> Assess the governed estate and readiness, design the insights and data-quality scope (domain, data
> product, critical data elements, rules), configure insights and author rules, **pilot data-quality
> scoring on a bounded data product**, validate the scores and the health picture against the gate,
> then expand across the estate — scheduling scoring only after the pilot passes. The repeatable way:
> **Assess → Design → Configure → Pilot (test) → Validate → Expand.**
