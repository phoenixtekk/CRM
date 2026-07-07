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
