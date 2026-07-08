# 6. Troubleshooting — Microsoft Purview FedRAMP Compliance Program

Symptom → likely cause → fix, for the failure modes this program actually hits. Diagnosis is read-only
(`CMPFEDRAMP-Discovery.ps1` / `CMPFEDRAMP-Validate.ps1`); changes go through `CMPFEDRAMP-Configure.ps1`
(`-WhatIf` first, `-Commit` to apply). Remember the boundary: these are **technical** fixes — baseline
selection, NIST 800-53 applicability, and any ATO decision remain **security/compliance/legal's**, and
this solution asserts **no certification or ATO**.

## A capability is missing from the portal or a cmdlet errors "not recognized"
- **Cause:** licensing gap or a feature not enabled/available in your tenant. Sensitivity-label encryption, DLP, and Audit Premium require **E5 / E5 Compliance**; some features/cmdlets are region- or plan-gated and evolve.
- **Fix:** run `CMPFEDRAMP-Discovery.ps1` licensing section; confirm the plan is **present and assigned** to in-scope users (Requirement 2.1). **Verify plan/cmdlet names against your tenant and current Microsoft docs** — a missing plan is a licensing gap, not a config defect.

## `Connect-IPPSSession` fails or hangs
- **Cause:** `ExchangeOnlineManagement` not installed, MFA/modern-auth prompt blocked, or a stale token.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; run interactively so the MFA prompt appears; retry. `CMPFEDRAMP-Scope.ps1` reports endpoint reachability.

## `Get-Label` / label cmdlets not found, or the label won't appear for users
- **Cause:** information-protection feature/licensing not available, or the label is created but **not published** to the pilot scope.
- **Fix:** verify licensing; create the label and its policy with `CMPFEDRAMP-Configure.ps1 -Control Label -Publish` and **scope the policy to the pilot users/locations** (not All). Allow for label-availability latency before it shows in apps.

## The DLP policy isn't blocking anything
- **This is expected.** The policy is created in **test/simulation** mode (`TestWithoutNotifications` / `TestWithNotifications`) — it **matches and reports but does not block**. This is by design so you can tune before enforcing.
- **Fix (only after the pilot passes and sign-off):** `CMPFEDRAMP-Configure.ps1 -Control DLP -Enforce -Commit` switches it to `-Mode Enable`. Never enforce before the test pilot is validated.

## The DLP policy is unexpectedly ENFORCING (Enable) before sign-off
- **Cause:** the policy was created/switched to `Enable` prematurely.
- **Fix:** `CMPFEDRAMP-Validate.ps1` flags this as a RED gate. Return it to test/simulation via the portal (or recreate with the helper) until the pilot passes and security/compliance sign off. Enforcing blind can block legitimate user actions.

## DLP matches nothing on test content
- **Cause:** the rule conditions don't match your controlled-data definition (wrong sensitive info type / label), content-indexing latency, or the location isn't in scope.
- **Fix:** confirm the `New-DlpComplianceRule` conditions reflect the **controlled-data definition your security/compliance function specified** (match/lexicon adequacy is *their* determination, not a test); allow ingestion latency; verify the pilot location is in the policy scope. Review the DLP **simulation/overview** results in-portal.

## Endpoint DLP conditions do nothing
- **Cause:** devices are **not onboarded** to Purview, so endpoint conditions can't evaluate.
- **Fix:** onboard the pilot devices to Purview (Requirement 2.6) before relying on any endpoint DLP condition; re-test on an onboarded device.

## Applying the encryption label broke access / downstream automation
- **Cause:** a label with **encryption** changes who can open content and can affect guests, service accounts, and automation.
- **Fix:** this is why encryption is **piloted on benign content first**. Confirm recovery/super-user and offboarding behavior before wider use; if access broke, review the encryption/rights settings and the affected principals. Understand removal implications in **your** tenant before changing an in-use encryption label.

## `Get-AdminAuditLogConfig` fails or ingestion shows False
- **Cause:** the cmdlet runs in **Exchange Online PowerShell** (`Connect-ExchangeOnline`), not only S&C PowerShell; or unified audit ingestion is genuinely off.
- **Fix:** `Connect-ExchangeOnline` and re-read; if `UnifiedAuditLogIngestionEnabled` is False, enable unified audit under change control (Requirement 2.7). Audit evidence is **not retroactive** — nothing is captured for the period it was off.

## The audit / retention policy errored on `RetentionDuration`
- **Cause:** an unsupported duration value or an unlicensed long-term tier.
- **Fix:** **verify the accepted `-RetentionDuration` values and that the long-term tier is licensed** for your tenant (Requirement 2.1) before committing; adjust the `-Duration` / `-RetentionDuration` parameter and re-run `-WhatIf`.

## Two audit retention policies conflict / priority error
- **Cause:** duplicate or overlapping `New-UnifiedAuditLogRetentionPolicy` priorities.
- **Fix:** give the evidence policy a **unique `-Priority`**; `CMPFEDRAMP-Discovery.ps1` lists existing policies and priorities so you can pick a free one.

## Compliance Manager has no FedRAMP template
- **Cause:** the **FedRAMP Moderate / High** assessment templates may be premium and licensing-dependent, or not yet added.
- **Fix:** verify template availability in-portal against your licensing; add/assign the template and create `Assessment – FedRAMP Controls – Program` (Implementation Step 6). Baseline choice and applicability are **security/compliance's** determination.

## The evidence binder shows a gap (a control with no object)
- **Cause:** the implementing Purview object doesn't exist (or is named differently from the register).
- **Fix:** `CMPFEDRAMP-Report.ps1` flags each gap. Configure the missing control (Implementation Guide) or align the name to `Control Map – FedRAMP – Purview`, then re-run. **A control with no evidence fails an assessment.**

## Validation was green, now a gate is red (drift)
- **Cause:** a DLP policy disabled, a label unpublished, a lapsed license, or audit turned off since the last run.
- **Fix:** this is why the read-only chain (`CMPFEDRAMP-Discovery.ps1` → `CMPFEDRAMP-Validate.ps1` → `CMPFEDRAMP-Report.ps1`) is **scheduled**. Remediate the specific red item and regenerate the evidence binder before the next assessment cycle.

> If a fix would require deciding the **baseline**, whether a Purview object **satisfies** a NIST 800-53
> control, or anything touching an **ATO/authorization**, stop — those are **security/compliance/legal**
> determinations. This solution provides the technical control and the evidence, not the determination,
> and asserts no certification or ATO.
