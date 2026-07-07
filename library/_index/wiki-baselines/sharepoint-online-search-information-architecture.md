# SharePoint Online Search & Information Architecture

> **Version 1.0.0** · Category: SharePoint · Solution code: SPOSEARCH

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — SharePoint Online Search & Information Architecture

**Outcome.** Content in SharePoint Online becomes reliably findable: the right document or page surfaces
on the first page of results, users can filter by meaningful attributes (department, document type), a
dedicated tab exists for high-value categories, and known-item searches jump straight to the
authoritative answer. Fewer "I can't find it" tickets, less reliance on emailed copies, and measurably
faster time-to-content.

**Approach.** Findability is fixed in the correct order — **information architecture first, search schema
second, search experience third** — and delivered with the house model **Assess → Design → Configure →
Pilot → Validate → Expand**:
- **Metadata & content types:** a small, governed set of term sets and enterprise content types
  (`Content Type – Policy Document – Prod`) so content is described consistently tenant-wide.
- **Search schema:** crawled properties mapped to reusable refinable managed properties with friendly
  aliases (`Department`, `DocType`) and the right searchable/queryable/retrievable/refinable flags.
- **Search experience:** scoped **result sources**, a **vertical** (a Policies tab), and **promoted
  results / bookmarks** for known-item queries — configured on the Microsoft Search surface where users
  actually start.
- **Automation:** five PowerShell tools (SharePoint Online Management Shell / PnP / Graph) for assessment,
  schema mapping, source/vertical/bookmark configuration, findability validation, and ongoing health.

**Why it is low-risk.** Everything is proven on a named **pilot** scope with explicit pass/fail gates
before any tenant-wide change. Every tenant-level schema change is preceded by a captured **rollback
baseline** (a full search-config export) and made in a change window. The scripts are **safe-by-default**
— read-only or `-WhatIf` unless an explicit commit switch is passed, modern-auth only, no stored
credentials. Search reflects existing permissions (it never grants access), and all
compliance/records/legal determinations remain with those functions. Plan- and cloud-dependent behavior
(content-type gallery vs hub, Microsoft Search availability, Government-cloud URLs) is flagged to verify
in-tenant rather than assumed.

**What you receive.** A solution overview, a requirements guide, an implementation runbook with named
artifacts and gates, testing and troubleshooting guides, best practices, and the five PowerShell tools —
enough for a competent M365 administrator to run the engagement end to end for a fraction of the cost of
bespoke consulting.


---


# 1. Solution Overview — SharePoint Online Search & Information Architecture

## What this solution is
When users say "I can't find anything in SharePoint," the fix is almost never "buy more SharePoint" —
it is *search tuning on a sound information architecture (IA)*. Microsoft Search and classic SharePoint
search only surface what the content is *described* as: the metadata on it, the content types that
carry that metadata, and the **search schema** that decides which of that metadata is searchable,
queryable, retrievable, and refinable. This solution is a repeatable method to establish the metadata
and content-type layer, tune the search schema and managed properties, stand up result sources,
verticals, and promoted results, and validate that the *right* content surfaces fast — using the
SharePoint admin center, the Search admin center, managed metadata, and PowerShell (SharePoint Online
Management Shell / PnP PowerShell / Microsoft Graph). No third-party search product is required.

## Why this matters
- Search is the single most-used feature in SharePoint, and the first thing users blame. Poor
  findability quietly pushes people back to email attachments and local copies — the failure mode the
  intranet was meant to end.
- Search quality is *downstream of IA*. If content has no consistent metadata (department, document
  type, owner, status) there is nothing for the schema to refine or filter on, so results stay a flat,
  relevance-only list. Metadata first, schema second, experience third.
- The knobs that actually move findability — **managed property mappings**, **searchable / queryable /
  retrievable / refinable** flags, **result sources**, **verticals**, and **promoted results /
  bookmarks** — are tenant- and site-collection-level settings that are easy to get wrong and, once
  wrong, silently degrade every query. This solution makes those changes deliberate, named, piloted,
  and reversible.
- A one-time "fix search" project regresses as new sites, libraries, and content types appear without
  metadata discipline. The durable value is the schema + governance pattern, not a single sweep.

## How it works
1. **Crawling** — SharePoint continuously crawls tenant content. Each column/field on an item becomes a
   **crawled property** (e.g. a `Department` site column surfaces as a crawled property like
   `ows_Department`). Crawled properties are raw and, by default, not individually queryable or
   refinable.
2. **The search schema** maps **crawled properties → managed properties**. A managed property is the
   named, typed handle search actually uses. Each managed property has attributes:
   - **Searchable** — its text is included in the full-text index (matches a free-text query).
   - **Queryable** — it can be targeted by name in a query (`Department:Finance`).
   - **Retrievable** — its value can be returned in results (shown in a card / custom result).
   - **Refinable** — it can drive a refiner/filter on a results page (sort/filter by it).
   - **Sortable** — results can be ordered by it.
   Out of the box, tenant-level managed properties are read-only; you map metadata onto the built-in,
   reusable **`RefinableString00…`, `RefinableDate00…`, `RefinableInt00…`** aliases (and set an
   **alias** so queries use a friendly name).
3. **Managed metadata & content types** feed the schema. A **term set** (e.g. Department, Document Type)
   defines the controlled vocabulary; **site columns** bound to those term sets carry it; **content
   types** bundle those columns so every library applies them consistently. Published from a central
   content-type gallery / hub, they give the whole tenant the same crawled properties to map.
4. **Result sources** scope *where* results come from (e.g. only a Policies hub, only documents of a
   given content type) using a query transform. **Verticals** are the tabs on the Microsoft Search /
   results page (All, Files, Sites, plus custom ones like "Policies") — each backed by a result source.
5. **Promoted results / bookmarks** pin an authoritative answer to the top for known queries (e.g.
   searching "VPN" always surfaces the IT VPN page). In Microsoft Search these are **Bookmarks**;
   classic query rules can also promote results within a site.
6. **The Microsoft Search experience** (the search box in the M365 app bar, Office.com, and SharePoint
   home) presents verticals, bookmarks, acronyms, and Q&A tenant-wide. This solution tunes that surface
   so answers appear where users start.
7. **Validation** runs representative **test queries** and confirms the target content is found, the
   managed property is returned/refinable, and the vertical and bookmark behave — before expanding
   tenant-wide.

