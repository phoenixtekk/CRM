# 3. Implementation Guide — Microsoft Purview for Government

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, `*-ComplianceTag`/
`*-RetentionCompliancePolicy`, and `*-UnifiedAuditLogRetentionPolicy` cmdlets), and **Microsoft Graph**
(licensing). Every write is gated: scripts run **read-only or `-WhatIf` by default** and only change state
with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and
are reused verbatim.

> **Model:** Assess the controls/licensing/cloud you have → design the obligation-to-control map with
> compliance/security/legal → configure sensitivity labels, DLP/endpoint DLP, retention, and audit evidence
> → **pilot in simulation/test mode** → validate and evidence → expand to enforcement. Pattern: **Assess →
> Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Sovereign-cloud note:** in GCC High/DoD you MUST connect with the cloud endpoint —
> `Connect-IPPSSession -ConnectionUri <your cloud's S&C endpoint>` and `Connect-MgGraph -Environment
> USGov|USGovDoD`. **Verify the exact endpoint/environment for your cloud** before running any step.
>
> **Determination boundary:** which data is CJI/CUI/ITAR, which CMMC level applies, retention durations, and
> whether a configuration *satisfies* CJIS/CMMC/NIST 800-171/ITAR are **compliance/security/records/legal**
> determinations. This guide configures the control and evidences it; it does not make the determination or
> claim any authorization/certification. **DLP is high-impact — never enforce a policy that has not passed
> simulation and sign-off; never publish an encrypting label broadly before piloting access outcomes.**

## Step 1 — Assess current controls, licensing, and cloud (Assess)
1. Run `INDGOV-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph
   (pass your cloud endpoints where applicable) and reports:
   - compliance licensing present (sensitivity-label / DLP / Audit-Premium-bearing plans — **verify plan
     names for your tenant and cloud**),
   - existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`), flagging which
     **encrypt**,
   - existing **DLP policies** (`Get-DlpCompliancePolicy`), flagging **mode** (simulation vs enforce) and any
     with **endpoint (Devices)** locations,
   - existing **retention labels/policies** (`Get-ComplianceTag` / `Get-RetentionCompliancePolicy`),
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies**
     (`Get-UnifiedAuditLogRetentionPolicy`).
2. Run `INDGOV-Scope.ps1` (read-only) to enumerate the intended in-scope population, mailboxes/sites, the
   role groups it can see, and endpoint-onboarding readiness pointers (Requirement 2.2/2.4).
3. Record the gaps across the control domains. **Pass gate:** a written current-state for labels, DLP/endpoint
   DLP, retention, and audit — and a confirmed cloud (GCC/GCC High/DoD).

## Step 2 — Design the obligation-to-control map (Design)
1. With compliance/security/records/legal (Requirement 2.5), populate the `Control Map – Gov – Purview`
   register: for each in-scope obligation (CJIS, CMMC/NIST 800-171, ITAR), name the controlled-data type, the
   Purview control object that protects it, the required retention/audit, and the approver. **The
   classification and rule-to-control mapping are governance's determination; you provide the register and the
   technical control.**
2. Map the obligations to the standard named artifacts:
   - CJI protection → `Protect – Gov CJI – Restricted` (encrypting label).
   - CUI protection → `Protect – Gov CUI – Controlled` (encrypting label).
   - ITAR technical-data protection → `Protect – Gov ITAR – Controlled` (encrypting label, with U.S.-person
     access constraints per legal).
   - Egress prevention → `DLP – Gov Controlled Data – Simulate` (services) + `DLP – Gov Endpoint Egress –
     Simulate` (devices).
   - Records preservation → `Retention – Gov Records – Publish`.
   - Audit evidence → `Audit Retention – Gov Evidence – LongTerm`.
   - Control tracking → `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` (Compliance Manager).
3. Define the pilot scope `Gov Pilot – Controlled Data – Stage1` (Requirement 2.8) and the encryption/access
   sign-off for the labels (Requirement 2.6). **Pass gate:** the control map, retention schedule, encryption/
   access design, pilot, and approvals are documented.

