# 5. Testing & Validation — Microsoft Purview FINRA/SEC Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use **benign, self-generated pilot content** — no production records or real
employee communications are actioned. Do not declare "FINRA/SEC-ready" until every gate passes for the
pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether the control
> **satisfies** a specific FINRA/SEC rule — retention adequacy, supervisory scope/lexicon sufficiency,
> 17a-4 electronic-recordkeeping compliance — is a **compliance/records/legal determination**, not a
> test outcome. **Never action a real supervision item during testing — outcomes are HR/legal's.**

## Gate 1 — Compliance licensing present for each control
- **Method:** `CMPFINRA-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** records/regulatory-records, Communication Compliance, and Audit Premium-bearing plans are present and assigned to the in-scope population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable — that is a licensing gap, not a config defect. **Verify plan names for your tenant.**

## Gate 2 — Records label applies and preserves (pilot, non-regulatory first)
- **Method:** apply the **non-regulatory** pilot records label to benign pilot content, attempt to edit/delete it, then confirm via `CMPFINRA-Discovery.ps1` / portal that retention held.
- **Pass:** the label applies, records behavior prevents disallowed deletion, and `Get-ComplianceTag`/`Get-RetentionCompliancePolicy` show it scoped to the pilot.
- **Fail:** confirm the label type (`-IsRecordLabel`), the publish policy scope, and label availability latency; retest. **Do not proceed to the regulatory-records label until this passes and compliance signs off.**

## Gate 3 — Regulatory-records behavior confirmed (post sign-off)
- **Method:** after compliance sign-off, confirm `Records – FINRA/SEC Regulated – Regulatory` exists as a **regulatory** record label (immutable, retention non-shortenable) on the approved scope.
- **Pass:** the label is present and typed regulatory; its irreversibility is understood and documented.
- **Fail:** verify the regulatory-record behavior in your tenant before wider application; a regulatory label **cannot be undone**, so treat any doubt as a stop.

## Gate 4 — Communications-store retention scoped
- **Method:** `CMPFINRA-Discovery.ps1` / portal — confirm `Retention – FINRA/SEC Comms Store – Immutable` covers the in-scope Exchange/Teams locations for the pilot.
- **Pass:** the retention policy exists, is enabled, and covers the intended comms locations at the agreed duration.
- **Fail:** correct the locations/duration with `CMPFINRA-Configure.ps1 -Control Records`; re-verify. Confirm the retention duration with compliance (determination).

## Gate 5 — Unified audit on and evidence policy present
- **Method:** `CMPFINRA-Discovery.ps1` audit section (`UnifiedAuditLogIngestionEnabled`, `Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** ingestion is `True` and `Audit Retention – FINRA/SEC Evidence – LongTerm` exists with the agreed duration and a unique priority.
- **Fail:** enable ingestion under change control; create/correct the policy (Implementation Step 4); verify the `RetentionDuration` value and licensing.

## Gate 6 — Supervision policy exists in TEST with reviewer separation
- **Method:** `CMPFINRA-Discovery.ps1` / `CMPFINRA-Validate.ps1` — confirm `Supervision – Registered Persons Comms – Test` (`Get-SupervisoryReviewPolicyV2`) is scoped to the pilot group, in test, and that reviewers are separated from the configuring admin (Requirement 2.2/2.6).
- **Pass:** the test policy exists, is pilot-scoped, and only designated reviewers can access its items.
- **Fail:** correct scope/reviewers; **do not enforce or action real items**. If pseudonymization is required and not enabled, resolve before proceeding.

## Gate 7 — Supervision surfaces test items (benign)
- **Method:** generate **benign test communications** matching the policy conditions for a pilot user; confirm a review item appears to the designated reviewer.
- **Pass:** a review item is generated and visible only to the reviewer.
- **Fail:** confirm the policy conditions/scope and ingestion latency; adjust and retest. **Conditions/lexicon adequacy is compliance's determination, not a test.**

## Gate 8 — Control map and evidence binder generated
- **Method:** `CMPFINRA-Report.ps1` → `Evidence – FINRA/SEC Controls – Binder`, cross-referenced to `Control Map – FINRA/SEC – Purview`.
- **Pass:** every in-scope obligation maps to a Purview object with its configuration and a proof reference; the binder exports cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an exam.

## Gate 9 — Validation scorecard is green (pilot)
- **Method:** `CMPFINRA-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope).
- **Fail:** address the specific red item and re-run before enforcing anything tenant-wide.

## Evidence to retain
- `CMPFINRA-Discovery.ps1` and `CMPFINRA-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, retention, audit, and supervision change.
- The `Evidence – FINRA/SEC Controls – Binder` export and the `Control Map – FINRA/SEC – Purview` register.
- The compliance sign-offs (regulatory-records application, supervisory scope, retention schedule) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Retention adequacy, supervisory-scope sufficiency, 17a-4 compliance, and rule applicability are
> **compliance/records/legal determinations** — these gates prove the Purview controls work and are
> evidenced, not that the program satisfies the regulation.
