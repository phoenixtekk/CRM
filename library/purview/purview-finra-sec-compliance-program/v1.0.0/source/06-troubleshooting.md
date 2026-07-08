# 6. Troubleshooting — Microsoft Purview FINRA/SEC Compliance Program

Symptom → likely cause → fix, for the failure modes you are most likely to hit. Diagnosis is
read-only: run `CMPFINRA-Discovery.ps1`, `CMPFINRA-Scope.ps1`, and `CMPFINRA-Validate.ps1` first — they
name the specific gap and the Implementation step that closes it. Remember the boundary throughout:
these fixes make the **technical control** work and be **evidenced**; whether a control **satisfies** a
FINRA/SEC rule is a **compliance/records/legal determination**.

## A capability is missing entirely (label type, supervision, audit tier) — likely a licensing gap
- **Cause:** Records/regulatory-records, Communication Compliance, and Audit Premium are **plan-gated**
  (Microsoft 365 **E5** or the **E5 Compliance** add-on; Requirement 2.1). If the plan/service plan is
  absent or unassigned to the in-scope user, the control simply isn't available — that is a licensing
  gap, not a configuration defect.
- **Fix:** `CMPFINRA-Discovery.ps1` licensing section reports the indicative plans; confirm in **M365
  admin center → Billing → Licenses** and assign the right plan to the in-scope population. **Plan and
  service-plan names change — verify them for your tenant** rather than trusting the script's indicative
  list.

## `Connect-IPPSSession` fails or cmdlets are "not recognized"
- **Cause:** The `ExchangeOnlineManagement` module isn't installed/updated, you're not on modern
  auth/MFA, or you ran a Security & Compliance cmdlet in the wrong session.
- **Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (update if old);
  `Connect-IPPSSession` with an MFA-capable admin. Note the **two different sessions**: retention labels,
  DLP, supervision, and audit-retention cmdlets are **Security & Compliance PowerShell**
  (`Connect-IPPSSession`), while `Get-AdminAuditLogConfig` runs in **Exchange Online PowerShell**
  (`Connect-ExchangeOnline`). `CMPFINRA-Validate.ps1` falls back to `Connect-ExchangeOnline` for the
  ingestion check — connect there if the audit gate can't read config.

## `Get-SupervisoryReviewPolicyV2` (or the supervision cmdlets) error / not found
- **Cause:** The Communication Compliance feature/cmdlet set isn't available for your tenant/licensing,
  or your account lacks the Communication Compliance role.
- **Fix:** Confirm Communication Compliance licensing (Requirement 2.1) and that you hold the least-
  privilege **Communication Compliance** role (Requirement 2.2). The cmdlet surface for supervision has
  **changed over time and varies by tenant** — **verify the current cmdlet/feature for your tenant** in
  Microsoft's documentation before assuming a defect. Build the policy **in test mode** regardless.

