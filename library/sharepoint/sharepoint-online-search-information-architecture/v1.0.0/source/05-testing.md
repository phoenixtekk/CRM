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
