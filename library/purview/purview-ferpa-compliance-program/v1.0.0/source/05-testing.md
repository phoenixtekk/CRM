# 5. Testing & Validation — Microsoft Purview FERPA Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use **benign, self-generated pilot content** — no production education records
are exposed and no user is blocked (DLP stays in simulation). Do not declare "FERPA-ready" until every
gate passes for the pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether the control
> **satisfies** FERPA — whether the classified data are the right education records, whether the DLP
> match logic and permitted-disclosure exceptions are adequate, whether retention meets the schedule —
> is a **compliance/registrar/records/legal determination**, not a test outcome. **Never enforce a DLP
> policy as part of testing — keep it in simulation until sign-off.**

## Gate 1 — Compliance licensing present for each control
- **Method:** `CMPFERPA-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** information-protection/DLP (incl. Endpoint if in scope) and Audit Premium-bearing plans are present and assigned to the in-scope population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable — that is a licensing gap, not a config defect. **Verify plan names for your tenant.**

## Gate 2 — Sensitivity label applies to education records (pilot)
- **Method:** confirm `Protect – FERPA Education Records – Confidential` is published to the pilot (`Get-Label`/`Get-LabelPolicy`), then apply it to benign pilot education-record content and confirm it takes (and, if designed, encrypts/marks).
- **Pass:** the label appears to pilot users, applies, and `Get-Label` shows the expected settings.
- **Fail:** confirm label publish scope, availability latency, and the sensitive-info-type/classifier match; retest.

## Gate 3 — Education-record classification matches (SIT / classifier)
- **Method:** `CMPFERPA-Discovery.ps1` sensitive-info-types section; test benign content containing education-record patterns (student ID, grades) against the chosen SIT/classifier.
- **Pass:** the in-scope sensitive information types / trainable classifiers exist and match the education-record test content at an acceptable rate.
- **Fail:** tune the SIT/classifier or select a better match; **match-logic adequacy is compliance/registrar's determination, not a test.**

## Gate 4 — DLP policy present IN SIMULATION with disclosure exceptions
- **Method:** `CMPFERPA-Discovery.ps1` / `CMPFERPA-Validate.ps1` — confirm `DLP – FERPA Education Records – Simulate` (`Get-DlpCompliancePolicy`) is in **simulation/test** mode (not enforce), scoped to the pilot locations, with the permitted-disclosure exceptions configured.
- **Pass:** the DLP policy exists, is in simulation, pilot-scoped, and carries the exceptions.
- **Fail:** correct the mode/scope/exceptions; **do not switch to enforce**. Confirm the exceptions with compliance/registrar (determination).

## Gate 5 — DLP surfaces simulation matches without blocking (benign)
- **Method:** generate **benign test content** matching the policy conditions across the in-scope workloads (email, SharePoint/OneDrive, Teams, endpoint if in scope); confirm simulation events appear and **no user is blocked**.
- **Pass:** simulation matches are generated, false positives are within the agreed tolerance, and no enforcement action fires.
- **Fail:** confirm conditions/scope and ingestion latency; adjust exceptions and retest. A high false-positive rate is a tuning task before enforcement.

## Gate 6 — Retention policy scoped
- **Method:** `CMPFERPA-Discovery.ps1` / portal — confirm `Retention – FERPA Records – Publish` covers the in-scope education-record locations for the pilot at the agreed duration.
- **Pass:** the retention policy exists, is enabled, and covers the intended locations at the agreed duration.
- **Fail:** correct locations/duration with `CMPFERPA-Configure.ps1 -Control Retention`; re-verify. Confirm the duration against the records schedule (determination).

## Gate 7 — Unified audit on and evidence policy present
- **Method:** `CMPFERPA-Discovery.ps1` audit section (`UnifiedAuditLogIngestionEnabled`, `Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** ingestion is `True` and `Audit Retention – FERPA Evidence – LongTerm` exists with the agreed duration and a unique priority.
- **Fail:** enable ingestion under change control; create/correct the policy (Implementation Step 5); verify the `RetentionDuration` value and licensing.

## Gate 8 — Control map and evidence binder generated
- **Method:** `CMPFERPA-Report.ps1` → `Evidence – FERPA Controls – Binder`, cross-referenced to `Control Map – FERPA – Purview`.
- **Pass:** every in-scope obligation maps to a Purview object with its configuration and a proof reference; the binder exports cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an audit.

## Gate 9 — Validation scorecard is green (pilot)
- **Method:** `CMPFERPA-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope with DLP enforced).
- **Fail:** address the specific red item and re-run before enforcing anything.

## Evidence to retain
- `CMPFERPA-Discovery.ps1` and `CMPFERPA-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, retention, and audit change.
- The `Evidence – FERPA Controls – Binder` export and the `Control Map – FERPA – Purview` register.
- The compliance/registrar sign-offs (education-record scope, permitted-disclosure exceptions, DLP enforcement, retention schedule) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Education-record scope, DLP match/exception adequacy, retention adequacy, and rule applicability are
> **compliance/registrar/records/legal determinations** — these gates prove the Purview controls work and
> are evidenced, not that the program satisfies FERPA.
