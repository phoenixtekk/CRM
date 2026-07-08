# 5. Testing & Validation — Microsoft Purview FedRAMP Compliance Program

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**.
Tests are read-only or use **benign, self-generated pilot content** — no production controlled data is
exposed and **no DLP enforcement (blocking) is exercised during testing**. Do not declare "FedRAMP-ready"
until every gate passes for the pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether the control
> **satisfies** a specific NIST 800-53 control, which **baseline** applies, and whether the tenant
> supports an **ATO** are **security/compliance/legal determinations**, not test outcomes. **This
> solution asserts no certification or ATO.**

## Gate 1 — Compliance licensing present for each control
- **Method:** `CMPFEDRAMP-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans).
- **Pass:** information-protection, DLP, and Audit Premium-bearing plans are present and assigned to the in-scope population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable — that is a licensing gap, not a config defect. **Verify plan names for your tenant.**

## Gate 2 — Sensitivity label applies (pilot, benign content)
- **Method:** apply `Protect – FedRAMP Controlled – Confidential` to benign pilot content; confirm via `CMPFEDRAMP-Discovery.ps1` / portal that the label and its publish policy are scoped to the pilot.
- **Pass:** the label applies, and `Get-Label`/`Get-LabelPolicy` show it published to the pilot scope; if encryption is designed, protected content behaves as intended for a pilot user.
- **Fail:** confirm the label definition, the publish-policy scope, and label availability latency; retest. **Do not apply encryption tenant-wide until the pilot behavior is confirmed.**

## Gate 3 — DLP policy present IN TEST / SIMULATION mode
- **Method:** `CMPFEDRAMP-Discovery.ps1` / `CMPFEDRAMP-Validate.ps1` — confirm `DLP – FedRAMP Controlled – Simulate` (`Get-DlpCompliancePolicy`) exists and its **Mode is a test/simulation mode** (not `Enable`), scoped to the pilot.
- **Pass:** the DLP policy exists, is pilot-scoped, and is in **test/simulation** mode (no blocking).
- **Fail:** correct the mode/scope with `CMPFEDRAMP-Configure.ps1 -Control DLP`; **never leave it in `Enable` before the pilot passes and sign-off is obtained.**

## Gate 4 — DLP matches and reports on benign test content (no blocking)
- **Method:** generate **benign test content** matching the DLP condition (the controlled-data sensitive info type / label) for a pilot user; review the DLP **simulation/overview** results in-portal.
- **Pass:** the policy **reports** a match with **no user action blocked** (test mode); the match is visible in the DLP results.
- **Fail:** confirm the rule conditions/scope and ingestion latency; adjust and retest. **Match/condition adequacy for a control is security/compliance's determination, not a test.**

## Gate 5 — Unified audit on and evidence policy present (AU)
- **Method:** `CMPFEDRAMP-Discovery.ps1` audit section (`UnifiedAuditLogIngestionEnabled`, `Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** ingestion is `True` and `Audit Retention – FedRAMP Evidence – LongTerm` exists with the agreed duration and a unique priority.
- **Fail:** enable ingestion under change control; create/correct the policy (Implementation Step 5); verify the `RetentionDuration` value and licensing.

## Gate 6 — Controlled-records retention scoped
- **Method:** `CMPFEDRAMP-Discovery.ps1` / portal — confirm `Retention – FedRAMP Records – Publish` covers the in-scope locations for the pilot.
- **Pass:** the retention policy exists, is enabled, and covers the intended locations at the agreed duration.
- **Fail:** correct the locations/duration with `CMPFEDRAMP-Configure.ps1 -Control Retention`; re-verify. Confirm the retention duration with compliance (determination).

## Gate 7 — Compliance Manager assessment reflects the controls
- **Method:** Purview portal → Compliance Manager — confirm `Assessment – FedRAMP Controls – Program` exists (from a FedRAMP template) and its improvement actions link to the configured Purview objects.
- **Pass:** the assessment is present and its actions cross-reference the `Control Map – FedRAMP – Purview` register with evidence links.
- **Fail:** create/assign the assessment (Implementation Step 6) and map actions to objects. Template availability/baseline is licensing- and compliance-dependent.

## Gate 8 — Control map and evidence binder generated
- **Method:** `CMPFEDRAMP-Report.ps1` → `Evidence – FedRAMP Controls – Binder`, cross-referenced to `Control Map – FedRAMP – Purview`.
- **Pass:** every in-scope control maps to a Purview object with its configuration and a proof reference; the binder exports cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an assessment.

## Gate 9 — Validation scorecard is green (pilot)
- **Method:** `CMPFEDRAMP-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope with DLP enforced).
- **Fail:** address the specific red item and re-run before enforcing anything tenant-wide.

## Evidence to retain
- `CMPFEDRAMP-Discovery.ps1` and `CMPFEDRAMP-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, audit, and retention change.
- The `Evidence – FedRAMP Controls – Binder` export and the `Control Map – FedRAMP – Purview` register.
- The security/compliance sign-offs (DLP enforcement, encryption application, retention schedule, baseline) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Baseline selection, control applicability, NIST 800-53 sufficiency, and any ATO decision are
> **security/compliance/legal determinations** — these gates prove the Purview controls work and are
> evidenced, not that the program satisfies FedRAMP or supports an authorization.
