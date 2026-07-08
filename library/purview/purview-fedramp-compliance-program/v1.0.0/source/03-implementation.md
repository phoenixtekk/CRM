# 3. Implementation Guide — Microsoft Purview FedRAMP Compliance Program

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`,
`*-RetentionCompliancePolicy`/`*-ComplianceTag`, and `*-UnifiedAuditLogRetentionPolicy` cmdlets), and
**Microsoft Graph** (licensing). Every write is gated: scripts run **read-only or `-WhatIf` by default**
and only change state with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>`
convention from the Overview and are reused verbatim.

> **Model:** Assess the controls/licensing you have → design the NIST-800-53-to-Purview control map with
> security/compliance → configure information protection, DLP (in test/simulation), and audit/retention
> evidence → **pilot in simulation/test/disabled mode** → validate and evidence → expand to enforcement.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Determination boundary:** the FedRAMP baseline, which NIST 800-53 controls apply, whether a Purview
> object satisfies a control, and whether the tenant supports an ATO are **security/compliance/legal**
> determinations. This guide configures the control and evidences it; it does not make the determination
> and asserts no certification/ATO. **DLP is enforced only after the test/simulation pilot passes and
> sign-off is obtained.**

## Step 1 — Assess current controls and licensing (Assess)
1. Run `CMPFEDRAMP-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph and reports:
   - compliance licensing present (information-protection / DLP / Audit Premium-bearing plans — **verify plan names for your tenant**),
   - existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`), flagging any that apply **encryption**,
   - existing **DLP policies** (`Get-DlpCompliancePolicy`) and their **Mode** (flagging any already in **Enable**/enforce),
   - existing **retention labels/policies** (`Get-ComplianceTag` / `Get-RetentionCompliancePolicy`),
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies** (`Get-UnifiedAuditLogRetentionPolicy`).
2. Run `CMPFEDRAMP-Scope.ps1` (read-only) to enumerate the intended controlled-data owners group, in-scope mailboxes/sites, and the role groups it can see (Requirement 2.2/2.4).
3. Record the gaps against the three control domains. **Pass gate:** a written current-state for information protection, DLP, and audit/retention.

## Step 2 — Design the NIST-800-53-to-control map (Design)
1. With security/compliance (Requirement 2.5), populate the `Control Map – FedRAMP – Purview` register: for each in-scope NIST 800-53 control, name the Purview control object that implements it, the required scope, and the approver. **The control-to-object mapping is security/compliance's determination; you provide the register and the technical control.**
2. Map the control families to the standard named artifacts:
   - Information protection (**AC / MP / SC**) → `Protect – FedRAMP Controlled – Confidential` (label) + `Protect – FedRAMP Controlled – Publish` (label policy).
   - Data-loss prevention (**SC / AC**) → `DLP – FedRAMP Controlled – Simulate` (built in test/simulation mode).
   - Audit evidence (**AU**) → `Audit Retention – FedRAMP Evidence – LongTerm`; controlled-records retention → `Retention – FedRAMP Records – Publish`.
   - Control tracking → `Assessment – FedRAMP Controls – Program` (Compliance Manager).
3. Define the pilot scope `FedRAMP Pilot – Controlled Data – Stage1` (Requirement 2.8). **Pass gate:** the control map, baseline, pilot, and approvals are documented.

## Step 3 — Configure the information-protection control (Configure → Pilot)
1. Create the sensitivity label with the helper, `-WhatIf` first (prints the exact `New-Label` it would run). Pilot on benign content before applying encryption tenant-wide:
   - `CMPFEDRAMP-Configure.ps1 -Control Label -WhatIf` → review → `-Commit` (creates `Protect – FedRAMP Controlled – Confidential`; add **encryption**/rights protection per the design — encryption changes access, so pilot on benign content first).
2. Publish the label to the pilot scope with a label policy:
   - `CMPFEDRAMP-Configure.ps1 -Control Label -Publish -PilotScope "FedRAMP Pilot – Controlled Data – Stage1" -WhatIf` → review → `-Commit` (creates `Protect – FedRAMP Controlled – Publish` scoped to the pilot).
3. **Pass gate:** `CMPFEDRAMP-Discovery.ps1` lists the label and its publish policy scoped to the pilot; the label applies to benign pilot content (Testing Gate 2). **Rollback:** the label policy and label are removable (`-Control Label -Remove -Commit`) before wider adoption; once encryption-protected content exists, plan removal carefully (access/recovery implications — verify in your tenant).