## The reference design
- A central **content-type gallery** publishes a small, governed set of enterprise content types
  (`Content Type – Policy Document – Prod`, `Content Type – Contract – Prod`) each carrying term-set-bound
  site columns (`Site Column – Department`, `Site Column – DocType`, `Site Column – Owner`).
- Those site columns surface as crawled properties, mapped to refinable managed properties with friendly
  aliases (`RefinableString00` → alias `Department`, `RefinableString01` → alias `DocType`).
- A **Policies result source** and a **Policies vertical** give users a dedicated, scoped tab; **bookmarks**
  pin authoritative answers for high-volume known-item queries.
- Everything is proven on a **pilot hub / site set** with pass/fail gates and a documented rollback
  (schema export, source/vertical/bookmark removal) before tenant-wide expansion.

## What you can control
- Which term sets and content types are in scope (start with the highest-value: policies, contracts, HR).
- Which crawled properties map to which refinable managed properties, and their alias names.
- Which result sources and verticals exist, and the query transform that scopes each.
- Which known-item queries get promoted results / bookmarks.
- The pilot scope validated first, before any tenant-wide schema or Microsoft Search change.

## Limitations (be honest with buyers)
- **Reindex latency.** Changing a managed property mapping does not retro-apply until the affected content
  is **re-crawled/re-indexed**. You can force a reindex per library/site (Advanced settings → Reindex),
  but tenant-scale reindex takes time — plan for hours-to-days, not minutes, before refiners populate.
- **Refinable managed properties are a finite, typed pool** (`RefinableString00–199`, `RefinableDate`,
  `RefinableInt`, etc.). Track allocations so two teams don't map different metadata to the same alias.
- **Tenant-level schema is global.** A mapping made at the tenant Search admin center affects every site;
  site-collection-level schema (`/_layouts/15/listmanagedproperties.aspx`) is narrower but only overrides
  where allowed. Change tenant-level schema under change control.
- **Managed metadata / content-type publishing** (content-type gallery vs the legacy Content Type Hub) is
  **plan- and rollout-dependent** — confirm which your tenant exposes; the steps flag "verify in your
  tenant" where Microsoft is mid-transition.
- **Government clouds (GCC High / DoD)** use different portal URLs (`*.sharepoint.us` /
  `*-admin.sharepoint.us`, `*.office365.us`) and some Microsoft Search features roll out later — verify
  availability in your cloud.
- **Compliance/records determinations** (which content is a record, retention labels, information barriers)
  are **deferred** to your compliance/records/legal functions — this solution makes content *findable*, it
  does not decide what content must be *retained or restricted*.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across
the docs, scripts, admin centers, and search schema.

| Artifact | Name |
|---|---|
| Department term set | `Term Set – Department – Prod` |
| Document-type term set | `Term Set – DocType – Prod` |
| Department site column | `Site Column – Department` |
| Document-type site column | `Site Column – DocType` |
| Enterprise policy content type | `Content Type – Policy Document – Prod` |
| Enterprise contract content type | `Content Type – Contract – Prod` |
| Managed property alias (Department) | `Department` (on `RefinableString00`) |
| Managed property alias (DocType) | `DocType` (on `RefinableString01`) |
| Policies result source | `Result Source – Policies – Prod` |
| Policies search vertical | `Search Vertical – Policies – Prod` |
| Known-item bookmark | `Bookmark – VPN Access – Prod` |
| Pilot site set | `Pilot Site – Findability – Pilot` |
| Findability assessment export | `Findability Assessment – Tenant – Discovery` |
| Findability validation report | `Findability Validation – Pilot – Validation` |

## The standard deployment model
> Assess current metadata/schema/findability → design the IA + schema map → configure metadata, content
> types, managed properties, sources/verticals/bookmarks → prove it on a **pilot** hub/site → validate with
> test queries against pass/fail gates → expand tenant-wide.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first, with a documented
> rollback for every tenant-level change.


---


# 2. Requirements — SharePoint Online Search & Information Architecture

These are the **solution-specific** prerequisites for tuning SharePoint Online search and information
architecture. They build **on top of** the shared SharePoint-category prerequisites in
**`global-requirements-sharepoint.md`** (M365 tenant + SharePoint/OneDrive licensing; least-privilege
SharePoint admin access; SPO Management Shell / PnP / Graph toolchain; an IA & identity source of truth;
a pilot scope + change control; and security/compliance/records stakeholders). Verify those six first,
then confirm the search-and-IA–specific items below. Each: **Description / Why / Verify / Implement if
missing.**

## 1. Search Administrator access (Search admin center)
- **Description:** An account with **Search Administrator** (or SharePoint Administrator / Global
  Administrator, which include it) able to open the **Microsoft Search & Intelligence admin center**
  (`admin.microsoft.com` → Settings → Search & intelligence) and the SharePoint **Search admin center**
  (`https://<tenant>-admin.sharepoint.com` → More features → Search).
- **Why required:** Tenant-level managed properties, result sources, verticals, and Microsoft Search
  bookmarks/verticals are configured only with the search-admin surfaces.
- **How to verify:** Sign in and confirm the "Search & intelligence" node and the SPO admin "Search"
  page load without an access error. In Government clouds the URLs are `*-admin.sharepoint.us` /
  `admin.microsoft.us` — **verify in your tenant**.
- **How to implement if missing:** Have a Global Admin assign **Search Administrator** (Entra role) under
  change control; use the least-privilege role that covers the scope you are changing.

## 2. Managed metadata service & term-store contributor rights
- **Description:** The **Managed Metadata Service** application (term store) is provisioned, and you have
  **Term Store Administrator** (or Group Manager/Contributor on the relevant term group) to create the
  Department and Document-Type term sets.
- **Why required:** The controlled vocabularies (`Term Set – Department – Prod`, `Term Set – DocType – Prod`)
  that drive consistent metadata — and therefore refinable managed properties — live in the term store.
- **How to verify:** Open the SharePoint admin center → **Content services → Term store**; confirm the
  term store loads and your account appears as an admin/contributor.
- **How to implement if missing:** In Term store, add your account as a Term Store Administrator (or the
  taxonomy owner grants Group Manager on the working term group).

## 3. Content-type publishing surface (gallery / hub) confirmed
- **Description:** The mechanism your tenant uses to publish enterprise content types across sites —
  the modern **content type gallery** (SharePoint admin center → Content services → Content type gallery)
  and/or the legacy **Content Type Hub** (`/sites/contentTypeHub`).
- **Why required:** Enterprise content types (`Content Type – Policy Document – Prod`,
  `Content Type – Contract – Prod`) must publish tenant-wide so every library produces the same crawled
  properties to map.
