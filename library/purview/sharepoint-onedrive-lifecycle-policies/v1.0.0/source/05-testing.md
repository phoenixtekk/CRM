# 5. Testing Guide — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to observe real retention behavior on a pilot site. Validate on `SPO Lifecycle – Pilot Scope –
Stage1` in **retain-only** mode before enabling any deletion or expanding.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `DLCSPO-Check-Prereqs.ps1`.
**Expected:** ExchangeOnlineManagement present and connected; Records Management / Compliance
Administrator role reported; the retention and adaptive-scope signals reported; existing policies listed.
Every gap (e.g. adaptive scopes unavailable → static scoping) is **recorded, not guessed**.

## Test 2 — Discovery inventory is complete
**Do:** Run `DLCSPO-Discover.ps1`.
**Expected:** Every retention policy and rule is listed with whether it covers **SharePoint** and/or
**OneDrive**, its **period and action** (retain / retain-then-delete / delete), and any adaptive scopes —
matching what the Purview portal shows under Data Lifecycle Management.

## Test 3 — Create dry-run makes no changes
**Do:** Run `DLCSPO-Set-RetentionPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -RetainDays 2555 -WhatIf`.
**Expected:** It states the policy/rule/scope it *would* create (retain-only) plus the reverse action and
changes nothing; a follow-up `Get-RetentionCompliancePolicy` shows no new policy until `-Commit`.

## Test 4 — Policy exists, retain-only, scoped to the pilot
**Do:** After `-Commit`, run `Get-RetentionCompliancePolicy -Identity "SPO-OneDrive Retention - Policy"`
and `Get-RetentionComplianceRule`.
**Expected:** The policy exists, covers exactly the pilot locations (SharePoint and/or OneDrive as
designed), the rule retains for the intended period, and **no delete action** is enabled.

## Test 5 — Retained content cannot be permanently removed before its period
**Do:** On a pilot site, delete a test document, then check the site's **Preservation Hold Library**.
**Expected:** A copy of the deleted document is preserved in the Preservation Hold Library — retention is
protecting the content; nothing is lost mid-window. (Verify the hold-library behavior against current
Microsoft guidance.)

## Test 6 — Validation gate passes on the pilot (retain-only)
**Do:** Run `DLCSPO-Validate.ps1`.
**Expected:** PASS for each gate — the policy exists, covers the intended locations, the period matches
design, and **no unintended delete action** is enabled. Any FAIL names the specific issue.

## Test 7 — Enable-delete dry-run makes no changes and is reversible
**Do:** Run `DLCSPO-Set-RetentionPolicy.ps1 -Action EnableDelete -RetainDays 2555 -WhatIf`.
**Expected:** The dry-run states it *would* switch the rule to **retain-then-delete** plus the reverse
action (back to retain-only) and changes nothing; a follow-up `Get-RetentionComplianceRule` shows the
rule unchanged.

## Test 8 — Deletion behaves as designed (deliberate, after approval)
**Do:** Only after retain-only is validated and approved: enable delete with `-Commit`, then verify the
rule's action.
**Expected:** The rule is **retain-then-delete** for the intended period; content will be deleted only
**after** its period elapses (not immediately). Deletion after the window is irreversible — this is why it
is enabled deliberately.

## Test 9 — Scope is exactly what was intended
**Do:** In the portal, review the policy's locations (and any adaptive-scope rule) against
`Lifecycle Schedule – Map`.
**Expected:** The covered SharePoint sites / OneDrive accounts match the intended scope precisely — no
site is missed, and none is over-retained by accident.

## Test 10 — Reporting evidence is produced
**Do:** Run `DLCSPO-Report.ps1 -CsvPath .\LifecycleReport.csv`.
**Expected:** `Lifecycle – Coverage Report` lists each policy/rule, its SharePoint/OneDrive locations,
period, and action — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `SPO Lifecycle – Pilot Scope – Stage1` — policy present and retain-only, retained
content held in the Preservation Hold Library, scope exactly as intended, and the coverage report produced
— before enabling deletion or expanding to the estate. Deletion is enabled only as a deliberate, approved
step; any deferred (licensing-gated) capability is recorded explicitly, not silently skipped.