## Records/regulatory-records label applied but content can still be deleted, or label isn't visible
- **Cause:** Label **publish latency** (a published label can take time to appear), the publish policy
  isn't scoped to the location, or the label was created as **retain-only** rather than a **record**
  (`-IsRecordLabel`)/**regulatory record** (`-Regulatory`).
- **Fix:** Confirm the label type with `Get-ComplianceTag` (`IsRecordLabel`/`RegulatoryRecord`), confirm
  `Retention – FINRA/SEC Records – Publish` covers the pilot location, and allow for propagation before
  retesting (Testing Gate 2). **Pilot with the non-regulatory label first** — never chase this on a
  regulatory-records label.

## "I need to undo a regulatory-records label" — you can't
- **Cause:** A **regulatory record** label is **immutable and cannot be removed**, and its retention
  **cannot be shortened or disabled** — by design (that is the point of the control).
- **Fix:** There is no rollback. This is exactly why the model **pilots with a non-regulatory records
  label first** and applies the regulatory label **only under explicit compliance sign-off** on the
  approved scope. If you applied it in error, this is a **compliance/records** escalation, not a
  technical fix. Treat any doubt before committing as a stop.

## Comms-store retention policy exists but Validate shows it DISABLED or out of scope
- **Cause:** The policy was created disabled, or its locations don't cover the intended Exchange/Teams
  targets.
- **Fix:** `CMPFINRA-Discovery.ps1` shows `Enabled`/`Workload`; correct the scope/enable it with
  `CMPFINRA-Configure.ps1 -Control Records` and re-run `CMPFINRA-Validate.ps1` (Testing Gate 4). Confirm
  the **retention duration** with compliance — the duration is their determination, not a default.

## Audit gate red: ingestion off, or evidence policy missing
- **Cause:** `UnifiedAuditLogIngestionEnabled` is **False** (no evidence is being written, and it is
  **not retroactive**), or `Audit Retention – FINRA/SEC Evidence – LongTerm` doesn't exist / uses an
  invalid `RetentionDuration` for your tenant/licensing.
- **Fix:** Enable unified audit under change control (Purview Audit solution / Exchange Online), then
  create the policy with `CMPFINRA-Configure.ps1 -Control Audit` (Implementation Step 4). **Verify the
  accepted `RetentionDuration` values and that the long-term tier is licensed** (Requirement 2.1) —
  an unlicensed long-term duration is rejected.

## Supervision policy created but no review items appear
- **Cause:** No content yet matches the policy conditions, ingestion/indexing latency, the supervised
  users aren't the pilot population, or the conditions/lexicon don't match your test content.
- **Fix:** Generate **benign test communications** matching the conditions for a pilot user, allow for
  latency, and confirm the policy's supervised users are the pilot group and reviewers are the
  designated (separated) reviewers (Testing Gates 6–7). **Never action a real item to "test" it —
  outcomes are HR/legal's.** Whether the conditions/lexicon are **adequate** is compliance's
  determination, not a test result.

## Reviewers can see too much, or the configuring admin can self-review
- **Cause:** **Reviewer role separation** wasn't enforced — a privacy/governance defect, not a bug.
- **Fix:** Separate the **Communication Compliance** reviewer roles from the configuring admin
  (Requirement 2.2/2.6); enable **pseudonymization** where the tenant supports it; obtain the privacy/
  notice sign-off. `CMPFINRA-Scope.ps1` lists visible role groups to check separation. Keep the policy
  in **test** until this is resolved.

## Graph licensing or population check fails
- **Cause:** `Microsoft.Graph` isn't installed, consent for `Organization.Read.All` /
  `Directory.Read.All` / `Group.Read.All` / `User.Read.All` wasn't granted, or the covered-persons group
  display name is wrong.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; consent to the delegated scopes at
  `Connect-MgGraph`; pass the **exact** group display name to `CMPFINRA-Scope.ps1 -CoveredPersonsGroup`.
  Use `-SkipGraphLicensing` / `-SkipGraph` to run the S&C-only sections if Graph is unavailable.

## Evidence binder has gaps (a control with no proof)
- **Cause:** A control isn't configured, or it's configured but the report can't resolve its object
  (name mismatch) — either way it exports as `Present=False`.
- **Fix:** `CMPFINRA-Report.ps1` lists every missing object; either configure the control (Implementation
  Steps 3–6) or correct the artifact name so it matches the **verbatim** naming convention
  (Overview §"Naming convention"). Re-run until no control is missing — **a control with no evidence
  fails an exam** (Testing Gate 8).

## A `-Commit` change didn't take effect
- **Cause:** `-WhatIf` and `-Commit` were both passed (`-WhatIf` wins — nothing changes), or the cmdlet
  errored mid-run.
- **Fix:** Re-run with **only** `-Commit` (no `-WhatIf`), read the error, and confirm with
  `CMPFINRA-Discovery.ps1` / `CMPFINRA-Validate.ps1`. The Configure helper prints `SAFE MODE` when no
  write will occur — if you see it, you're still in preview.

## Everything passes for the pilot but you're unsure you're "FINRA/SEC-ready"
- **Cause:** Green gates prove the **technical controls are present, working, and evidenced** — they do
  **not** certify regulatory compliance.
- **Fix:** Take the `Evidence – FINRA/SEC Controls – Binder` and `Control Map – FINRA/SEC – Purview` to
  your **compliance, records, and legal** functions for the determination (retention adequacy,
  supervisory scope/lexicon, 17a-4 compliance, rule applicability). Then expand from pilot to enforcement
  under change control and schedule the read-only monitoring chain so drift is caught before an examiner
  finds it.