## Step 4 — Configure the DLP control — IN TEST / SIMULATION MODE (Configure → Pilot)
1. **Build the DLP policy in test/simulation mode** (no blocking) with the conditions your security/compliance function specified (the sensitive info types / the `Protect – FedRAMP Controlled – Confidential` label as the match). The helper defaults to `-WhatIf` and creates the policy in **test mode**:
   - `CMPFEDRAMP-Configure.ps1 -Control DLP -PilotScope "FedRAMP Pilot – Controlled Data – Stage1" -WhatIf` → review → `-Commit` (creates `DLP – FedRAMP Controlled – Simulate` via `New-DlpCompliancePolicy -Mode TestWithoutNotifications` plus a `New-DlpComplianceRule` matching the controlled-data condition — **created in simulation/test mode; it does NOT block**).
2. Confirm the policy **matches and reports** against **benign test content** for the pilot scope without blocking any action, and review the DLP simulation/overview results in-portal. **Do not enforce (switch to `Enable`) until the pilot passes and sign-off is obtained.**
3. **Pass gate:** the DLP policy exists in **test/simulation** mode, is pilot-scoped, and reports matches on test content with no enforcement. **Rollback:** disable/remove the test policy (`-Control DLP -Remove -Commit`); in test mode no user action is ever blocked, so there is nothing to reverse for end users.

## Step 5 — Configure the audit-evidence and retention controls (Configure)
1. Confirm unified audit is on (Requirement 2.7). Create the evidence-retention policy pilot-first:
   - `CMPFEDRAMP-Configure.ps1 -Control Audit -PolicyName "Audit Retention – FedRAMP Evidence – LongTerm" -WhatIf` → review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your compliance function requires as **AU** evidence, at the agreed duration and a unique priority). **Verify accepted `RetentionDuration` values and that the long-term tier is licensed** (Requirement 2.1).
2. Where the design calls for controlled-records preservation, create the retention policy:
   - `CMPFEDRAMP-Configure.ps1 -Control Retention -PilotScope "FedRAMP Pilot – Controlled Data – Stage1" -WhatIf` → review → `-Commit` (creates `Retention – FedRAMP Records – Publish` scoped to the pilot locations).
3. **Pass gate:** `CMPFEDRAMP-Discovery.ps1` lists the audit retention policy (expected duration/priority) and the retention policy scoped to the pilot. **Rollback:** `-Control Audit -Remove -Commit` / `-Control Retention -Remove -Commit` (already-retained records age out under remaining rules).

## Step 6 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign the assessment `Assessment – FedRAMP Controls – Program` from a **FedRAMP assessment template** (e.g. **FedRAMP Moderate** or **FedRAMP High** — **template availability depends on your licensing; verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links to the `Control Map – FedRAMP – Purview` register). **Pass gate:** the assessment reflects the configured controls with evidence links. *(Compliance Manager assessment content, baseline choice, and applicability are security/compliance's determination; no cmdlet invents this — it is authored in-portal.)*

## Step 7 — Validate the controls and generate evidence (Validate)
1. Run `CMPFEDRAMP-Validate.ps1` (read-only) to score the program across gates: label present (and encryption state as designed), DLP present **in test/simulation** and pilot-scoped, audit ingestion on with the evidence policy in place, retention policy scoped, and the pilot scope covered.
2. Run `CMPFEDRAMP-Report.ps1` (read-only) to produce `Evidence – FedRAMP Controls – Binder` — a control → Purview object → configuration → proof export (CSV/JSON) for the security/compliance package, cross-referenced to `Control Map – FedRAMP – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the pilot scope and the evidence binder is generated.

## Step 8 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and security/compliance signs off, expand scope: publish the label to the full controlled-data scope, extend the retention/audit-evidence policies, and **move the DLP policy from test/simulation to Enable (enforce)** on the approved scope — each under change control.
   - `CMPFEDRAMP-Configure.ps1 -Control DLP -Enforce -WhatIf` → review → `-Commit` (switches `DLP – FedRAMP Controlled – Simulate` to `-Mode Enable`; consider renaming/annotating that it is now enforced). **Only after the pilot passes and sign-off is obtained.**
2. Schedule the read-only chain (`CMPFEDRAMP-Discovery.ps1` → `CMPFEDRAMP-Validate.ps1` → `CMPFEDRAMP-Report.ps1`) on a cadence so drift — a DLP policy silently disabled, a label unpublished, a lapsed license, audit turned off — is caught, and re-generate the evidence binder before each assessment cycle. **Pass gate:** controls enforced on the approved scope, evidence binder current, monitoring cadence scheduled. Hand the register, binder, and runbook to the security/compliance function as the standing procedure.
