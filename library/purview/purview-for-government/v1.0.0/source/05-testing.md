# 5. Testing & Validation — Microsoft Purview for Government

Work through every gate. Each has a **method**, an **expected result (pass)**, and a **fail action**. Tests
are read-only or use **benign, self-generated pilot content** on the pilot scope — no production controlled
data is exfiltrated and no DLP policy is enforced during testing. Do not declare "ready to enforce" until
every gate passes for the pilot scope, then re-confirm on expand.

> **Boundary:** these gates prove the **technical control works and is evidenced**. Whether the control
> **satisfies** the CJIS Security Policy, CMMC / NIST SP 800-171, or the ITAR — classification correctness,
> retention adequacy, CMMC-level fit, access sufficiency — is a **compliance/security/records/legal
> determination**, not a test outcome, and this solution makes **no certification/authorization claim.**
> **Sovereign cloud:** confirm each cmdlet/feature behaves as expected **in your cloud** (GCC/GCC High/DoD).

## Gate 1 — Compliance licensing present for each control (in your cloud)
- **Method:** `INDGOV-Discovery.ps1` licensing section (Graph `subscribedSkus` / service plans; connect with
  the correct `-Environment` for your cloud).
- **Pass:** sensitivity-label (encryption/auto-label), DLP/endpoint-DLP, and Audit-Premium-bearing plans are
  present and assigned to the in-scope population.
- **Fail:** assign the license (Requirement 2.1); a missing plan makes the corresponding control unavailable
  — a licensing gap, not a config defect. **Verify plan names for your tenant and cloud.**

## Gate 2 — Connectivity to the correct cloud endpoint
- **Method:** `INDGOV-Discovery.ps1` / `INDGOV-Scope.ps1` connect via `Connect-IPPSSession -ConnectionUri …`
  and `Connect-MgGraph -Environment …` for your cloud.
- **Pass:** both endpoints connect and enumerate objects.
- **Fail:** confirm the exact `-ConnectionUri` / `-Environment` for GCC/GCC High/DoD from current Microsoft
  documentation; the commercial defaults will not connect a sovereign tenant.

## Gate 3 — Government labels exist, encrypt, and publish to the pilot
- **Method:** `INDGOV-Discovery.ps1` / portal — confirm `Protect – Gov CJI – Restricted`,
  `Protect – Gov CUI – Controlled`, `Protect – Gov ITAR – Controlled` exist (`Get-Label`), are configured to
  **encrypt**, and are published (`Get-LabelPolicy`) to `Gov Pilot – Controlled Data – Stage1`.
- **Pass:** all three labels exist, encrypt per the approved rights, and are available to pilot users.
- **Fail:** confirm the label's encryption/rights definition and the label-policy scope; re-verify. **Confirm
  the ITAR access constraint with legal before wider publish.**

## Gate 4 — Label applies and access behaves as designed (pilot content)
- **Method:** apply each label to benign pilot content; confirm encryption applies and that an authorized user
  can open it while an out-of-scope/external user cannot (per the approved rights).
- **Pass:** the label applies, content is encrypted, and access matches the design.
- **Fail:** adjust the rights definition in-portal and retest; **do not broaden publish until access outcomes
  are correct** — an encrypting label changes who can open a file.

## Gate 5 — Services DLP present IN SIMULATION and matching the right content
- **Method:** `INDGOV-Discovery.ps1` / `INDGOV-Validate.ps1` — confirm `DLP – Gov Controlled Data – Simulate`
  exists (`Get-DlpCompliancePolicy`), is in **simulation/test mode**, scoped to the pilot; generate benign
  test content matching the CJI/CUI/ITAR conditions and confirm simulation records a match.
- **Pass:** the policy exists in simulation, is pilot-scoped, and simulation surfaces the expected matches
  **without blocking**.
- **Fail:** confirm the conditions/SITs and scope; tune to reduce false positives/negatives. **Conditions/SIT
  adequacy is governance's determination, not a test.** **Do not enforce.**

## Gate 6 — Endpoint DLP present IN SIMULATION on onboarded devices
- **Method:** `INDGOV-Discovery.ps1` — confirm `DLP – Gov Endpoint Egress – Simulate` exists for **Devices**
  in simulation; on a pilot **onboarded** device, attempt a benign USB/print/cloud-upload of test content and
  confirm simulation records the egress (without blocking).
- **Pass:** the endpoint policy exists in simulation, the pilot device is onboarded, and egress attempts are
  recorded.
- **Fail:** confirm device onboarding and endpoint-DLP licensing/availability **in your cloud**; verify the
  egress-channel conditions; retest. **Do not enforce.**

## Gate 7 — Records retention scoped and audit on with evidence policy
- **Method:** `INDGOV-Discovery.ps1` — confirm `Retention – Gov Records – Publish` exists/enabled and scoped
  to the pilot; confirm `UnifiedAuditLogIngestionEnabled = True` and `Audit Retention – Gov Evidence –
  LongTerm` present (`Get-UnifiedAuditLogRetentionPolicy`).
- **Pass:** retention is scoped and enabled; ingestion is True and the audit-evidence policy exists at the
  agreed duration/priority.
- **Fail:** correct the retention scope/duration (records' determination) and/or enable ingestion under change
  control; verify the `RetentionDuration` value and licensing.

## Gate 8 — Control map and evidence binder generated
- **Method:** `INDGOV-Report.ps1` → `Evidence – Gov Controls – Binder`, cross-referenced to
  `Control Map – Gov – Purview`, including the **DLP simulation-match** summary.
- **Pass:** every in-scope obligation maps to a Purview object with its configuration and a proof reference;
  the binder and simulation summary export cleanly.
- **Fail:** fill the gap (missing control or missing evidence) and re-run. A control with no evidence fails an
  assessment.

## Gate 9 — Validation scorecard is green (pilot)
- **Method:** `INDGOV-Validate.ps1`.
- **Pass:** every gate above is green for the pilot scope (and, on expand, for the approved production scope).
- **Fail:** address the specific red item and re-run before enforcing anything or broadening publish.

## Evidence to retain
- `INDGOV-Discovery.ps1` and `INDGOV-Validate.ps1` outputs (before/after).
- The `-WhatIf` transcripts for every label, DLP, endpoint-DLP, retention, and audit change.
- The `INDGOV-Report.ps1` **DLP simulation-match** summary and the `Evidence – Gov Controls – Binder` export
  and `Control Map – Gov – Purview` register.
- The compliance/security/legal sign-offs (data classification, encryption/ITAR access, DLP enforcement,
  retention schedule) and the pilot roster/approvals (Requirement 2.5/2.6/2.8).

> Classification correctness, retention adequacy, CMMC-level fit, ITAR access sufficiency, and rule
> applicability are **compliance/security/records/legal determinations** — these gates prove the Purview
> controls work and are evidenced, not that the program satisfies CJIS/CMMC/ITAR. Feature behavior is
> **cloud-dependent — verify in your cloud.**
