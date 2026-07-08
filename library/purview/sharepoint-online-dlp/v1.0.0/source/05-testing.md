# 5. Testing Guide — SharePoint Online DLP (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to generate representative activity on a pilot site — and the policy is in **test mode**, so no
real sharing is blocked. Validate on `SPO DLP – Pilot Sites – Stage1` before enforcing or expanding.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `DLPSPO-Check-Prereqs.ps1`.
**Expected:** ExchangeOnlineManagement present and connected; the DLP/compliance role reported; the DLP
capability signal reported; existing policies listed. Every gap (e.g. an advanced classifier unavailable →
deferred) is **recorded, not guessed**.

## Test 2 — Discovery inventory is complete
**Do:** Run `DLPSPO-Discover.ps1`.
**Expected:** Every DLP policy and rule is listed with whether it covers **SharePoint** and/or
**OneDrive**, each policy's **mode** (test/enforce), and the available **sensitive information types** —
matching the Purview portal.

## Test 3 — Create dry-run makes no changes
**Do:** Run `DLPSPO-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotSites "https://contoso.sharepoint.com/sites/PilotSite" -SensitiveTypes "Credit Card Number" -WhatIf`.
**Expected:** It states the policy/rule/scope it *would* create (test mode) plus the reverse action and
changes nothing; a follow-up `Get-DlpCompliancePolicy` shows no new policy until `-Commit`.

## Test 4 — Policy exists in test mode, scoped to the pilot
**Do:** After `-Commit`, run `Get-DlpCompliancePolicy -Identity "SPO-OneDrive DLP - Policy"` and
`Get-DlpComplianceRule`.
**Expected:** The policy exists, covers exactly the pilot locations (SharePoint and/or OneDrive as
designed), its rule matches the intended sensitive info type + sharing condition, and the mode is
**test** (e.g. TestWithoutNotifications) — enforcing nothing.

## Test 5 — The rule matches the intended sensitive content
**Do:** Upload a test document containing the sensitive info type (e.g. a fake credit-card number in the
correct format) to a pilot site.
**Expected:** The DLP reports / Activity Explorer show a **match** for the document in test mode — the
policy detects the content it was designed to detect.

## Test 6 — The sharing condition is evaluated
**Do:** Share the matching test document **externally** from a pilot site.
**Expected:** In test mode the policy records what it **would** restrict (and where a **policy tip** would
appear) for the external-sharing condition — without blocking the share.

## Test 7 — Validation gate passes on the pilot (test mode)
**Do:** Run `DLPSPO-Validate.ps1`.
**Expected:** PASS for each gate — the policy exists, covers the intended locations, the rule matches the
intended content/sharing condition, and the policy is in **test mode** (not prematurely enforcing). Any
FAIL names the specific issue.

## Test 8 — False positives are tuned out
**Do:** Review test-mode matches for legitimate documents that shouldn't match; add an **exception** or
tighten the condition; re-review.
**Expected:** After tuning, legitimate content no longer matches while the intended sensitive content
still does — an acceptable false-positive rate before enforcement.

## Test 9 — Enforce dry-run makes no changes and is reversible
**Do:** Run `DLPSPO-Set-DlpPolicy.ps1 -Action Enforce -WhatIf`.
**Expected:** The dry-run states it *would* switch the policy to **enforce** plus the reverse action (back
to test) and changes nothing; a follow-up `Get-DlpCompliancePolicy` shows the mode unchanged.

## Test 10 — Enforcement blocks as designed (deliberate, after approval)
**Do:** Only after validation and approval: enforce with `-Commit`, then attempt to share a matching
document externally from an in-scope site as a normal user.
**Expected:** The external share is **restricted/blocked** per the rule, the user sees the **policy tip**,
and an **admin alert** fires. An authorized/excepted case still works. (Verify against your configuration.)

## Test 11 — Reporting evidence is produced
**Do:** Run `DLPSPO-Report.ps1 -CsvPath .\SpoDlpReport.csv`.
**Expected:** `SPO DLP – Coverage Report` lists each policy/rule, its SharePoint/OneDrive locations, mode,
and match conditions — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `SPO DLP – Pilot Sites – Stage1` — policy present in test mode, matching the intended
content and sharing conditions with false positives tuned out, policy tips and alerts behaving as designed
— before moving to enforce or expanding. Enforcement is enabled only as a deliberate, approved step; any
deferred (licensing-gated) capability is recorded explicitly, not silently skipped.
