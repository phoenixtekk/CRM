# 3. Implementation Guide — Microsoft Purview FERPA Compliance Program

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`,
`*-RetentionCompliancePolicy`/`*-ComplianceTag`, and `*-UnifiedAuditLogRetentionPolicy` cmdlets), and
**Microsoft Graph** (licensing). Every write is gated: scripts run **read-only or `-WhatIf` by default**
and only change state with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>`
convention from the Overview and are reused verbatim.

> **Model:** Assess the controls/licensing you have → design the obligation-to-control map with
> compliance/registrar/legal → configure classification & labels, DLP, and retention & audit evidence →
> **pilot in simulation/test/disabled mode** → validate and evidence → expand to enforcement. Pattern:
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Determination boundary:** which data are education records, which disclosures are permitted, retention
> durations, and whether a configuration *satisfies* FERPA are **compliance/registrar/records/legal**
> determinations. This guide configures the control and evidences it; it does not make the determination.
> **A DLP policy is enforced only after it passes in simulation and compliance/registrar signs off —
> never enforce outside the pilot without sign-off.**

## Step 1 — Assess current controls and licensing (Assess)
1. Run `CMPFERPA-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph and reports:
   - compliance licensing present (information-protection / DLP / Audit-Premium-bearing plans — **verify plan names for your tenant**),
   - existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`),
   - existing **DLP policies** (`Get-DlpCompliancePolicy`), flagging any in **enforce** vs **simulation/test** mode,
   - existing **retention labels** (`Get-ComplianceTag`) and **retention policies** (`Get-RetentionCompliancePolicy`),
   - available **sensitive information types** relevant to education records (`Get-DlpSensitiveInformationType`),
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies** (`Get-UnifiedAuditLogRetentionPolicy`).
2. Run `CMPFERPA-Scope.ps1` (read-only) to enumerate the intended in-scope education-record locations, mailboxes/sites, device-onboarding state, and the role groups it can see (Requirement 2.2/2.4).
3. Record the gaps against the three control domains. **Pass gate:** a written current-state for classification, DLP, and retention/audit.

## Step 2 — Design the obligation-to-control map (Design)
1. With compliance/registrar/records/legal (Requirement 2.5), populate the `Control Map – FERPA – Purview` register: for each in-scope obligation, name the Purview control object that implements it, the classification/DLP/retention scope, the permitted-disclosure exceptions, and the approver. **What is an education record and which disclosures are permitted are the institution's determinations; you provide the register and the technical control.**
2. Map the obligations to the standard named artifacts:
   - Identify & protect → `Protect – FERPA Education Records – Confidential` (sensitivity label) + `Protect – FERPA Education Records – Publish` (label publish policy), keyed off the education-record **sensitive information types / trainable classifiers**.
   - Prevent disclosure → `DLP – FERPA Education Records – Simulate` (DLP policy, built in simulation).
   - Records lifecycle → `Retention – FERPA Records – Publish` (retention policy) + `Disposition – FERPA Records – Review` (disposition stage).
   - Access evidence → `Audit Retention – FERPA Evidence – LongTerm`.
   - Control tracking → `Assessment – FERPA Controls – Program` (Compliance Manager).
3. Define the pilot scope `FERPA Pilot – Education Records – Stage1` (Requirement 2.8) and the permitted-disclosure exceptions for DLP (Requirement 2.6). **Pass gate:** the control map, records schedule, disclosure exceptions, pilot, and approvals are documented.

## Step 3 — Configure the classification & labeling control (Configure → Pilot)
1. Confirm the education-record **sensitive information types / trainable classifiers** exist and match your data (Requirement 2.4). Create the sensitivity label and publish it to the pilot with the helper, `-WhatIf` first (prints the exact `New-Label`/`New-LabelPolicy` it would run):
   - `CMPFERPA-Configure.ps1 -Control Label -WhatIf` → review → `-Commit` (creates `Protect – FERPA Education Records – Confidential` and publishes it via `Protect – FERPA Education Records – Publish` scoped to the pilot).
2. Validate the label appears to pilot users and applies to education-record content (Testing Gate 2). Where the design calls for **encryption/marking**, confirm the label's protection settings in-portal before wider publish. **Pass gate:** the label exists, is published to the pilot, and applies. **Rollback:** unpublish/remove via `-Control Label -Remove -Commit`.

