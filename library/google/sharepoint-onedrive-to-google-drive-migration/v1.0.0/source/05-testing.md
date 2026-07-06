# 5. Testing Guide — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Run these validation gates for **every** scope — first for Wave 0 (the pilot), then for each
expansion wave — before that wave is declared done. Each test confirms one part of the mapping
(files, permissions, sharing, structure, identity) worked for the wave's content. A wave does not
pass until its gate criteria are met. Use `GWDRIVE-Validation.ps1` for the per-item checks and
`GWDRIVE-Report.ps1` for coverage and exceptions.

## Test 1 — Discovery and mapping are complete
Do: Confirm every in-scope site/library/OneDrive in the wave has a named target in
`GWDRIVE Mapping - Content & Structure - Source to Target`, every source permission level has a role
in `GWDRIVE Mapping - Permissions - Level to Role`, and every discovered principal resolves in
`GWDRIVE Mapping - Identity - Source to Google`; run `GWDRIVE-Discovery.ps1`.
Expected: No in-scope scope, permission level, or principal is unmapped for the wave.

## Test 2 — Files migrated (content coverage)
Do: For the wave's scopes, compare source item/folder counts against the target; run
`GWDRIVE-Validation.ps1`.
Expected: Every source file and folder has a corresponding target item in the mapped Shared Drive / My
Drive; item counts reconcile within the tool's known exclusions, and no scope is empty.

## Test 3 — Permissions correct (roles preserved, not flattened)
Do: For a sample of items across each permission level, confirm the target Google role matches the
translated level in `GWDRIVE Mapping - Permissions - Level to Role`; run `GWDRIVE-Validation.ps1`.
Expected: Full Control → Manager, manage-content → Content manager, Contribute → Contributor,
read+comment → Commenter, read → Viewer — access intent preserved, nothing flattened to Viewer.

## Test 4 — No dropped principals
Do: For the sampled items, confirm every source grantee has a corresponding Google grant (no principal
was silently dropped for want of an identity mapping).
Expected: Every permission on the source item is present on the target item at the mapped role; any
dropped grant traces to a gap in the identity map, which is then closed.

## Test 5 — Sharing translated correctly
Do: Check the wave's shared items: direct grants, organization links, and anyone-with-the-link shares
against `GWDRIVE Mapping - Sharing - Link & Grant Rules`.
Expected: Direct grants map to Google permissions/membership; organization links map to domain sharing
at the matching role; anyone-with-the-link shares are translated only where policy allows and
otherwise down-scoped and flagged — no share is silently widened or lost.

## Test 6 — Structure preserved
Do: Spot-check folder hierarchy for a sample of migrated scopes.
Expected: Folder structure beneath each target root matches the source; nesting is within the Shared
Drive limit and no folders collapsed or re-parented incorrectly.

## Test 7 — Users can access their content
Do: Have a sample of wave users open their migrated content (team content in the Shared Drive, personal
content in My Drive) at their expected role.
Expected: Users can view/edit/manage per their mapped role; owners can manage Shared Drive members;
users are briefed that previously-hidden folders may appear greyed out (visibility change, not access).

## Test 8 — Coverage and exceptions reported
Do: Run `GWDRIVE-Report.ps1` for the wave.
Expected: The report shows content coverage (items migrated vs source), permission/sharing validation
pass rate, and an itemized exception list with no unresolved exceptions before the wave passes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Wave 0 (pilot) pass | Tests 1-8 pass; every exception is fixed in the **mapping artifact** (not just the item) before expanding |
| Expansion wave pass | Tests 1-8 pass for the wave; the exception list from `GWDRIVE-Report.ps1` is empty before the next wave starts |
| Migration complete | All waves passed, users confirmed access at mapped roles, and source content set read-only / decommissioned only after validation was clean |
