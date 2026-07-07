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
