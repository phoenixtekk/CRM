# 2. Requirements Guide — Business Glossary & Stewardship Program (Microsoft Purview)

Meet these before starting the Implementation Guide. The six **category** prerequisites in
*Global Requirements — Microsoft Purview Solutions* (tenant/licensing, least-privilege roles, the
PowerShell/Graph toolchain, in-scope data, compliance/records/privacy/legal stakeholders, and a pilot
scope with change control) apply in full and are **not** repeated here. Below are the prerequisites
**specific to standing up a business glossary and stewardship program**, each with *what it is*,
*why it matters*, *how to verify*, and *how to implement if missing*.

> **Determinations are deferred.** Every requirement below is about the *technical and organizational
> readiness* to run a glossary. The **official meaning** of a term, whether a data element is a
> regulated/critical data element, and any records or legal implication of a definition are set by the
> business data owners, compliance, records, privacy, and legal — not by this solution.

---

## R1. Microsoft Purview Data Governance (Unified Catalog) available in your tenant
- **Description:** The **Purview Data Governance** experience — the **Unified Catalog** with
  **governance domains** and the **business glossary** — must be available and enabled for your
  tenant, tied to an **Azure subscription** for its consumption billing.
- **Why it matters:** The glossary and stewardship roles live in the Unified Catalog; without it there
  is nowhere to create governance domains, terms, or governance-role assignments.
- **How to verify:** In the **Microsoft Purview portal** (purview.microsoft.com) confirm the
  **Unified Catalog** / **Data Governance** experience loads and that you can open **Governance
  domains** and **Glossary**. Confirm an Azure subscription is associated for billing. Because the
  experience is evolving, **verify current availability and naming for your tenant**.
- **How to implement if missing:** Enable Purview Data Governance and associate an Azure subscription
  per Microsoft's current onboarding documentation before starting.

## R2. Governance-role assignments (least privilege) for glossary curation
- **Description:** The least-privilege **governance roles** the program needs: **governance domain
  owner** (owns the pilot domain and its role assignments), **data owner** (accountable for terms),
  **data steward** (day-to-day curation), and **data reader** (browse). Where the glossary links to
  scanned assets, **collection admin** / **data curator** in the Data Map may also apply.
- **Why it matters:** Curation is gated by governance role at the domain scope; the right person needs
  the matching least-privilege role and nothing more.
- **How to verify:** In the Unified Catalog, open the target **governance domain → Roles** and confirm
  the named people hold domain owner / data owner / steward as intended.
- **How to implement if missing:** Assign the least-privilege governance roles at the **narrowest**
  scope (the pilot domain) under change control; reserve any account/tenant admin for a minimal group.

## R3. A named stewardship model — owners, stewards, and an approval workflow
- **Description:** A documented **stewardship model** for the pilot: who **owns** each term (data
  owner), who **stewards** it (data steward), and the **workflow** by which a term moves Draft →
  reviewed → approved → **Published**, plus a **re-certification cadence** for keeping terms current.
- **Why it matters:** A glossary without named owners and an upkeep workflow goes stale within weeks;
  the program *is* the roles and the workflow, not just the term list.
- **How to verify:** Confirm a written RACI (owner vs steward vs approver) for the pilot domain and an
  agreed review cadence (for example, re-certify Published terms quarterly).
- **How to implement if missing:** Agree the owner/steward/approver mapping and the cadence with the
  business data owners before configuring workflows. *The determination of who is the authoritative
  owner of a business concept is the business's, not this solution's.*

## R4. A pilot governance domain and a small agreed term set (Critical Data Elements)
- **Description:** One **pilot governance domain** (for example `DGGLOSS-Domain-Pilot`, such as
  Finance) and a **small agreed list of 5–10 terms / critical data elements (CDEs)** to seed the
  glossary — each with a proposed name and definition to review.
- **Why it matters:** The pilot proves the whole cycle (propose → review → approve → publish → report)
  on a bounded, high-value set before scaling; CDEs are where shared meaning matters most.
- **How to verify:** Confirm the pilot domain is chosen and that the 5–10 candidate terms with draft
  definitions are captured (a spreadsheet or list is enough to start).
- **How to implement if missing:** Work with the pilot domain's data owner to select the 5–10 most
  contested or highest-value terms and draft their candidate definitions before configuring.

## R5. Data-plane access for the automation (Purview REST via Azure sign-in — no secrets)
- **Description:** A workstation with the **Az PowerShell** modules (`Az.Accounts`) and an admin
  account that can sign in with **`Connect-AzAccount`** and hold at least **data reader** (and, for
  the configuration script, **data steward / governance domain owner**) on the pilot domain. The
  scripts acquire a **Purview data-plane token** at runtime — **no secret is stored in code**. (The
  category toolchain requirement — Security & Compliance PowerShell / Graph — still applies for
  neighboring Purview work; the glossary automation specifically uses the Purview data-plane REST.)
- **Why it matters:** The provided Discovery, Scope, Configuration, Validation, and Reporting scripts
  call the Purview data-plane REST API using a token acquired from your interactive sign-in.
- **How to verify:** `Connect-AzAccount` succeeds, and `Get-AzAccessToken -ResourceUrl
  https://purview.azure.net` returns a token; the Purview portal shows your role on the pilot domain.
- **How to implement if missing:** Install `Az.Accounts` (`Install-Module Az.Accounts -Scope
  CurrentUser`), confirm modern-auth/MFA sign-in, and confirm your governance role before running any
  write step. **Verify the current Purview data-plane API versions for your tenant** — they evolve.

## R6. Change control and a stale-term policy for the upkeep cadence
- **Description:** A lightweight **change-control** path for publishing/retiring terms and an agreed
  **stale-term policy** (for example, a Published term not re-certified within *N* months is flagged
  for review and may be set **Expired**).
- **Why it matters:** Publishing a term is an outward-facing act (the business will rely on it); an
  agreed review/retire policy keeps the glossary trustworthy over time and gives the reporting script a
  gate to measure against.
- **How to verify:** Confirm an approval path for publishing/retiring terms and a written re-certify
  interval.
- **How to implement if missing:** Agree the approval path and the stale-term interval with the data
  owners and compliance before Publishing beyond the pilot.

---

*Everything above is technical and organizational readiness. The **authoritative meaning** of any
term, whether an element is a regulated critical data element, and any records/legal consequence of a
definition remain with the business data owners, compliance, records, privacy, and legal — this
solution provides the structure to record and operate their decisions, never the decision itself.*
