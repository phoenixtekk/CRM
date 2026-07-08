# 6. Troubleshooting Guide — Microsoft Purview Communication Compliance

Field issues and how to resolve them. **Symptom → Likely cause → Resolution.** Confirm the basics
first: correct licensing, the right Communication Compliance role, and a successful
`Connect-IPPSSession`. Portal paths and cmdlets are plan-dependent and evolve — **verify against your
tenant.**

## Communication Compliance area isn't visible in the Purview portal
**Likely cause:** Missing E5 / E5 Compliance / Insider Risk Management licensing, or the admin lacks a
Communication Compliance role.
**Resolution:** Confirm entitlement in the M365 admin center (Requirement 2.1) — **verify with Microsoft
licensing, don't assume**. Ensure your account is in a Communication Compliance role group (Requirement
2.2). Sign out/in after a licence or role change.

## `Get-SupervisoryReviewPolicyV2` / `SupervisoryReview*` cmdlets are not recognised
**Likely cause:** Not connected via `Connect-IPPSSession`, an outdated ExchangeOnlineManagement module,
or Communication Compliance not entitled/enabled.
**Resolution:** `Import-Module ExchangeOnlineManagement`; `Update-Module ExchangeOnlineManagement`;
`Connect-IPPSSession` (Security & Compliance PowerShell — **not** `Connect-ExchangeOnline`). If the
cmdlets still don't appear, confirm licensing/enablement. `PURVCC-Discovery.ps1` performs this check.

## A role group is missing or empty
**Likely cause:** Communication Compliance not yet initialized in the tenant, or membership never set.
**Resolution:** The four groups (Admin / Analysts / Investigators / Viewers) appear once Communication
Compliance is available; populate them with **separation** in `Settings → Roles & scopes → Permissions`
(Implementation Step 2). If a group is genuinely absent, confirm licensing/enablement.

## The same person is both a policy-builder and a reviewer (separation warning)
**Likely cause:** One identity added to **Communication Compliance Admin** *and* **Analysts/
Investigators**, or the combined **Communication Compliance** role group is in use.
**Resolution:** This is the guardrail the solution exists to enforce. Remove the overlap so builders,
reviewers, and investigators are distinct — or obtain **explicit HR/legal acceptance** for a stated
reason. Avoid the combined role group outside a tiny pilot. `PURVCC-Discovery.ps1` flags the overlap.

## `PURVCC-Configuration.ps1` didn't create anything
**Likely cause:** It ran in the default **`-WhatIf`** mode (by design), or the policy name already
exists.
**Resolution:** Review the planned actions it printed; re-run with **`-Commit`** *after HR/legal
sign-off* to apply. If the policy already exists, adjust it with `PURVCC-Set-Scope.ps1` instead, or
choose a new name.

## `-Commit` fails: classifier or sensitive-info-type not found
**Likely cause:** A named trainable classifier or SIT isn't available in your tenant (plan-dependent or
different display name).
**Resolution:** In `Data classification → Classifiers` / `→ Sensitive info types`, confirm the exact
name exists (Requirement 2.6). Correct the `-Classifiers` / `-SensitiveInfoTypes` values to match, then
re-run. **Verify availability against your tenant — don't assume a classifier is present.**

## Policy created but no alerts appear
**Likely cause:** Processing latency; wrong channel coverage; the sampling percentage is low; test
messages fell outside the conditions; or the supervised population is wrong.
**Resolution:** Allow processing time. Confirm the in-scope **channels** (Teams/Exchange/Viva Engage/
connected sources — Requirement 2.5) and that the test user is in the supervised group and **not** in
`Comms Excluded – Privacy`. Check that test content actually matches the classifiers/conditions, and
that sampling isn't suppressing it. `PURVCC-Report.ps1` shows the effective rule.

## Too many alerts / reviewers overwhelmed (false positives)
**Likely cause:** Classifiers/conditions too broad, keyword lexicon too loose, sampling too high, or
scope too wide.
**Resolution:** Tune with `PURVCC-Set-Scope.ps1` (`-WhatIf` first): tighten classifiers/keywords, lower
the sampling percentage, or narrow the supervised population; re-validate (Testing Guide Test 6). This
is expected iterative tuning — do it in the pilot before expanding.

## A reviewer can't see alerts, or sees the wrong policy's alerts
**Likely cause:** Reviewer not in **Communication Compliance Analysts**, or not assigned as a reviewer on
the policy.
**Resolution:** Add them to the Analysts group and set them as a policy **reviewer** with
`PURVCC-ReviewerWorkflow.ps1` (`-WhatIf` then `-Commit`). Reviewer visibility is bounded by the policies
they're assigned to.

## A Viewer can see message content
**Likely cause:** The person is in Analysts/Investigators, not **Viewers**.
**Resolution:** Viewers get reports/dashboards only — no content. Move oversight-only people to the
**Communication Compliance Viewers** group. `PURVCC-Discovery.ps1` shows the membership.

## Usernames aren't pseudonymized in the review experience
**Likely cause:** The privacy/anonymization option isn't enabled.
**Resolution:** `Settings → Communication Compliance` → enable the pseudonymization/anonymized-usernames
option (Requirement 2.4) if your privacy stakeholders require it. Confirm reviewers now see pseudonyms
(Testing Guide Test 2).

## Connected-source (third-party) messages aren't inspected
**Likely cause:** The data connector for that source isn't configured or isn't ingesting.
**Resolution:** Stand up the relevant **data connector** in the Purview portal and confirm it's
ingesting before scoping a policy to that source (Requirement 2.5). **Connector availability/licensing
vary — verify against your tenant.**

## `Search-UnifiedAuditLog` returns nothing in `PURVCC-Report.ps1`
**Likely cause:** Unified auditing disabled, activity outside the `-DaysBack` window, or a different
record type in your tenant.
**Resolution:** Confirm unified auditing is enabled; widen `-DaysBack`. The **authoritative** alert and
review metrics live in the Communication Compliance area of the Purview portal — the audit-log rollup is
supplementary evidence.

## "Is this a violation? What do we do about the person?"
**Not a tool question.** Communication Compliance surfaces and evidences candidate violations and routes
them through reviewers; **whether a message is a violation and what happens to the employee is an
HR/privacy/legal determination.** Escalate through the Investigator/legal path with the evidence — do
not have IT adjudicate outcomes.