## Step 4 — Configure the disclosure-prevention (DLP) control — IN SIMULATION (Configure → Pilot)
1. **Build the DLP policy in simulation mode.** The helper creates it in test/simulation, scoped to the pilot locations, matching the education-record sensitive information types / the sensitivity label, with the **permitted-disclosure exceptions** you supply (Requirement 2.6):
   - `CMPFERPA-Configure.ps1 -Control DLP -PilotScope "FERPA Pilot – Education Records – Stage1" -WhatIf` → review → `-Commit` (creates `DLP – FERPA Education Records – Simulate` via `New-DlpCompliancePolicy -Mode Enable` in **TestWithoutNotifications/simulation** and `New-DlpComplianceRule` with the conditions your compliance/registrar function specified — **the match logic and exceptions are compliance's determination**).
2. Confirm the policy generates **simulation events** against benign education-record test content across the in-scope workloads **without blocking users**, and that permitted-disclosure exceptions suppress false positives. **Do not enforce tenant-wide; do not switch to block until validation passes and sign-off is complete.**
3. **Pass gate:** the DLP policy exists in **simulation**, is scoped to the pilot, and surfaces expected matches with acceptable false-positive rate. **Rollback:** disable/remove the policy (`-Control DLP -Remove -Commit`); no user content is altered by a simulation-mode policy.

## Step 5 — Configure the retention & audit-evidence controls (Configure)
1. **Retention.** Create the education-record retention policy pilot-first (`-Control Retention`): `CMPFERPA-Configure.ps1 -Control Retention -WhatIf` → review → `-Commit` (creates `Retention – FERPA Records – Publish` at the duration your records schedule requires; **verify accepted `RetentionDuration` values**). Where disposition review is required, configure `Disposition – FERPA Records – Review`.
2. **Audit evidence.** Confirm unified audit is on (Requirement 2.7). Create the evidence-retention policy pilot-first: `CMPFERPA-Configure.ps1 -Control Audit -PolicyName "Audit Retention – FERPA Evidence – LongTerm" -WhatIf` → review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your compliance function requires as access evidence, at the agreed duration and a unique priority). **Verify accepted `RetentionDuration` values and that the long-term tier is licensed** (Requirement 2.1).
3. **Pass gate:** `CMPFERPA-Discovery.ps1` lists the retention and audit policies with the expected duration/scope/priority. **Rollback:** `-Control Retention -Remove -Commit` / `-Control Audit -PolicyName "…" -Remove -Commit` (already-retained records age out under remaining rules).

## Step 6 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign the assessment `Assessment – FERPA Controls – Program` from a FERPA-relevant **assessment template** (**template availability depends on your licensing — verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links to the `Control Map – FERPA – Purview` register). **Pass gate:** the assessment reflects the configured controls with evidence links. *(Compliance Manager assessment content and applicability are compliance's determination; no cmdlet invents this — it is authored in-portal.)*

## Step 7 — Validate the controls and generate evidence (Validate)
1. Run `CMPFERPA-Validate.ps1` (read-only) to score the program across gates: the education-record label present and published, the DLP policy present in **simulation** with exceptions, retention scoped, audit ingestion on with the evidence policy in place, and the pilot scope covered.
2. Run `CMPFERPA-Report.ps1` (read-only) to produce `Evidence – FERPA Controls – Binder` — a control → Purview object → configuration → proof export (CSV/JSON) for the compliance/audit file, cross-referenced to `Control Map – FERPA – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the pilot scope and the evidence binder is generated.

## Step 8 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and compliance/registrar signs off, expand scope: publish the sensitivity label to the full in-scope population, extend retention and audit-evidence policies, and **move the DLP policy from simulation to enforcement** (block / block-with-override per the approved actions) on the approved scope — each under change control.
2. Configure the `Disposition – FERPA Records – Review` stage so end-of-retention disposal is reviewed, not automatic (where the records schedule requires disposition review).
3. Schedule the read-only chain (`CMPFERPA-Discovery.ps1` → `CMPFERPA-Validate.ps1` → `CMPFERPA-Report.ps1`) on a cadence so drift — a DLP policy reverted to simulation or disabled, a removed label scope, a lapsed license, audit turned off — is caught, and re-generate the evidence binder before each audit. **Pass gate:** controls enforced on the approved scope, evidence binder current, monitoring cadence scheduled. Hand the register, binder, and runbook to the compliance/registrar function as the standing procedure.
