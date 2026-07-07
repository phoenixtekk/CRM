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
