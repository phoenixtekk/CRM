# 1. Solution Overview — Business Glossary & Stewardship Program (Microsoft Purview)

## What this solution is
Microsoft Purview has two related but distinct sides. The **compliance** side (sensitivity labels,
DLP, retention, insider risk) governs Microsoft 365 content. This solution works on the **data
governance** side — specifically the **business glossary** and the **stewardship program** that sit
inside the Purview **Unified Catalog**. It gives your data *shared meaning* (agreed business terms
and critical data elements) and *named owners* (data owners and data stewards), wrapped in a
**workflow** so terms are proposed, reviewed, approved, and kept current rather than defined once and
forgotten. It is the human-and-metadata layer that makes a data estate usable by the business, not
just visible to IT.

> **Boundary.** This solution provides the technical method to *stand up a glossary, define
> stewardship roles and workflows, assign owners, and keep terms current* in Microsoft Purview. It
> does **not** make the business, regulatory, or records determinations — *what a term officially
> means*, *which data is "confidential"*, *what the retention or records schedule is*, or *who may
> access what*. Those belong to the organization's data owners, stewards, compliance, privacy, and
> legal functions. The solution gives them the governed structure to record and enforce those
> decisions; it never invents the decision.

## Why this matters
"Customer", "active account", "revenue", "churn" — ask five teams and you get five definitions.
Finance counts a customer one way, Sales another, Support a third. Reports disagree, dashboards
contradict each other, and nobody can say which number is right because nobody owns the term. Left
unaddressed this is both a **compliance gap** (you cannot govern data whose meaning is contested) and
a **data-risk exposure** (decisions get made on numbers that mean different things). A business
glossary fixes the *meaning* problem; a stewardship program fixes the *ownership and upkeep* problem.
Together they turn a pile of ambiguous fields into a set of agreed, owned, maintained terms the whole
organization can trust.

## The four building blocks
This solution stands up four things in order. Each is named once in the Implementation Guide and
reused everywhere.

1. **Governance domain(s)** — the business grouping inside the Unified Catalog that a glossary and its
   stewards belong to (for example Finance, Sales, HR). A domain carries its own ownership and roles,
   so glossary curation is scoped and least-privilege.
2. **The business glossary** — the set of **terms** and **critical data elements (CDEs)**: each term
   has a name, an agreed definition, a **status** (Draft → Published → Expired), an **owner** and a
   **steward**, and — where useful — links to the data assets it describes. This is the shared
   dictionary of the business.
3. **The stewardship program** — the named **roles** and the **workflow** around the glossary:
   **governance domain owners**, **data owners**, and **data stewards** who propose, review, approve,
   publish, and periodically re-certify terms. Roles and an approval workflow are what keep the
   glossary alive instead of stale.
4. **Curation & upkeep cadence** — the recurring rhythm (review stale terms, re-certify Published
   terms, retire Expired ones, fill unowned gaps) that a steward runs, evidenced by the reporting
   script. Governance that is not maintained decays; the cadence is a first-class deliverable.

## Roles and least privilege
Curation in the Unified Catalog is organized by **governance roles** assigned at the **governance
domain** level: **governance domain owner** (owns the domain and its role assignments), **data
owner** (accountable for a term or data product), **data steward** (curates terms, definitions, and
status day to day), and **data reader** (browses the catalog). Collection-level roles in the Data Map
(**collection admin**, **data curator**) may also apply where the glossary links to scanned assets.
Least-privilege role assignment is an explicit step in the Implementation Guide, not an afterthought —
each role is named at the stage it is needed, and account-level administration is reserved for a
minimal named group.

## Pilot-first, simulation where available — safe by design
Glossary and stewardship changes are lower-blast-radius than DLP or retention enforcement (creating a
Draft term modifies no user data), but the same discipline applies: **pilot on a bounded domain and
a small agreed term set first**, keep new terms in **Draft** status until the owner approves, and only
then **Publish** and **expand** to further domains. The provided scripts are **read-only or `-WhatIf`
by default**; any write is gated behind an explicit `-Commit`, and **no secret is ever stored in a
script or document**.

## Licensing and the evolving portal
The **business glossary** and **Unified Catalog** are part of Microsoft Purview **Data Governance**,
which is billed through a **consumption / pay-as-you-go** model tied to an **Azure subscription**, and
the capability set is **actively evolving** — feature names (governance domains, data products, data
quality), portal paths, and the underlying data-plane API versions may have moved or may be in
preview. **Verify current availability, pricing, portal paths, and API versions for your tenant** in
Microsoft's documentation and in the Purview portal before you plan. This solution cites the method;
it never asserts a price, a portal path, or an API version as permanent.

## What this is not
This is the *shared-meaning and stewardship* solution. It is **not** the Microsoft 365 compliance
configuration (sensitivity/retention labels, DLP, records management), and it is **not** the full Data
Map / scanning build — those are separate Purview solutions in this category. It complements them: a
glossary term can be *linked* to scanned assets and to sensitivity classifications, but standing up
the estate-wide scan is out of scope here. This solution focuses squarely on giving terms meaning,
owners, and a workflow.

## The deployment model
> Assess readiness and the term landscape, design the domain / role / workflow model, configure the
> glossary and stewardship program, **pilot on a bounded domain with a small term set (terms in
> Draft)**, validate against the gate, then expand across domains — publishing broadly and enforcing
> the upkeep cadence only after the pilot passes. The repeatable way:
> **Assess → Design → Configure → Pilot (simulate/Draft) → Validate → Expand.**
