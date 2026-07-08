# 6. Troubleshooting — Microsoft Purview FERPA Compliance Program

Symptom → likely cause → fix, for the failure modes this program hits most. Diagnosis is read-only
(`CMPFERPA-Discovery.ps1` / `CMPFERPA-Validate.ps1`); fixes go through `CMPFERPA-Configure.ps1`
(`-WhatIf` first, `-Commit` to apply). Remember the boundary: these are **technical** fixes — whether a
configuration satisfies FERPA is a **compliance/registrar/records/legal determination**.

## The sensitivity label doesn't appear to pilot users
- **Cause:** the label isn't published, the publish policy is disabled or scoped to the wrong users, or label-availability latency (publishing can take time to propagate to clients).
- **Fix:** `CMPFERPA-Discovery.ps1` → confirm `Protect – FERPA Education Records – Confidential` exists (`Get-Label`) and `Protect – FERPA Education Records – Publish` is enabled and scoped to the pilot (`Get-LabelPolicy`). Correct scope with `CMPFERPA-Configure.ps1 -Control Label`; allow propagation time, then re-test (Gate 2).

## Classification misses education records (false negatives) or over-matches (false positives)
- **Cause:** the chosen **sensitive information types / trainable classifiers** don't match your education-record patterns (student IDs, grades, disciplinary/health records), or match too broadly.
- **Fix:** `CMPFERPA-Discovery.ps1` sensitive-info-types section lists candidates; tune the SIT/classifier or build a **custom SIT** for your student-ID format. This is exactly what the **pilot** is for — measure and tune before enforcement. **Match-logic adequacy is compliance/registrar's determination, not a technical default.**

## DLP policy fires on legitimate, permitted disclosures
- **Cause:** the **permitted-disclosure exceptions** (to the student, to school officials with legitimate educational interest, under consent, directory information) aren't encoded, so authorized sharing is flagged.
- **Fix:** add the exceptions to `DLP – FERPA Education Records – Simulate` in-portal (they are compliance/registrar's determination), keep the policy **in simulation**, and re-measure the false-positive rate (Gate 5). Only enforce once the rate is acceptable **and** sign-off is complete.

## DLP is blocking users during testing
- **Cause:** the policy was moved to **enforce** (block) instead of staying in **simulation** — DLP is high-impact and the pilot must stay in simulation until sign-off.
- **Fix:** revert the policy to simulation/test mode (`CMPFERPA-Validate.ps1` flags the mode; the Configure helper creates it in `TestWithoutNotifications`). Never enforce outside the pilot without explicit compliance/registrar sign-off. This is the documented rollback for the disclosure-prevention control.

## `Get-DlpCompliancePolicy` shows the FERPA policy as ENFORCING unexpectedly
- **Cause:** an in-portal edit switched the mode, or the policy was created enforcing.
- **Fix:** confirm whether enforcement was **signed off** and recorded with the evidence binder. If not, revert to simulation. `CMPFERPA-Validate.ps1` gates this specifically — a policy enforcing without recorded sign-off is a governance finding.

## Endpoint DLP doesn't match on devices
- **Cause:** devices aren't **onboarded** to Purview, or Endpoint DLP isn't licensed (needs E5 / E5 Compliance).
- **Fix:** confirm licensing (`CMPFERPA-Discovery.ps1` licensing section) and device onboarding (Purview portal → Settings → Device onboarding; `CMPFERPA-Scope.ps1` flags this). Endpoint is a separate location in the DLP policy — verify it's in scope. **Verify feature availability for your tenant.**

## Retention policy not applying to education records
- **Cause:** the policy is disabled, scoped to the wrong locations, or the retention duration doesn't match the records schedule.
- **Fix:** `CMPFERPA-Discovery.ps1` / `CMPFERPA-Validate.ps1` → confirm `Retention – FERPA Records – Publish` is enabled and covers the in-scope locations. Correct with `CMPFERPA-Configure.ps1 -Control Retention`. **Confirm the duration against the records schedule (compliance/registrar determination), not a technical default.**

## Unified audit shows no access evidence
- **Cause:** `UnifiedAuditLogIngestionEnabled` is **False**; no audit evidence is captured while ingestion is off, and it is **not retroactive**.
- **Fix:** enable unified audit under change control (Purview Audit solution / Exchange Online), then create `Audit Retention – FERPA Evidence – LongTerm` (Implementation Step 5). Re-run `CMPFERPA-Discovery.ps1` to confirm ingestion is on (Gate 7).

## `Get-AdminAuditLogConfig` fails in the Security & Compliance session
- **Cause:** `Get-AdminAuditLogConfig` runs in **Exchange Online PowerShell**, not the Security & Compliance session — a common endpoint confusion.
- **Fix:** `Connect-ExchangeOnline` for the audit-config read; the validation script already attempts this fallback. Keep the two sessions distinct (S&C PowerShell for labels/DLP/retention/audit-retention; Exchange Online for `Get-AdminAuditLogConfig`).

## A licensing check reports a plan "NOT found"
- **Cause:** the indicative **service-plan name** in the discovery script doesn't match your tenant's naming, or the plan genuinely isn't licensed. Plan names change over time.
- **Fix:** treat the check as **indicative** — verify the actual entitlement in the M365 admin center (`Billing → Licenses`). If genuinely unlicensed, the corresponding control (auto-labeling, Endpoint DLP, Audit Premium) is unavailable until assigned — a **licensing gap, not a config defect**. **Verify plan names for your tenant.**

## The evidence binder shows a control MISSING
- **Cause:** the control isn't configured, or it's named differently from the register.
- **Fix:** `CMPFERPA-Report.ps1` marks each control PRESENT/MISSING; a MISSING control has no proof and **fails an audit**. Configure the missing control (Implementation Guide) or reconcile the artifact name to the `Control Map – FERPA – Purview` register, then re-run. Retain the binder with the `-WhatIf` transcripts and sign-offs.

## A cmdlet name or parameter isn't recognized
- **Cause:** Purview cmdlets, `-Mode` values, and `-RetentionDuration` values are **tenant-/version-dependent and evolving**; the portal changes.
- **Fix:** **verify the exact cmdlet, parameter, and accepted values against current Microsoft documentation and your tenant** before committing. The scripts are safe-by-default (`-WhatIf`) precisely so you can preview the exact command and confirm it before any change. Do not force a command whose behavior you can't confirm.

> **Boundary reminder:** these fixes restore the **technical control**. Education-record scope,
> permitted-disclosure/DLP-exception adequacy, retention adequacy, and whether the program satisfies FERPA
> (34 CFR Part 99) are **compliance/registrar/records/legal determinations** — this solution provides the
> method and the evidence, not the determination, and makes no certification claim.
