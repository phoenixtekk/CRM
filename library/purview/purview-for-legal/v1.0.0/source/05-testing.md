# 5. Testing & Validation — Microsoft Purview for Legal

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use **benign, self-generated pilot content** — no real privileged material, no
matter records, and no legal hold is created or actioned. Do not declare "Legal-ready" until every gate
passes for the pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether content is
> **privileged**, how matters map, whether retention is **adequate**, and whether a matter needs a **legal
> hold** are **legal/records determinations**, not test outcomes. **Never create or release a legal hold
> during testing — that is the legal function's action in eDiscovery.**

## Gate 1 — Compliance licensing present for each control
- **Method:** `INDLEGAL-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** information-protection (encryption labels), DLP-endpoint, records/regulatory-records, and Audit-Premium-bearing plans are present and assigned to the legal population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable — that is a licensing gap, not a config defect. **Verify plan names for your tenant.**

## Gate 2 — Sensitivity labels published to the pilot
- **Method:** `INDLEGAL-Discovery.ps1` / portal — confirm `Protect – Legal Privileged – Restricted` and `Protect – Legal Matter Confidential – Confidential` exist (`Get-Label`) and are published (`Get-LabelPolicy`) to the pilot population; confirm they appear in Outlook/Office for a pilot user.
- **Pass:** both labels exist, the label policy targets the pilot, and pilot users can see/apply them.
- **Fail:** confirm the label policy scope and publication latency; retest. Labels can take time to appear for end users.

## Gate 3 — Privileged label encrypts as designed
- **Method:** apply `Protect – Legal Privileged – Restricted` to a **benign** pilot document/email; confirm it is encrypted and that only the permitted identities (per legal's decision) can open it.
- **Pass:** the label applies encryption and the permission scope matches legal's approved design (internal-only / named groups / external counsel as decided).
- **Fail:** correct the label's encryption/permission settings; retest with benign content. **Do not broaden decryption beyond legal's approval.**

## Gate 4 — DLP policy exists IN SIMULATION and matches correctly
- **Method:** `INDLEGAL-Discovery.ps1` / portal — confirm `DLP – Legal Privileged – Simulate` exists (`Get-DlpCompliancePolicy`), is in a **test/simulation** mode (`TestWithNotifications`/`TestWithoutNotifications`), scoped to the pilot; generate **benign** content matching the criteria and confirm it appears as a **simulated** match (blocked nothing).
- **Pass:** the policy is in simulation, scoped to the pilot, and surfaces the right matches without blocking; over-matching of legitimate legal sharing is reviewed and tuned.
- **Fail:** tune the rule (labels/info types/exceptions) **still in simulation**; retest. **Do not switch to Enable until the match review is clean and legal signs off.**

## Gate 5 — Matter-records retention applies and preserves (pilot, non-regulatory first)
- **Method:** apply the **non-regulatory** pilot matter-retention label to benign pilot content, attempt to delete it, then confirm via `INDLEGAL-Discovery.ps1` / portal that retention held and the publish policy is scoped to the pilot matter workloads.
- **Pass:** the label applies, records behavior prevents disallowed deletion, and `Get-ComplianceTag`/`Get-RetentionCompliancePolicy` show it scoped to the pilot at the agreed duration.
- **Fail:** confirm the label type (`-IsRecordLabel`), the publish policy scope, and label latency; retest. **Do not proceed to any regulatory-records label until this passes and legal/records sign off.**

## Gate 6 — Regulatory-records behavior confirmed (only if the schedule requires, post sign-off)
- **Method:** *only where the records schedule requires it and after sign-off*, confirm the regulatory-records label exists as a **regulatory** record label (immutable, retention non-shortenable) on the approved scope.
- **Pass:** the label is present and typed regulatory; its irreversibility is understood and documented.
- **Fail:** verify the regulatory-record behavior in your tenant before wider application; a regulatory label **cannot be undone**, so treat any doubt as a stop.

## Gate 7 — Disposition review configured (where required)
- **Method:** portal — confirm the `Disposition – Legal Records – Review` stage governs end-of-retention disposal for the matters the schedule requires.
- **Pass:** disposal is reviewed (not automatic) for the in-scope matter records, with the correct reviewers.
- **Fail:** configure disposition review in-portal; the disposition trigger/reviewers are records' determination.

## Gate 8 — Unified audit on and evidence policy present
- **Method:** `INDLEGAL-Discovery.ps1` audit section (`UnifiedAuditLogIngestionEnabled`, `Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** ingestion is `True` and `Audit Retention – Legal Evidence – LongTerm` exists with the agreed duration and a unique priority.
- **Fail:** enable ingestion under change control; create/correct the policy (Implementation Step 6); verify the `RetentionDuration` value and licensing.

## Gate 9 — Legal-hold coverage is visible (read-only reference)
- **Method:** `INDLEGAL-Discovery.ps1` reference section (`Get-CaseHoldPolicy`, read-only) — confirm existing eDiscovery holds are visible so the legal function can see coverage.
- **Pass:** existing holds (if any) are listed for legal's review. **This gate never creates or changes a hold.**
- **Fail:** if legal expects a hold that is not present, that is a **legal action** in eDiscovery — refer it to the legal function; do not create it here.

## Gate 10 — Control map and evidence binder generated
- **Method:** `INDLEGAL-Report.ps1` → `Evidence – Legal Controls – Binder`, cross-referenced to `Control Map – Legal – Purview`.
- **Pass:** every in-scope obligation maps to a Purview object with its configuration and a proof reference; the binder exports cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an audit.

## Gate 11 — Validation scorecard is green (pilot)
- **Method:** `INDLEGAL-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope with DLP moved to Enable).
- **Fail:** address the specific red item and re-run before enforcing anything tenant-wide.

## Evidence to retain
- `INDLEGAL-Discovery.ps1` and `INDLEGAL-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, retention, and audit change, and the DLP **simulation match report**.
- The `Evidence – Legal Controls – Binder` export and the `Control Map – Legal – Purview` register.
- The legal/records sign-offs (encryption scope, DLP enforcement, retention schedule, regulatory-records application) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Privilege determination, matter mapping, retention adequacy, disposition triggers, and legal-hold scope
> are **legal/records determinations** — these gates prove the Purview controls work and are evidenced,
> not that the program satisfies a legal obligation. **Legal holds and eDiscovery actions remain legal's.**
