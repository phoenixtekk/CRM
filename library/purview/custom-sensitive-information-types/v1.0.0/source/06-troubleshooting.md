# 6. Troubleshooting Guide — Custom Sensitive Information Types (Microsoft Purview)

Field issues and how to resolve them. **Symptom → Likely cause → Resolution.** Confirm the basics
first: the right compliance role (can manage sensitive info types), a successful `Connect-IPPSSession`,
and that any *consuming* capability you're piloting is licensed. Portal paths, the rule-package schema,
and cmdlets are plan-dependent and evolve — **verify against your tenant.**

## The "Create sensitive info type" option isn't visible in the portal
**Likely cause:** Your account isn't in a role group that can manage sensitive information types.
**Resolution:** Add the account to **Compliance Administrator** or **Compliance Data Administrator** (or
an equivalent custom role group) — Requirement 2.3. Sign out/in after a role change. Global Admin is not
required just to build a SIT.

## `Get/New/Set-DlpSensitiveInformationType*` cmdlets are not recognised
**Likely cause:** Not connected via `Connect-IPPSSession`, or an outdated ExchangeOnlineManagement module.
**Resolution:** `Import-Module ExchangeOnlineManagement`; `Update-Module ExchangeOnlineManagement`;
`Connect-IPPSSession` (Security & Compliance PowerShell — **not** `Connect-ExchangeOnline`).
`CLSCUSTOM-Discovery.ps1` performs this check.

## `Test-DataClassification` is not available
**Likely cause:** Outdated module, or the cmdlet isn't enabled for your tenant/role.
**Resolution:** Update ExchangeOnlineManagement and reconnect; confirm your role. If it remains
unavailable, validate the SIT in the portal's **Test** experience instead (upload/paste a sample) — the
`CLSCUSTOM-Validation.ps1` automation depends on this cmdlet. **Verify availability against your tenant.**

## `CLSCUSTOM-Configuration.ps1` didn't import anything
**Likely cause:** It ran in the default **`-WhatIf`** mode (by design).
**Resolution:** Review the validated XML and the planned action it printed; re-run with **`-Commit`**
*after* `CLSCUSTOM-Validation.ps1` passes. Back up the current package first with
`CLSCUSTOM-Set-Scope.ps1 -Export`.

## Rule-package import fails: schema / validation error
**Likely cause:** The XML doesn't match the current rule-package schema (missing `<IdMatch>`, malformed
`<Regex>`/`<Keyword>`, bad `confidenceLevel`, duplicate entity **GUID**, or an unescaped character in the
regex).
**Resolution:** Validate the XML against Microsoft's current *"create a custom sensitive information type
in PowerShell"* schema. Ensure every `<Entity>` has a **unique GUID**, each `<Pattern>` has a valid
`confidenceLevel` (65/75/85), and regex special characters are properly escaped. `CLSCUSTOM-Configuration.ps1`
checks *well-formedness* but not full schema conformance — fix the reported service error and re-import.

## The SIT exists but positives don't match (false negatives)
**Likely cause:** The regex is too strict; supporting evidence is required but absent in the sample; the
proximity window is too small; or the SIT hasn't finished **publishing** yet.
**Resolution:** Allow publish time and re-run `CLSCUSTOM-Validation.ps1`. Then loosen: relax the regex
(anchors, character classes, length), widen **character proximity**, or make supporting evidence
optional at a lower confidence. Re-validate after each change (Implementation Step 5).

## Look-alike content matches (false positives)
**Likely cause:** The regex is too broad, no supporting evidence is required, or the recommended
confidence is too low — so any number of that shape matches.
**Resolution:** Tighten the regex, **require a supporting keyword within proximity** for the higher
confidence level, and set the **recommended confidence** to what validation proves. Add the offending
look-alikes to `Custom SIT Test – Negative` and re-run `CLSCUSTOM-Validation.ps1` until FP = 0. This is
the gate that protects every downstream policy.

## Validation passed but the pilot policy over/under-matches on real content
**Likely cause:** Real documents differ from the samples; the consuming policy uses a different
confidence threshold than validated; or scope/coverage differs.
**Resolution:** Confirm the consuming policy references the SIT at the **recommended** confidence
(`CLSCUSTOM-Report.ps1`). Refresh the sample sets from real content, re-validate, and adjust the policy's
confidence threshold. Keep the policy in **simulation** until precision on real traffic is acceptable.

## A change to the SIT didn't take effect
**Likely cause:** **Publishing latency**, or the update was applied to a different rule package / name.
**Resolution:** Allow time; re-run `CLSCUSTOM-Validation.ps1`. Confirm you updated the correct package
(`CLSCUSTOM-Discovery.ps1` lists them) and used `-Commit`. A dry-run (`-WhatIf`) changes nothing.

## `CLSCUSTOM-Report.ps1` shows the SIT isn't referenced anywhere
**Likely cause:** The consuming policy references a **different SIT name**, or it's an auto-labeling /
non-DLP consumer this report doesn't enumerate.
**Resolution:** Confirm the exact SIT name matches (`CLSCUSTOM-Discovery.ps1`). This report covers **DLP
compliance** rules; check **auto-labeling** and other consumers in the Purview portal, which use separate
cmdlets.

## `CLSCUSTOM-Report.ps1` shows the SIT in an ENFORCING policy unexpectedly
**Likely cause:** A consuming DLP policy is in **Enable** (enforce) mode rather than **Test** mode.
**Resolution:** If the SIT hasn't cleared the validation + simulation gates, set the consuming policy back
to **TestWithNotifications / TestWithoutNotifications** (simulation) until it has. Enforcement is the
final, approved step — not the default.

## I need to delete a custom SIT / rule package
**Likely cause:** A retired or mistaken SIT.
**Resolution:** First confirm nothing consumes it (`CLSCUSTOM-Report.ps1` — and check auto-labeling in the
portal); a SIT referenced by a live policy should not be deleted out from under it. Then remove the rule
package (`Remove-DlpSensitiveInformationTypeRulePackage`) or delete the SIT in the portal. Back up the XML
first (`CLSCUSTOM-Set-Scope.ps1 -Export`).

## "Does detecting this identifier mean we must retain it / place a hold / report it?"
**Not a tool question.** The SIT provides the **detection method and evidence**. Whether the detected
data triggers **retention, records disposition, legal hold, or regulatory reporting** is a
**records/compliance/legal determination** — defer it to those functions (Requirement 2.6,
`global-requirements-purview.md` §5).
