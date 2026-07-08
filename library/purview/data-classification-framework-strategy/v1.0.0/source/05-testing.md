# 5. Testing & Validation Guide — Data Classification Framework & Strategy

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not expand from the pilot ring, and do not enforce the DLP baseline, until the
relevant tests pass. All checks use the Purview portal and Security & Compliance PowerShell — the
provided scripts automate the read-only ones.

> **Reminder:** the tier definitions, DLP enforcement decisions, and retention periods/actions under
> test are the governance/records/legal determinations from §2 — you are validating that the
> configuration *behaves as specified*, not deciding the scheme or the schedule.

## Test 1 — Tier labels created as designed
- **How:** `CLSFRAME-Discovery.ps1`, or `Get-Label | Format-Table DisplayName,Priority`.
- **Pass:** the four tier labels (`Public`, `Internal`, `Confidential`, `Restricted`) exist in tier order, each with the intended protection (marking / encrypt / encrypt+watermark).
- **Fail:** missing/extra labels, wrong order, or wrong protection → fix in `CLSFRAME-FrameworkConfig.ps1` and re-run.

## Test 2 — Tier labels visible to pilot users only
- **How:** as a **pilot** user, open Word/Excel/PowerPoint and Outlook; check the Sensitivity button lists the four tiers. Confirm a **non-pilot** user does **not** see them.
- **Pass:** pilot users see the full ordered tier set; non-pilot users see nothing (publish is scoped).
- **Fail:** labels missing for pilot users (allow client sync time) or visible to non-pilot users → re-check `CLS Policy – Pilot – Ring1` targeting.

## Test 3 — Protected tiers actually encrypt
- **How:** as a pilot user, apply `Confidential` (or `Restricted`) to a test document; attempt to open it as a user **outside** the rights definition.
- **Pass:** the unauthorized user is **denied**; the authorized rights behave as defined; content marking (footer/watermark) appears where configured.
- **Fail:** unauthorized access succeeds, or rights are wrong → the protection service or the label's `EncryptionRightsDefinitions` is misconfigured (§2.7). **Do not publish broadly** until fixed.

## Test 4 — DLP baseline stays in test mode until accepted
- **How:** `Get-DlpCompliancePolicy "CLS DLP – Tier2-3 – Test" | Select-Object Name,Mode`, or `CLSFRAME-Discovery.ps1`.
- **Pass:** the policy `Mode` is a **Test** value (`TestWithNotifications`/`TestWithoutNotifications`), **not** `Enable` — it reports and tips but blocks nothing.
- **Fail:** the policy is enforcing before sign-off → `Set-DlpCompliancePolicy "CLS DLP – Tier2-3 – Test" -Mode Disable` and investigate why it was enabled early.

## Test 5 — DLP baseline matches the right content
- **How:** as a pilot user, send/save test content containing a Tier 2/3 sensitive info type (test data) to a location in scope; review the DLP match report / policy tip. Try clearly non-matching content too.
- **Pass:** the policy matches Tier 2/3 content (policy tip appears, match logged) and does **not** match clearly non-sensitive content.
- **Fail:** over- or under-matching → tune the DLP rule conditions (sensitive info types, instance counts) and re-test. **This is the gate before Step 10 enforcement.**

## Test 6 — Tier retention labels publish and apply (pilot)
- **How:** as a pilot user, apply `CLS Retain – Internal` (or another tier) to a test item in SharePoint/Outlook; confirm it appears and is recorded.
- **Pass:** the tier retention label is available to pilot users and applies; the item shows the label.
- **Fail:** label not offered → re-check `CLS Retain Publish – Pilot – Ring1` scope and the publishing rule (`New-RetentionComplianceRule -PublishComplianceTag`).

## Test 7 — Retention *behavior* is safe (controlled disposition test)
- **How:** for any tier retention label with a **delete** action, apply it to a **disposable test item** with a short/adjusted trigger in a controlled area (never production records) and confirm the disposition/disposition-review behaves as specified.
- **Pass:** at end of period the item is retained/disposed/sent to review exactly as the records/legal determination specifies.
- **Fail:** unexpected deletion or no disposition → **halt broad reliance**, review the label action/trigger with records/legal before enforcing anywhere real.

## Test 8 — The crosswalk is coherent (no orphans)
- **How:** `CLSFRAME-Validation.ps1`.
- **Pass:** every tier has its sensitivity label **and** a DLP posture **and** a retention label, consistently named — no orphan (a label with no retention, a DLP posture with no matching tier label, etc.).
- **Fail:** any tier row incomplete or misnamed → build the missing artifact (`CLSFRAME-FrameworkConfig.ps1`) and re-validate.

## Test 9 — The live crosswalk matches the standard
- **How:** `CLSFRAME-Crosswalk.ps1 -CsvPath .\crosswalk.csv`; compare the exported tier→label→DLP→retention table to the signed-off standard document.
- **Pass:** the live crosswalk equals the standard — same tiers, same mappings, DLP still in test.
- **Fail:** drift between live config and the standard → reconcile (fix config or update the standard with governance sign-off) before expanding.

## Test 10 — Coverage evidence before enforcement
- **How:** `CLSFRAME-Coverage.ps1` (activity/content explorer is E5-tier — **verify your licensing/tenant**).
- **Pass:** pilot content is classifying into the tiers as designed and the DLP test policy is matching Tier 2/3 content as expected — the scheme demonstrably works.
- **Fail:** content not classifying sensibly or DLP not matching → tune conditions and re-measure before enforcing.

## Test 11 — Full readiness before expansion
- **How:** `CLSFRAME-Validation.ps1` (re-run) after all fixes.
- **Pass:** tier labels published to pilot, DLP baseline in **test** with accepted match reports, retention labels published to pilot, crosswalk coherent and matching the standard — all green.
- **Fail:** any red → resolve before publishing `CLS Policy – Broad – AllUsers` or enforcing the DLP baseline.

---
### Exit criteria (all must be true before broad enforcement)
`Four tier labels built as designed · pilot users see labels · protected tiers encrypt · DLP baseline in test only · DLP matches correct content · retention applies + disposition safe · crosswalk coherent (no orphans) · live crosswalk == standard · coverage evidence positive · rollback documented per policy`