- **How to verify:** In the SharePoint admin center confirm **Content type gallery** is present; check
  whether a legacy Content Type Hub site also exists. Microsoft is mid-transition between the two —
  **verify which your tenant exposes** before authoring content types.
- **How to implement if missing:** Use the content type gallery if present; otherwise enable/locate the
  Content Type Hub. Decide one publishing path and record it before creating content types.

## 4. A defined findability intent (the IA + query inventory)
- **Description:** A short, agreed statement of **what users need to find** and **how they search for it**:
  the top content domains (policies, contracts, HR, projects), the metadata that describes them, and a list
  of representative **known-item and exploratory test queries**.
- **Why required:** Managed-property mappings, result sources, verticals, and bookmarks are only "right"
  relative to real queries; the test-query inventory is also the validation instrument (§5 Testing).
- **How to verify:** Confirm a documented list of priority content domains, the metadata each carries, and
  10–20 representative test queries with the expected top result for each.
- **How to implement if missing:** Interview content owners and the service desk (top search terms,
  top "I can't find X" tickets); capture the query inventory before configuring. This is a design input,
  not a compliance determination.

## 5. Refinable managed-property allocation register
- **Description:** A simple register of which reusable **refinable** managed properties
  (`RefinableString00–199`, `RefinableDate00…`, `RefinableInt00…`, `RefinableDecimal00…`) are already in
  use and which are free.
- **Why required:** The refinable pool is finite and typed; mapping two different site columns to the same
  alias corrupts refiners tenant-wide. A register prevents collisions.
- **How to verify:** Export the current search schema (`Get-PnPSearchConfiguration -Scope Subscription`, or
  the Search admin center "Managed Properties" list) and record which refinables already carry a mapping/alias.
- **How to implement if missing:** Run the discovery script (`Get-SearchIAAssessment.ps1`) to enumerate
  current managed properties and their mappings; seed the register from its output.

## 6. A pilot hub/site set with representative content
- **Description:** A **named pilot scope** — a hub or a small set of site collections
  (`Pilot Site – Findability – Pilot`) that contains real, representative content and can absorb a forced
  reindex without disrupting the tenant.
- **Why required:** Schema, source/vertical, and bookmark changes must be proven on real content and
  re-indexed there first; a pilot lets you validate refiners populate and queries return correctly before
  tenant-wide schema changes (which reindex everything).
- **How to verify:** Confirm the pilot sites exist, carry the target content types/metadata, and that a
  reindex there is acceptable in the change window.
- **How to implement if missing:** Designate the pilot sites, apply the content types/metadata to their key
  libraries, and agree the change window before configuring the schema.

## 7. Reindex / change window and rollback baseline
- **Description:** An agreed **change window** for tenant-level schema changes (which trigger a full
  reindex over time) and a captured **rollback baseline** — an export of the current search configuration
  before any change.
- **Why required:** Tenant-level managed-property and result-source changes are high-impact and take time to
  propagate; you must be able to revert to the pre-change schema.
- **How to verify:** Confirm `Get-PnPSearchConfiguration -Scope Subscription -Path .\SearchConfig-Baseline.xml`
  produces a baseline file and it is stored with the change record.
- **How to implement if missing:** Capture the baseline export (the discovery/health scripts do this) and
  schedule the change window before applying tenant-level schema changes.


---


# Global Requirements — SharePoint Online & OneDrive Solutions

