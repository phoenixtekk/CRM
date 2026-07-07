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
