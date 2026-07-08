# 5. Testing Guide — Sensitivity Labeling for Power BI & Microsoft Fabric (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to observe real behavior on labeled content. Validate on `Analytics Labels – Pilot Ring – Stage1`
/ the pilot workspace before treating the tenant as production-ready.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `IPPBI-Check-Prereqs.ps1`.
**Expected:** ExchangeOnlineManagement + MicrosoftPowerBIMgmt modules present and connected; Information
Protection Admin / Power BI Admin roles reported; the sensitivity-label and Power BI Pro/PPU signals
reported; whether labels are published is reported. Every gap (e.g. AIP entitlement missing → labeling
deferred) is **recorded, not guessed**.

## Test 2 — Discovery inventory and tenant-setting checklist are complete
**Do:** Run `IPPBI-Discover.ps1`; open the Power BI/Fabric admin portal → Tenant settings → Information
protection.
**Expected:** Every sensitivity label and its publishing policy are listed; the in-scope workspaces are
listed; the information-protection tenant-setting checklist is printed and matches the admin portal.

## Test 3 — Publish dry-run makes no changes
**Do:** Run `IPPBI-Set-InfoProtection.ps1 -Action PublishPolicy -PolicyMembers "BI-Labeling-Pilot@contoso.com" -WhatIf`.
**Expected:** It states the policy/label/membership it *would* set plus the reverse action and changes
nothing; a follow-up `Get-LabelPolicy` shows the policy unchanged.

## Test 4 — Labels are published and appear in the service
**Do:** Run `Get-Label | Format-Table DisplayName, Name` and `Get-LabelPolicy`; as a pilot creator, open
a report in the Power BI service and check the sensitivity-label picker.
**Expected:** The labels exist; `Analytics Labels – Policy` is published to the pilot creators; the label
picker appears for a policy member and **not** for a non-member.

## Test 5 — Tenant settings are enabled for the pilot group
**Do:** In the admin portal, confirm each information-protection setting is **On** and scoped to
`BI Labeling – Enabled Users`.
**Expected:** "Allow users to apply sensitivity labels", source inheritance, and export restriction are
On for the group; mandatory labeling is **Off** during the pilot.

## Test 6 — Validation gate passes on the pilot
**Do:** Run `IPPBI-Validate.ps1`.
**Expected:** PASS for each scriptable gate — labels exist and are published to the pilot creators — plus
the printed tenant-setting gates to confirm in the admin portal. Any FAIL names the specific missing
object.

## Test 7 — An artifact can be labeled
**Do:** As a pilot creator, apply `Confidential` to a semantic model and a report in the pilot workspace.
**Expected:** The label is applied and visible on the artifact; a consumer sees the sensitivity indicator.

## Test 8 — The label inherits from a labeled source
**Do:** Build/refresh a report over a **labeled** data source (with source inheritance On).
**Expected:** The content **inherits** the source's label (or the higher of source/existing), so
classification is not lost at the BI boundary. (Verify the exact inheritance behavior against current
Microsoft guidance.)

## Test 9 — The label inherits to an export
**Do:** From a labeled report, **Export to Excel** (and to PowerPoint/PDF).
**Expected:** The exported file **carries the sensitivity label and its encryption/usage rights** — opening
it prompts for/enforces the label's protection. A download no longer strips protection.

## Test 10 — Export restriction behaves as designed
**Do:** As a user without rights to a protected label, attempt to export/consume the protected content.
**Expected:** The export/access is **restricted** per the export-protection setting; an authorized user
succeeds. (Verify against your tenant's export-restriction configuration.)

## Test 11 — Reporting evidence is produced
**Do:** Run `IPPBI-Report.ps1 -CsvPath .\AnalyticsLabelsReport.csv`.
**Expected:** `Analytics Labels – Coverage Report` lists each label, its publication/target coverage, and
the in-scope workspaces — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `Analytics Labels – Pilot Ring – Stage1` — labels published and applied, inheritance
from labeled sources and to exports proven on real content, export restriction behaving as designed, and
the coverage report produced — before expanding to the estate and enabling mandatory labeling. Any
deferred (licensing-gated) capability is recorded explicitly, not silently skipped.