## Step 3 — Configure the sensitivity labels — pilot access outcomes first (Configure → Pilot)
1. Create the three government labels with the helper, `-WhatIf` first (prints the exact `New-Label` it would
   run). **Pilot on non-production content** and confirm who can open/decrypt before broad publish:
   - `INDGOV-Configure.ps1 -Control Labels -WhatIf` → review → `-Commit` (creates
     `Protect – Gov CJI – Restricted`, `Protect – Gov CUI – Controlled`, `Protect – Gov ITAR – Controlled`).
   **Define the encryption/rights per label in-portal** (who may decrypt; for ITAR, the U.S.-person access
   constraint your legal function specified — **that access rule is legal's determination**).
2. Publish the labels to the **pilot scope only** first via a label policy (`New-LabelPolicy` scoped to
   `Gov Pilot – Controlled Data – Stage1`), confirm the labels appear and encrypt as designed, then expand
   publish on sign-off.
3. **Pass gate:** `INDGOV-Discovery.ps1` lists the labels with the expected encryption, published to the
   pilot; pilot users can apply them and access behaves as designed. **Rollback:** unpublish the label policy
   / remove the pilot labels (`-Control Labels -Remove -Commit`); note that content already encrypted retains
   its protection — verify decryption/access recovery in your tenant before broad use.

## Step 4 — Configure the DLP controls — IN SIMULATION (Configure → Pilot)
1. **Create both DLP policies in simulation/test mode**, scoped to the pilot. The helper defaults DLP to
   simulation and `-WhatIf`:
   - Services DLP: `INDGOV-Configure.ps1 -Control DLP -WhatIf` → review → `-Commit` (creates
     `DLP – Gov Controlled Data – Simulate` across Exchange/SharePoint/OneDrive/Teams, in **simulation**, with
     the conditions your compliance/security function specified — CJI/CUI/ITAR sensitive-info types and/or the
     government labels — **the conditions/SITs are governance's determination**).
   - Endpoint DLP: `INDGOV-Configure.ps1 -Control EndpointDLP -WhatIf` → review → `-Commit` (creates
     `DLP – Gov Endpoint Egress – Simulate` for **Devices**, in **simulation**, covering USB/print/cloud-upload
     egress). **Requires devices onboarded and endpoint DLP licensed/available in your cloud (Requirement
     2.4/2.1).**
2. Let simulation run and review **what would have matched/blocked** with `INDGOV-Report.ps1` — tune
   conditions to reduce false positives/negatives **before** any enforcement. **Do not enforce yet.**
3. **Pass gate:** both DLP policies exist **in simulation**, scoped to the pilot, and simulation surfaces the
   expected controlled-data matches without blocking. **Rollback:** remove the policy
   (`-Control DLP|EndpointDLP -Remove -Commit`) — simulation makes no user-facing change, so rollback is
   clean.

## Step 5 — Configure the records-retention and audit-evidence controls (Configure)
1. Create the government records retention publish policy pilot-first:
   - `INDGOV-Configure.ps1 -Control Retention -WhatIf` → review → `-Commit` (creates a retention label +
     `Retention – Gov Records – Publish` scoped to the pilot; **confirm the retention duration/disposition
     with records — that is their determination**).
2. Confirm unified audit is on (Requirement 2.7), then create the evidence-retention policy:
   - `INDGOV-Configure.ps1 -Control Audit -PolicyName "Audit Retention – Gov Evidence – LongTerm" -WhatIf` →
     review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your
     compliance function requires as evidence, at the agreed duration and a unique priority). **Verify accepted
     `RetentionDuration` values and that the long-term tier is licensed in your cloud (Requirement 2.1).**
3. **Pass gate:** `INDGOV-Discovery.ps1` lists the retention policy and the audit retention policy with the
   expected duration/priority. **Rollback:** `-Control Retention|Audit -Remove -Commit` (already-retained
   records age out under remaining rules).

## Step 6 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign
   `Assessment – Gov Controls (CJIS/CMMC/NIST 800-171) – Program` from the relevant **assessment template(s)**
   — CJIS Security Policy, CMMC, and/or NIST SP 800-171 (**template availability depends on your licensing and
   cloud — verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links
   to `Control Map – Gov – Purview`). **Pass gate:** the assessment reflects the configured controls with
   evidence links. *(Assessment content and applicability — and which CMMC level applies — are compliance's
   determination; no cmdlet invents this, it is authored in-portal.)*

## Step 7 — Validate the controls and generate evidence (Validate)
1. Run `INDGOV-Validate.ps1` (read-only) to score the program across gates: labels present and encrypting and
   published to the pilot; DLP + endpoint DLP present **in simulation**; retention present; audit ingestion on
   with the evidence policy in place; the pilot scope covered.
2. Run `INDGOV-Report.ps1` (read-only) to produce `Evidence – Gov Controls – Binder` — a control → Purview
   object → configuration → proof export (CSV/JSON) plus the **DLP simulation-match** summary — for the
   compliance/assessment file, cross-referenced to `Control Map – Gov – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the
   pilot scope and the evidence binder is generated.

## Step 8 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and compliance/security sign off, expand scope: publish the labels to the full
   in-scope population, **move `DLP – Gov Controlled Data – Simulate` and `DLP – Gov Endpoint Egress –
   Simulate` from simulation to enforce** (rename/re-stage per your convention if desired, keeping the control
   traceable), and extend the retention and audit-evidence policies — each under change control.
2. Schedule the read-only chain (`INDGOV-Discovery.ps1` → `INDGOV-Validate.ps1` → `INDGOV-Report.ps1`) on a
   cadence so drift — a DLP policy dropped back to simulation or disabled, an unpublished label, a lapsed
   license, audit turned off, a device off-boarded — is caught, and re-generate the evidence binder before
   each assessment. **Pass gate:** controls enforced on the approved scope, evidence binder current,
   monitoring cadence scheduled. Hand the register, binder, and runbook to the compliance function as the
   standing procedure. **This delivers and evidences the controls; it does not certify CJIS/CMMC/ITAR
   compliance — that determination is your governance functions'.**
