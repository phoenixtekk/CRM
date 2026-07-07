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
