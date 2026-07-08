# 3. Implementation Guide — Microsoft Purview FINRA/SEC Compliance Program

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-RetentionCompliancePolicy`, `*-ComplianceTag`, `*-SupervisoryReview*`, and
`*-UnifiedAuditLogRetentionPolicy` cmdlets), and **Microsoft Graph** (licensing). Every write is gated:
scripts run **read-only or `-WhatIf` by default** and only change state with `-Commit`. Artifact names
follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess the controls/licensing you have → design the rule-to-control map with
> compliance/legal → configure records retention, communication supervision, and audit evidence →
> **pilot in simulation/test/disabled mode** → validate and evidence → expand to enforcement. Pattern:
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Determination boundary:** which rules apply, retention durations, supervisory scope/lexicons, and
> whether a configuration *satisfies* FINRA/SEC are **compliance/records/legal** determinations. This
> guide configures the control and evidences it; it does not make the determination. **A
> `regulatory-records` label is effectively irreversible — never apply it outside the pilot without
> explicit compliance sign-off.**

## Step 1 — Assess current controls and licensing (Assess)
1. Run `CMPFINRA-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph and reports:
   - compliance licensing present (records / Communication Compliance / Audit Premium-bearing plans — **verify plan names for your tenant**),
   - existing **retention labels** (`Get-ComplianceTag`) and **retention policies** (`Get-RetentionCompliancePolicy`), flagging any that are **records**/**regulatory records**,
   - existing **Communication Compliance** (supervisory-review) policies (`Get-SupervisoryReviewPolicyV2`),
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies** (`Get-UnifiedAuditLogRetentionPolicy`).
2. Run `CMPFINRA-Scope.ps1` (read-only) to enumerate the intended covered-persons group, in-scope mailboxes/sites, and the role groups it can see (Requirement 2.2/2.4).
3. Record the gaps against the three control domains. **Pass gate:** a written current-state for records, supervision, and audit.

## Step 2 — Design the rule-to-control map (Design)
1. With compliance/records/legal (Requirement 2.5), populate the `Control Map – FINRA/SEC – Purview` register: for each in-scope obligation, name the Purview control object that implements it, the required retention/supervisory scope, and the approver. **The rule-to-control mapping is compliance's determination; you provide the register and the technical control.**
2. Map the obligations to the standard named artifacts:
   - Records preservation → `Records – FINRA/SEC Regulated – Regulatory` (label) + `Retention – FINRA/SEC Records – Publish` (publish policy) + `Retention – FINRA/SEC Comms Store – Immutable` (comms-store retention).
   - Communication supervision → `Supervision – Registered Persons Comms – Test`.
   - Audit evidence → `Audit Retention – FINRA/SEC Evidence – LongTerm`.
   - Control tracking → `Assessment – FINRA/SEC Controls – Program` (Compliance Manager).
3. Define the pilot scope `FINRA/SEC Pilot – Registered Persons – Stage1` (Requirement 2.8) and the privacy/reviewer sign-off for supervision (Requirement 2.6). **Pass gate:** the control map, retention schedule, supervisory scope, pilot, and approvals are documented.

## Step 3 — Configure the records-preservation control (Configure → Pilot)
1. **Pilot with a non-regulatory records label first** to prove behavior safely. Create the labels and publish policy with the helper, `-WhatIf` first (prints the exact `New-ComplianceTag`/`New-RetentionCompliancePolicy` it would run):
   - `CMPFINRA-Configure.ps1 -Control Records -PilotLabel -WhatIf` → review → `-Commit` (creates a **records** — not regulatory — label for pilot testing, plus `Retention – FINRA/SEC Records – Publish` scoped to the pilot).
2. Validate the pilot label applies and preserves on pilot content (Testing Gate 2). **Only after compliance sign-off**, create the production **regulatory record** label `Records – FINRA/SEC Regulated – Regulatory` (immutable, un-disablable) and, where the design calls for immutable comms preservation, the `Retention – FINRA/SEC Comms Store – Immutable` location-based retention policy across Exchange/Teams:
   - `CMPFINRA-Configure.ps1 -Control Records -Regulatory -WhatIf` → review → `-Commit`.
3. **Pass gate:** `CMPFINRA-Discovery.ps1` lists the labels/policies with the expected records/regulatory behavior and scope. **Rollback:** the **non-regulatory** pilot label/policy is removable (`-Control Records -Remove -Commit`); a **regulatory-records** label is **not removable and its retention cannot be shortened by design** — this is why sign-off precedes it (verify behavior in your tenant before committing).

## Step 4 — Configure the audit-evidence control (Configure)
1. Confirm unified audit is on (Requirement 2.7). Create the evidence-retention policy pilot-first:
   - `CMPFINRA-Configure.ps1 -Control Audit -PolicyName "Audit Retention – FINRA/SEC Evidence – LongTerm" -WhatIf` → review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your compliance function requires as evidence, at the agreed duration and a unique priority). **Verify accepted `RetentionDuration` values and that the long-term tier is licensed** (Requirement 2.1).
2. **Pass gate:** `CMPFINRA-Discovery.ps1` lists the audit retention policy with the expected duration/priority. **Rollback:** `CMPFINRA-Configure.ps1 -Control Audit -PolicyName "…" -Remove -Commit` (already-retained records age out under remaining rules).

## Step 5 — Configure the communication-supervision control — IN TEST MODE (Configure → Pilot)
1. **Build the supervision policy in test/pilot mode** with reviewer separation in place (Requirement 2.6). The helper creates it disabled/test-scoped to the pilot covered persons:
   - `CMPFINRA-Configure.ps1 -Control Supervision -PilotScope "FINRA/SEC Pilot – Registered Persons – Stage1" -WhatIf` → review → `-Commit` (creates `Supervision – Registered Persons Comms – Test` via `New-SupervisoryReviewPolicyV2`, scoped to the pilot group and its supervising reviewers, with the conditions your compliance function specified — **the lexicon/conditions are compliance's determination**).
2. Confirm the policy generates review items against **benign test communications** for the pilot group, and that only the designated reviewers can see them. **Do not enforce tenant-wide, and do not action any real item — case actions/outcomes are HR/legal's.**
3. **Pass gate:** the test policy exists, is scoped to the pilot with correct reviewer separation, and surfaces test items. **Rollback:** disable/remove the test policy (`-Control Supervision -Remove -Commit`); no employee communications are altered by the control.

## Step 6 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign the assessment `Assessment – FINRA/SEC Controls – Program` from a FINRA/SEC-relevant **assessment template** (**template availability depends on your licensing — verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links to the `Control Map – FINRA/SEC – Purview` register). **Pass gate:** the assessment reflects the configured controls with evidence links. *(Compliance Manager assessment content and applicability are compliance's determination; no cmdlet invents this — it is authored in-portal.)*

## Step 7 — Validate the controls and generate evidence (Validate)
1. Run `CMPFINRA-Validate.ps1` (read-only) to score the program across gates: labels/policies present and correctly typed, comms-store retention scoped, audit ingestion on with the evidence policy in place, the supervision policy present in test with reviewer separation, and the pilot scope covered.
2. Run `CMPFINRA-Report.ps1` (read-only) to produce `Evidence – FINRA/SEC Controls – Binder` — a control → Purview object → configuration → proof export (CSV/JSON) for the compliance/audit file, cross-referenced to `Control Map – FINRA/SEC – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the pilot scope and the evidence binder is generated.

## Step 8 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and compliance signs off, expand scope: publish the **regulatory-records** label to the full covered-persons/workload scope, extend the comms-store retention and audit-evidence policies, and **move the supervision policy from test to enforced** (compliance-approved) coverage — each under change control.
2. Configure the `Disposition – FINRA/SEC Records – Review` stage so end-of-retention disposal is reviewed, not automatic (where the records schedule requires disposition review).
3. Schedule the read-only chain (`CMPFINRA-Discovery.ps1` → `CMPFINRA-Validate.ps1` → `CMPFINRA-Report.ps1`) on a cadence so drift — a disabled policy, a removed label scope, a lapsed license, audit turned off — is caught, and re-generate the evidence binder before each exam. **Pass gate:** controls enforced tenant-wide on the approved scope, evidence binder current, monitoring cadence scheduled. Hand the register, binder, and runbook to the compliance function as the standing procedure.