These requirements apply to **every** solution in the **SharePoint** category (SharePoint Online
architecture & provisioning, external sharing, OneDrive for Business, migration to SPO, permissions,
search, and records/retention). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every SharePoint solution).** The **SharePoint admin center**, the
> **Microsoft 365 admin center**, the **SharePoint Online Management Shell** and **PnP PowerShell**,
> and **Microsoft Graph** are authored at exact, current click-by-click / cmdlet detail from Microsoft's
> public documentation. Where a capability, setting, or portal path is **plan- or version-dependent**
> (storage limits, sharing controls, Syntex/records features, Commercial vs Government cloud), it is
> **cited or flagged "verify in your tenant"** — never invented. **Third-party migration and governance
> tools** (e.g. ShareGate, Migration Manager, AvePoint) are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (SPO Management Shell / PnP /
> Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with SharePoint Online / OneDrive and licensing
- **Description:** A Microsoft 365 tenant with **SharePoint Online** and **OneDrive for Business** and
  the licensing the capability requires (e.g. an E-plan for advanced records/retention, Syntex where used).
- **Why required:** All site, sharing, OneDrive, and records configuration depends on the right plan.
- **How to verify:** In the M365 admin center confirm the SharePoint/OneDrive subscription and add-ons.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Administrative access (least-privilege SharePoint roles)
- **Description:** Access with the least-privilege role the solution names — typically **SharePoint
  Administrator** (and Global Administrator only where genuinely required, e.g. tenant-wide sharing).
- **Why required:** Tenant/site settings, sharing, provisioning, and records changes require the role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. SharePoint Online Management Shell / PnP + Graph toolchain
- **Description:** A workstation with the **SharePoint Online Management Shell** and/or **PnP
  PowerShell** (and Graph PowerShell where used), modern-auth / MFA-capable admin sign-in (PnP app
  registration where required).
- **Why required:** Configuration, automation, and the provided scripts run through SPO/PnP/Graph.
- **How to verify:** `Connect-SPOService` / `Connect-PnPOnline` succeeds; modules installed.
- **How to implement if missing:** Install the modules; register the PnP app where needed; confirm sign-in.

## 4. Information architecture & identity/group source of truth
- **Description:** A defined **information-architecture** intent (hub/site structure, taxonomy) and the
  identity/group source (Entra ID groups, M365 Groups backing team sites) that drives access.
- **Why required:** Provisioning, permissions, search, and governance key off the IA and groups.
- **How to verify:** Confirm the intended hub/site structure and which groups model is authoritative.
- **How to implement if missing:** Define the IA and group model (often the Architecture solution) first.

## 5. A pilot scope and change control
- **Description:** A **pilot site collection / hub / user set** to validate on before tenant-wide
  rollout, and a **change-control** process for production changes (sharing, permissions, retention,
  migration cutover are high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; tenant-wide sharing/permission/retention changes are high-impact.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

## 6. Security, compliance & records stakeholders
- **Description:** Engagement with the **security, compliance/records, and data-governance** stakeholders
  whose policies the configuration must satisfy (external sharing, permissions, retention/records,
  sensitivity).
- **Why required:** Sharing, permission, and records settings must align to enterprise policy.
- **How to verify:** Confirm the applicable policies and named approvers.
- **How to implement if missing:** Identify the owners and capture requirements before configuring governance.

*The deployment model across every SharePoint solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (SPO Management Shell / PnP / Graph) — never with
hardcoded credentials or secrets in code.*


---


# 3. Implementation — SharePoint Online Search & Information Architecture

Follow the house deployment model: **Assess → Design → Configure → Pilot → Validate → Expand**,
pilot-first, with explicit pass/fail gates and a documented rollback. Every artifact is named
`<Purpose> – <Scope> – <Stage>` (see Overview) and reused verbatim in later steps, testing,
troubleshooting, and the scripts. Navigation is given as both admin-center paths **and** PowerShell.

> **Connections used throughout.**
> - SharePoint Online Management Shell: `Connect-SPOService -Url https://<tenant>-admin.sharepoint.com`
> - PnP PowerShell (schema, metadata, content types, queries): `Connect-PnPOnline -Url https://<tenant>-admin.sharepoint.com -Interactive` (or `-Url https://<tenant>.sharepoint.com/sites/<site>` for site-scoped work).
> - Modern auth / MFA only; **no stored credentials**. Government cloud: substitute `*.sharepoint.us` / `*-admin.sharepoint.us` and `-AzureEnvironment USGovernment` where applicable — **verify in your tenant**.

---

## Stage 0 — Assess (read-only)

**Goal:** capture the current metadata, content-type, and search-schema state, and a rollback baseline.

1. **Run the assessment.** From the toolchain workstation:
   ```
   .\Get-SearchIAAssessment.ps1 -AdminUrl https://<tenant>-admin.sharepoint.com `
       -OutputPath .\Findability-Assessment-Tenant-Discovery.json
   ```
   This enumerates term groups/term sets, published content types, site columns, and the current
   managed-property → crawled-property mappings (with searchable/queryable/retrievable/refinable flags).
   Save the export as **`Findability Assessment – Tenant – Discovery`**.
2. **Capture the rollback baseline** of the search schema:
   ```
   Get-PnPSearchConfiguration -Scope Subscription -Path .\SearchConfig-Baseline.xml
   ```
   Store `SearchConfig-Baseline.xml` with the change record — this is the tenant-level rollback artifact.
3. **Seed the refinable register** (Requirements §5) from the assessment output: list which
   `RefinableString/Date/Int` slots already carry a mapping/alias, and which are free.

**Gate 0 (pass/fail):** you have (a) a saved assessment, (b) a tenant schema baseline export, and (c) a
refinable-allocation register. If any is missing, do not proceed.

---

## Stage 1 — Design

**Goal:** decide the metadata, the schema map, and the search experience before touching production.

1. **Choose the priority content domains** from the findability intent (Requirements §4) — e.g. Policies,
   Contracts.
2. **Define the metadata:** two term sets to start — `Term Set – Department – Prod`,
   `Term Set – DocType – Prod` — plus the site columns `Site Column – Department`, `Site Column – DocType`,
   `Site Column – Owner`.
3. **Define the content types:** `Content Type – Policy Document – Prod`, `Content Type – Contract – Prod`,
   each including the three site columns above.
4. **Plan the schema map** using free slots from the register:
   | Site column (crawled property) | Managed property | Alias | Flags to set |
   |---|---|---|---|
   | `Site Column – Department` (`ows_Department`) | `RefinableString00` | `Department` | Queryable, Retrievable, Refinable |
   | `Site Column – DocType` (`ows_DocType`) | `RefinableString01` | `DocType` | Queryable, Retrievable, Refinable |
   | `Site Column – Owner` (`ows_Owner`) | `RefinableString02` | `DocOwner` | Queryable, Retrievable |
   > Exact crawled-property names appear only **after** the content is first crawled with the column
   > populated (Stage 3.2). Confirm the real `ows_*` name in the assessment before mapping.
5. **Plan the experience:** `Result Source – Policies – Prod` (scoped to the Policies content), a
   `Search Vertical – Policies – Prod` backed by it, and the first bookmarks (e.g. `Bookmark – VPN Access – Prod`).
6. **Record the plan** and get change-control approval for the tenant-level steps.

**Gate 1:** the metadata list, content-type list, schema map (with confirmed free refinable slots), and
experience plan are documented and approved.

---

## Stage 2 — Configure metadata & content types

**Goal:** create the vocabulary and content types so libraries produce consistent crawled properties.

1. **Create the term sets.** SharePoint admin center → **Content services → Term store** → your term group →
   **New term set** → name `Term Set – Department – Prod`; add terms (e.g. Finance, HR, IT, Legal). Repeat for
   `Term Set – DocType – Prod` (Policy, Contract, Procedure, Report). PowerShell (PnP):
   ```
   Connect-PnPOnline -Url https://<tenant>.sharepoint.com/sites/<taxonomy-site> -Interactive
   New-PnPTermGroup -Name "Enterprise IA" -ErrorAction SilentlyContinue
   New-PnPTermSet -TermGroup "Enterprise IA" -Name "Term Set – Department – Prod"
   Add-PnPTerm -TermGroup "Enterprise IA" -TermSet "Term Set – Department – Prod" -Name "Finance"
   ```
2. **Create the site columns** as **Managed Metadata** columns bound to the term sets. In the content type
   gallery / hub site: **Site settings → Site columns → Create** → type *Managed Metadata* →
   `Site Column – Department` → bind to `Term Set – Department – Prod`. Repeat for `Site Column – DocType`.
   Add `Site Column – Owner` (Person or single line of text). PnP: `Add-PnPField` / `Add-PnPTaxonomyField`.
3. **Create the content types** in the **content type gallery** (or Content Type Hub — **verify which your
   tenant uses**): **New content type** → `Content Type – Policy Document – Prod` (parent: Document) → add
   `Site Column – Department`, `Site Column – DocType`, `Site Column – Owner`. Repeat for
   `Content Type – Contract – Prod`. PnP: `Add-PnPContentType`, then `Add-PnPFieldToContentType`.
4. **Publish** the content types (content type gallery: **Publish**; Content Type Hub: content type →
   **Manage publishing → Publish**) so they propagate to subscribing sites.

**Gate 2:** term sets exist and are populated; site columns are bound to them; both content types include
the three columns and are **published**. Verify with the assessment script or `Get-PnPContentType`.

---

## Stage 3 — Configure the search schema (pilot scope first)

**Goal:** get real crawled properties and map them to refinable managed properties — proven on the pilot.

1. **Apply content types + populate metadata** on the pilot libraries in `Pilot Site – Findability – Pilot`:
   add `Content Type – Policy Document – Prod` to the policies library and tag a representative set of
   documents with Department/DocType/Owner values.
2. **Trigger a reindex of the pilot library** so the populated columns become crawled properties: library →
   **Settings → Library settings → Advanced settings → Reindex document library**. (Site-scope: Site
   settings → Search and offline availability → **Reindex site**.) Allow the crawl to complete (minutes to
   hours).
3. **Confirm the crawled properties exist.** Search admin center → **Manage Search Schema → Crawled
   Properties** → search for `Department` / `DocType` and note the exact `ows_*` names. Or re-run
   `Get-SearchIAAssessment.ps1` and read the crawled-property list.
4. **Map crawled → managed properties** with the config helper (dry-run first, then commit within the change
   window):
   ```
   # Dry-run (default is -WhatIf; shows the intended mappings/aliases, changes nothing)
   .\Set-ManagedPropertyMapping.ps1 -AdminUrl https://<tenant>-admin.sharepoint.com `
       -MappingCsv .\schema-map.csv -WhatIf

   # Apply (explicit)
   .\Set-ManagedPropertyMapping.ps1 -AdminUrl https://<tenant>-admin.sharepoint.com `
       -MappingCsv .\schema-map.csv -Commit
   ```
   `schema-map.csv` lists each crawled property, the target refinable managed property, the alias, and the
   flags from the Stage-1 map (e.g. `ows_Department,RefinableString00,Department,Queryable;Retrievable;Refinable`).
   Equivalent manual path: Search admin center → **Manage Search Schema → Managed Properties** → open
   `RefinableString00` → **Add a mapping** to the crawled property → set **Alias** `Department` and check
   *Queryable / Retrievable / Refinable*.
   > Set the mapping at **site-collection scope** for the pilot first
   > (`/_layouts/15/listmanagedproperties.aspx`) where possible; promote to **tenant scope** only in Stage 6.
5. **Reindex again** so the new mappings take effect on the pilot content.

**Gate 3:** for the pilot content, the assessment/validation shows `Department` and `DocType` mapped with
Queryable + Retrievable + Refinable set, and their crawled properties identified. If the crawled property
never appears, the column was not populated or the reindex has not completed — do not map blindly.

---

## Stage 4 — Configure result sources, verticals & promoted results (pilot)

**Goal:** give users a scoped Policies tab and pin authoritative answers.

1. **Create the result source** `Result Source – Policies – Prod`. Search admin center →
   **Manage Result Sources → New Result Source** → Protocol: *Local SharePoint*, Type: *SharePoint Search
   Results*, **Query Transform**:
   `{searchTerms} ContentTypeId:0x0101...* Path:https://<tenant>.sharepoint.com/sites/policies*`
   (scope by the Policies content type ID and/or the Policies hub path). Or use the config helper:
   ```
   .\Set-SearchSourceVertical.ps1 -AdminUrl https://<tenant>-admin.sharepoint.com `
       -ConfigJson .\search-experience.json -WhatIf      # dry-run
   .\Set-SearchSourceVertical.ps1 -AdminUrl https://<tenant>-admin.sharepoint.com `
       -ConfigJson .\search-experience.json -Commit       # apply
   ```
2. **Create the vertical** `Search Vertical – Policies – Prod`. **Microsoft Search & Intelligence admin
   center → Customizations → Verticals → Add** → name it, set the **content source = SharePoint**, and set a
   **query** that scopes to policies (e.g. `ContentType:"Policy Document"` using the published content type),
   then **enable** it. This adds a *Policies* tab on the Microsoft Search results page.
   > Classic **site-level** search verticals/result-source scoping differ from **Microsoft Search** verticals;
   > this solution configures the Microsoft Search vertical for the tenant-wide experience and, optionally,
   > a site-scoped result source for a hub's own search box — **confirm which surface your users start from.**
3. **Create promoted results / bookmarks.** Microsoft Search & Intelligence admin center → **Answers →
   Bookmarks → Add** → `Bookmark – VPN Access – Prod` → title, URL (the authoritative IT VPN page), and
   **keywords** (`vpn`, `remote access`, `work from home`). Set state to **Published** (or Test in the pilot).
   For a single site's classic search, an equivalent is a **Query Rule → Promoted Result** on that site.

**Gate 4:** `Result Source – Policies – Prod` returns only policy content for a test query; the
`Search Vertical – Policies – Prod` tab appears and lists policies; `Bookmark – VPN Access – Prod` appears
above results for its keywords (in Test/pilot state).

---

## Stage 5 — Validate (pilot)

**Goal:** prove findability against the test-query inventory before tenant-wide changes.

1. Run the validation script against the pilot:
   ```
   .\Test-Findability.ps1 -SiteUrl https://<tenant>.sharepoint.com/sites/policies `
       -QueryCsv .\test-queries.csv -OutputPath .\Findability-Validation-Pilot-Validation.json
   ```
   `test-queries.csv` holds each query, the expected top result URL, and the managed property to check is
   returned/refinable. The report is **`Findability Validation – Pilot – Validation`**.
2. Work the pass/fail table in **§5 Testing**. Every priority known-item query must return its expected
   result on the first page; refiners for `Department`/`DocType` must populate; the Policies vertical and the
   bookmark must behave.

**Gate 5 (expansion gate):** all priority test queries pass, refiners populate, vertical + bookmark work,
and no regression in general search on the pilot. Only then expand. If a gate fails, **roll back** (Stage 7
rollback) or fix and re-validate — do not expand.

---

## Stage 6 — Expand (tenant-wide)

**Goal:** roll the proven configuration to the tenant under change control.

1. **Promote the schema mappings to tenant scope.** In the change window, apply the same mappings at
   **tenant** scope (Search admin center → Manage Search Schema → Managed Properties, or
   `Set-ManagedPropertyMapping.ps1 -Scope Subscription -Commit`). This triggers a tenant-wide reindex over
   time — communicate the propagation window.
2. **Broaden content-type adoption.** Apply the published content types to the remaining priority libraries;
   populate metadata (or run a metadata-tagging campaign). Reindex those sites.
3. **Publish verticals & bookmarks tenant-wide.** Move `Search Vertical – Policies – Prod` and
   `Bookmark – VPN Access – Prod` from Test to **Published**; add the remaining bookmarks from the query
   inventory.
4. **Re-validate at tenant scope** with `Test-Findability.ps1` against a broader query set, and monitor with
   the health helper:
   ```
   .\Get-SearchHealthScope.ps1 -AdminUrl https://<tenant>-admin.sharepoint.com `
       -OutputPath .\Search-Health-Tenant.json
   ```
5. **Operationalize.** Schedule the health helper monthly; keep the refinable register current; require new
   content types to carry the standard site columns so new content is findable by default.

**Gate 6:** tenant-wide validation passes and the health report shows the mappings, sources, verticals, and
bookmarks present and consistent.

---

## Rollback (documented, every tenant-level change)

- **Schema:** re-import the baseline — `Set-PnPSearchConfiguration -Scope Subscription -Path .\SearchConfig-Baseline.xml`
  — or, in the Search admin center, remove the added mapping/alias from the managed property. Reindex.
- **Result source / vertical:** delete `Result Source – Policies – Prod` and `Search Vertical – Policies – Prod`
  in the admin centers (or set the vertical to disabled).
- **Bookmark / promoted result:** set `Bookmark – VPN Access – Prod` to Draft/Unpublished (or delete the
  query rule promoted result on the site).
- **Content types:** unpublish the content type; existing tagged content and its crawled properties remain but
  stop propagating.
Reindex latency applies to every rollback — allow propagation time before declaring the revert complete.


---


# 5. Testing & Validation — SharePoint Online Search & Information Architecture

Run these after Stage 3–4 on the pilot (Gate 5) and again after Stage 6 tenant-wide (Gate 6). Each test
has an explicit **pass/fail**. Automate the query tests with `Test-Findability.ps1`; do the experience
checks (verticals, bookmarks) in the UI. Remember **reindex latency** — if a test fails right after a
schema change, confirm the reindex/crawl has completed before treating it as a real failure.

## Test 1 — Metadata & content types are applied and populated
- **How:** Run `Get-SearchIAAssessment.ps1`; open a pilot library and confirm items carry Department/DocType/Owner.
- **Pass:** `Content Type – Policy Document – Prod` is present and published; pilot documents have
  Department and DocType values populated.
- **Fail:** content type missing/unpublished, or columns empty — return to Stage 2/3.1.

## Test 2 — Crawled properties exist
- **How:** Search admin center → Manage Search Schema → Crawled Properties (search `Department`), or read the
  assessment output.
- **Pass:** crawled properties for the Department and DocType columns (`ows_*`) exist.
- **Fail:** absent → the column was not populated or the reindex has not completed (Stage 3.2–3.3).

## Test 3 — Managed property mappings & flags
- **How:** `Test-Findability.ps1` reads the schema; or open `RefinableString00`/`01` in the Search admin center.
- **Pass:** `Department` (alias on `RefinableString00`) and `DocType` (on `RefinableString01`) are mapped to
  the correct crawled properties with **Queryable + Retrievable + Refinable** set.
- **Fail:** wrong crawled property, missing alias, or missing flag → re-run `Set-ManagedPropertyMapping.ps1`.

## Test 4 — Queryable: property-targeted query works
- **How:** In pilot search (or `Submit-PnPSearchQuery -Query 'DocType:Policy'`), query `Department:Finance`.
- **Pass:** results are restricted to items whose Department term is Finance.
- **Fail:** query ignored / returns everything → managed property not Queryable, or alias wrong (Test 3).

## Test 5 — Retrievable: value returned in results
- **How:** `Test-Findability.ps1` requests `-SelectProperties "Title,Department,DocType,Path"`; or inspect a
  result card configured to show DocType.
- **Pass:** the `Department`/`DocType` values are returned for matching items.
- **Fail:** blank values → managed property not Retrievable (Test 3).

## Test 6 — Refinable: refiners populate
- **How:** On the pilot results page, add a **Department**/**DocType** refiner (or check the refiner data in
  the query result groups).
- **Pass:** the refiner lists the distinct term values and filtering by one narrows results.
- **Fail:** no refiner values → property not Refinable, or content not yet reindexed after mapping (Stage 3.5).

## Test 7 — Known-item queries return the expected top result
- **How:** `Test-Findability.ps1 -QueryCsv .\test-queries.csv` runs each priority query and compares the top
  result to the expected URL.
- **Pass:** every priority known-item query returns its expected page/document on the first page.
- **Fail:** expected result missing/buried → check content-type scoping, add a bookmark/promoted result, or
  fix metadata on the target.

## Test 8 — Result source scopes correctly
- **How:** Query through `Result Source – Policies – Prod` (admin center test, or the vertical).
- **Pass:** only policy content is returned; non-policy content is excluded.
- **Fail:** unrelated content appears → the query transform (content-type ID / path) is too broad (Stage 4.1).

## Test 9 — Vertical appears and works
- **How:** Perform a search in the Microsoft Search box; select the **Policies** tab
  (`Search Vertical – Policies – Prod`).
- **Pass:** the Policies tab appears and lists only policy content.
- **Fail:** tab missing/empty → vertical disabled, wrong content source, or query scope wrong (Stage 4.2).

## Test 10 — Bookmark / promoted result fires
- **How:** Search the bookmark keyword (e.g. `vpn`).
- **Pass:** `Bookmark – VPN Access – Prod` appears above organic results for its keywords.
- **Fail:** absent → bookmark in Draft/Test, keyword mismatch, or not yet propagated (allow a few minutes).

## Test 11 — No regression in general search
- **How:** Run a set of common general queries before and after the change on the pilot.
- **Pass:** general relevance is unchanged or improved; nothing previously found is now missing.
- **Fail:** general results degrade → a tenant mapping/alias collision (check the refinable register), roll back.

## Test 12 — Rollback verified (pre-expansion)
- **How:** In a non-production or pilot check, confirm the baseline re-import restores prior schema
  (`Set-PnPSearchConfiguration -Scope Subscription -Path .\SearchConfig-Baseline.xml`) and vertical/bookmark
  removal works.
- **Pass:** rollback restores the pre-change state after reindex.
- **Fail:** baseline import errors → re-capture a clean baseline before proceeding to tenant scope.

**Overall pass criteria (Gate 5 / Gate 6):** Tests 1–11 pass on the pilot before expansion; Tests 3–11 pass
tenant-wide after expansion; the validation report `Findability Validation – Pilot – Validation` is saved
with the change record.


---


# 6. Troubleshooting — SharePoint Online Search & Information Architecture

Common failure modes and resolutions. The single most frequent root cause is **reindex latency** —
schema and metadata changes do not appear until the affected content is re-crawled. Confirm the crawl
has completed before treating any of the below as a real failure.

## A refiner shows no values (empty refiner)
- **Symptom:** a Department/DocType refiner appears but lists nothing, or the refiner never appears.
- **Likely causes / fixes:**
  1. **Property not Refinable** — open the managed property (`RefinableString00`) in the Search admin
     center and confirm **Refinable = Yes**; re-run `Set-ManagedPropertyMapping.ps1` if not.
  2. **Content not reindexed** — the mapping was set but the library/site has not been re-crawled. Force
     **Reindex document library / Reindex site** and wait for the crawl.
  3. **Metadata empty** — the documents have no Department/DocType value, so there is nothing to refine on.
     Populate the columns (Test 1) then reindex.

## A property-targeted query is ignored (`Department:Finance` returns everything)
- **Symptom:** scoping a query by a managed property has no effect.
- **Fix:** the property is **not Queryable** or the **alias** doesn't match. Confirm the alias
  (`Department`) is set on the mapped managed property and Queryable is checked; then query by the alias.

## A managed property returns blank values
- **Symptom:** results show no value for DocType even though the item is tagged.
- **Fix:** the property is **not Retrievable**. Set Retrievable on the managed property and reindex; verify
  with `Test-Findability.ps1 -SelectProperties`.

## The crawled property never appears in the schema
- **Symptom:** after mapping time, the `ows_Department` crawled property isn't listed.
- **Likely causes / fixes:**
  1. **Column not populated on any crawled item** — a crawled property is created only once content with
     that column populated is crawled. Tag at least one item and reindex.
  2. **Reindex not completed** — allow the crawl to finish; re-run `Get-SearchIAAssessment.ps1`.
  3. **Wrong column type** — a Managed Metadata column surfaces differently from a text column; confirm the
     exact crawled-property name in the admin center before mapping (don't guess the `ows_*` name).

## Mapping change "isn't taking effect"
- **Symptom:** you set a mapping but nothing changed.
- **Fix:** mappings apply only to content indexed **after** the change. **Reindex** the affected libraries/
  sites. At tenant scope this propagates over hours-to-days — communicate the window; don't re-apply the
  mapping repeatedly (that won't speed it up).

## Refiners/results regressed tenant-wide after a change
- **Symptom:** general search got worse, or an unrelated team's refiner broke.
- **Likely cause:** an **alias/refinable collision** — two different crawled properties mapped to the same
  refinable slot/alias. Check the **refinable-allocation register**, remove the conflicting mapping, and
  **roll back** with the baseline (`Set-PnPSearchConfiguration -Scope Subscription -Path SearchConfig-Baseline.xml`).
  Reindex.

## The Policies vertical (tab) doesn't appear
- **Symptom:** users don't see `Search Vertical – Policies – Prod`.
- **Likely causes / fixes:**
  1. **Vertical disabled / still in draft** — enable/publish it in the Search & Intelligence admin center.
  2. **Wrong surface** — Microsoft Search verticals appear on the Microsoft Search results page (app bar /
     Office.com / SharePoint home), **not** a classic site search box. Confirm where users start.
  3. **Query scope returns nothing** — the vertical's query (e.g. `ContentType:"Policy Document"`) matches no
     indexed content yet; confirm content is tagged and indexed (Tests 1–2).

## The result source returns unrelated content
- **Symptom:** `Result Source – Policies – Prod` includes non-policy items.
- **Fix:** the **query transform** is too broad. Tighten it with the exact content-type ID
  (`ContentTypeId:0x0101...*`) and/or the policies hub **path**; test in the admin center's result-source
  test pane.

## A bookmark / promoted result doesn't fire
- **Symptom:** searching the keyword doesn't surface `Bookmark – VPN Access – Prod`.
- **Likely causes / fixes:**
  1. **State is Draft/Test** — set the bookmark to **Published** (or ensure your account is in the Test
     audience).
  2. **Keyword mismatch** — add the exact terms users type (`vpn`, `remote access`); keywords are matched,
     not fuzzy-guessed.
  3. **Propagation delay** — allow a few minutes after publishing.
  4. **Classic vs Microsoft Search** — a site **query-rule promoted result** only fires on that site's
     classic search, not tenant Microsoft Search; use a Bookmark for the tenant experience.

## `Connect-PnPOnline` / `Connect-SPOService` fails or the schema export errors
- **Symptom:** connection or `Get-PnPSearchConfiguration` denied.
- **Likely causes / fixes:**
  1. **Insufficient role** — you need Search Administrator / SharePoint Administrator; confirm the role.
  2. **PnP app not registered** — some tenants require a registered PnP Entra app for interactive auth;
     register it (`Register-PnPManagementShellAccess`) or use the app registration your org mandates.
  3. **Wrong cloud URL** — Government clouds use `*-admin.sharepoint.us`; add `-AzureEnvironment USGovernment`
     where required. **Verify in your tenant.**

## Content types stopped propagating to sites
- **Symptom:** new sites don't get the standard content types.
- **Fix:** confirm the content type is **published** (content type gallery: Publish; Content Type Hub:
  Manage publishing → Publish) and, for the hub, that the content-type publishing timer job has run. Run
  `Get-SearchHealthScope.ps1` to list sites missing the content type.

## When to escalate to Microsoft
If crawled properties still don't appear or refiners stay empty long after confirmed reindex (days) with
populated metadata and correct mappings, open a Microsoft support case with the site URL, the managed/crawled
property names, and the timeline — this can indicate a service-side index issue rather than a configuration
error.


---


# 7. Best Practices — SharePoint Online Search & Information Architecture

Durable practices for sustained findability. These outlive the initial project; treat them as the
operating standard.

## Information architecture & metadata
- **Metadata before schema before experience.** Never tune the search schema for content that has no
  consistent metadata — you will refine on nothing. Fix the IA first.
- **Keep the controlled vocabulary small and governed.** A handful of high-value term sets
  (`Term Set – Department – Prod`, `Term Set – DocType – Prod`) used everywhere beats dozens of local,
  free-text columns. Assign a term-store owner and a change process.
- **Publish enterprise content types centrally.** Use the content type gallery / hub so every library
  produces the same crawled properties. Require new site templates to inherit the standard content types
  so new content is findable by default.
- **Make key metadata required (or defaulted)** on high-value libraries so documents can't be saved
  untagged. Untagged content is the number-one cause of empty refiners.

## Search schema discipline
- **Reuse the built-in refinable properties** (`RefinableString/Date/Int/Decimal`) with **aliases** —
  don't proliferate custom managed properties. Maintain the **refinable-allocation register** so two
  teams never map different metadata to the same alias (a silent, tenant-wide corruption).
- **Set only the flags you need.** Refinable/Sortable have index cost; mark a property Refinable only if a
  refiner/sort actually uses it. Retrievable + Queryable is enough for many properties.
- **Prefer site-collection scope for narrow needs; reserve tenant scope for genuinely global metadata.**
  Tenant-level changes reindex everything and affect every site.
- **Always keep a current schema baseline export** (`Get-PnPSearchConfiguration -Scope Subscription`) so
  any change is reversible.

## Change management & reindex
- **Pilot-first, always.** Prove mappings, sources, verticals, and bookmarks on `Pilot Site – Findability –
  Pilot` and pass the gates before tenant-wide schema changes.
- **Respect reindex latency.** After a mapping change, refiners and returned values populate only as content
  is re-crawled — hours to days at tenant scale. Communicate the propagation window; don't declare
  success (or failure) before the crawl completes.
- **Make tenant-level schema changes in a change window** with a captured baseline and a communicated
  rollback.

## Search experience
- **Scope result sources tightly** with content-type IDs and/or hub paths so a vertical returns only what it
  should. A "Policies" tab that also shows random documents erodes trust fast.
- **Bookmarks for known-item queries, verticals for exploration.** Pin authoritative answers
  (`Bookmark – VPN Access – Prod`) for high-volume, single-answer searches; use verticals for "browse a
  category" needs.
- **Curate bookmarks from real query data.** Seed from the service desk's top "can't find X" tickets and
  from Microsoft Search usage insights; retire bookmarks whose targets move or die.
- **Confirm where users actually start** (Microsoft Search box in the app bar / Office.com / SharePoint home
  vs a hub's own search) and configure that surface — the vertical/bookmark model differs between Microsoft
  Search and classic site search.

## Governance & sustainment
- **Run the health helper on a schedule** (`Get-SearchHealthScope.ps1`, monthly) to catch mapping drift,
  broken bookmark targets, and content types that stopped publishing.
- **Review the query inventory quarterly.** Findability needs change as the org and content change; refresh
  test queries and re-validate.
- **Keep documentation and the refinable register versioned** with the schema baseline, so the next admin
  inherits the map, not a mystery.

## Safety, boundaries & compliance
- **Automation is safe-by-default.** Scripts are read-only or `-WhatIf` unless an explicit `-Commit`/`-Apply`
  switch is passed; use modern-auth `Connect-*`; never store credentials or secrets in code.
- **Search reflects permissions — it does not grant them.** Making content findable does not change who can
  open it; security trimming still applies. Do not "fix findability" by loosening permissions.
- **Defer compliance/records determinations.** Which content is a record, its retention label, and any
  information-barrier restriction are decisions for the compliance/records/legal functions; this solution
  makes content findable, it does not decide what must be retained or restricted.
- **Verify plan-/cloud-dependent behavior in your tenant.** Content-type gallery vs Content Type Hub,
  Microsoft Search feature availability, and Government-cloud URLs (`*.sharepoint.us`, `*.office365.us`) vary
  — confirm, don't assume.


---


# 8. Deliverables Summary — SharePoint Online Search & Information Architecture

## Documentation
- **01 — Solution Overview:** how SPO/Microsoft Search works (crawling, the search schema, result
  sources/verticals, promoted results) and the IA that feeds it; the reference design, limitations, naming
  convention, and deployment model.
- **02 — Requirements:** solution-specific prerequisites (Search Administrator access, term-store rights,
  content-type publishing surface, findability intent + query inventory, refinable-property register, pilot
  scope, reindex/change window) building on the shared SharePoint global requirements.
- **03 — Implementation:** the ordered runbook — Assess → Design → Configure metadata/content types →
  Configure search schema → Configure result sources/verticals/bookmarks → Pilot → Validate → Expand — with
  every artifact named and explicit pass/fail gates plus a documented rollback.
- **05 — Testing & Validation:** twelve tests (metadata, crawled/managed properties, queryable/retrievable/
  refinable, known-item queries, result source, vertical, bookmark, no-regression, rollback) each with
  pass/fail.
- **06 — Troubleshooting:** common failure modes (empty refiners, mapping not taking effect, crawled property
  missing, vertical/bookmark not showing, alias collisions) and resolutions.
- **07 — Best Practices:** durable practices for IA, schema discipline, change/reindex management, the search
  experience, sustainment, and safety/compliance boundaries.
- **Executive Summary:** outcome, approach, and why it is low-risk.

## PowerShell scripts (5) — SharePoint Online Management Shell / PnP / Graph, safe-by-default
1. **`Get-SearchIAAssessment.ps1`** — *Discovery (read-only).* Enumerates term sets, published content types,
   site columns, and the current managed-property → crawled-property mappings with their flags; captures the
   tenant search-config **rollback baseline**. Produces `Findability Assessment – Tenant – Discovery`.
2. **`Set-ManagedPropertyMapping.ps1`** — *Configuration helper (`-WhatIf` by default).* Maps crawled →
   refinable managed properties with alias and searchable/queryable/retrievable/refinable flags from a CSV;
   dry-runs unless `-Commit` is passed; always exports a baseline first and re-imports the edited schema at
   the chosen scope.
3. **`Set-SearchSourceVertical.ps1`** — *Experience config helper (`-WhatIf` by default).* Creates scoped
   **result sources** and enumerates the **verticals** and **promoted results / bookmarks** to configure in
   the Microsoft Search & Intelligence admin center; dry-runs unless `-Commit` is passed.
4. **`Test-Findability.ps1`** — *Validation (read-only).* Runs the test-query inventory with
   `Submit-PnPSearchQuery`, checks each returns its expected top result and required managed properties, and
   writes `Findability Validation – Pilot – Validation` with a pass count (Gate 5 / Gate 6).
5. **`Get-SearchHealthScope.ps1`** — *Scope/health helper (read-only).* Reports content-type/metadata
   coverage across sites, confirms expected managed-property aliases exist in the tenant schema, and checks
   bookmark-target reachability — for scheduled monitoring and drift detection.

All scripts use modern-auth `Connect-*` (no stored credentials or secrets), default to read-only or
`-WhatIf`, and require an explicit `-Commit`/`-Apply` switch before any change.
