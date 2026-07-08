# 3. Implementation Guide — Microsoft Purview for Legal

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — the
`*-Label`/`*-LabelPolicy`, `*-DlpCompliancePolicy`/`*-DlpComplianceRule`, `*-ComplianceTag`,
`*-RetentionCompliancePolicy`, and `*-UnifiedAuditLogRetentionPolicy` cmdlets), and **Microsoft Graph**
(licensing). Every write is gated: scripts run **read-only or `-WhatIf` by default** and only change
state with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the
Overview and are reused verbatim.

> **Model:** Assess the controls/licensing you have → design the obligation-to-control map with
> legal/records → configure sensitivity labels, DLP (in simulation), matter retention, and audit
> evidence → **pilot in simulation/test/disabled mode** → validate and evidence → expand to enforcement.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Determination boundary:** what is privileged, how matters map, retention durations, disposition
> triggers, and which matters are under **legal hold** are **legal/records** determinations. This guide
> configures the control and evidences it; it does not make the determination. **DLP is enforced only
> after a validated simulation; a `regulatory-records` label is effectively irreversible — never apply it
> outside the pilot without explicit legal/records sign-off; legal holds are created/released by legal in
> eDiscovery, never by this work.**

## Step 1 — Assess current controls and licensing (Assess)
1. Run `INDLEGAL-Discovery.ps1` (read-only). It connects to Security & Compliance PowerShell and Graph and reports:
   - compliance licensing present (information-protection / DLP-endpoint / records / Audit-Premium-bearing plans — **verify plan names for your tenant**),
   - existing **sensitivity labels** (`Get-Label`) and **label policies** (`Get-LabelPolicy`), flagging any with **encryption**,
   - existing **DLP policies** (`Get-DlpCompliancePolicy`), flagging **mode** (Enable / TestWithNotifications / TestWithoutNotifications),
   - existing **retention labels** (`Get-ComplianceTag`) and **retention policies** (`Get-RetentionCompliancePolicy`), flagging any that are **records**/**regulatory records**,
   - `UnifiedAuditLogIngestionEnabled` and existing **audit retention policies** (`Get-UnifiedAuditLogRetentionPolicy`),
   - **read-only reference only:** any existing eDiscovery **case holds** (`Get-CaseHoldPolicy`) — so hold coverage is visible; the script never creates or changes a hold.
2. Run `INDLEGAL-Scope.ps1` (read-only) to enumerate the intended legal-population group, in-scope mailboxes/matter sites, and the role groups it can see (Requirement 2.2/2.4).
3. Record the gaps against the four control domains. **Pass gate:** a written current-state for labels, DLP, retention, and audit.

## Step 2 — Design the obligation-to-control map (Design)
1. With legal/records (Requirement 2.5), populate the `Control Map – Legal – Purview` register: for each in-scope obligation, name the Purview control object that implements it, the required label/DLP/retention behavior, the disposition trigger, and the approver. **Privilege, matter mapping, retention, and hold are legal's determination; you provide the register and the technical control.**
2. Map the obligations to the standard named artifacts:
   - Privilege/confidentiality → `Protect – Legal Privileged – Restricted` (encrypted label) + `Protect – Legal Matter Confidential – Confidential` (label), published to the legal population.
   - Inadvertent disclosure → `DLP – Legal Privileged – Simulate` (built in simulation).
   - Matter records → `Retention – Legal Matter Records – Publish` (retention label + publish policy) + `Disposition – Legal Records – Review` (disposition stage).
   - Audit evidence → `Audit Retention – Legal Evidence – LongTerm`.
   - Control tracking → `Assessment – Legal Controls – Program` (Compliance Manager).
3. Define the pilot scope `Legal Pilot – Privileged Data – Stage1` (Requirement 2.8) and the encryption/DLP/external-sharing decisions (Requirement 2.6). **Pass gate:** the control map, privilege scope, records schedule, pilot, and approvals are documented.

## Step 3 — Configure the sensitivity labels (Configure → Pilot)
1. Create the two labels with the helper, `-WhatIf` first (prints the exact `New-Label`/`New-LabelPolicy` it would run):
   - `INDLEGAL-Configure.ps1 -Control Labels -WhatIf` → review → `-Commit` (creates `Protect – Legal Privileged – Restricted` **with encryption** per legal's decryption/permission decision, and `Protect – Legal Matter Confidential – Confidential`; then a label policy publishing both to the **pilot** legal population).
2. **Publish to the pilot population first.** Confirm the labels appear in Office/Outlook for pilot users and that applying the privileged label encrypts as designed (Testing Gate 2/3). **Encryption/permission scope is legal's decision — do not broaden decryption beyond what legal approved.**
3. **Pass gate:** `INDLEGAL-Discovery.ps1` lists both labels and the pilot label policy, with the privileged label flagged encrypted. **Rollback:** unpublish the label policy / remove the pilot labels (`-Control Labels -Remove -Commit`); already-encrypted content stays encrypted (by design) — pilot with benign content so this is inconsequential.

## Step 4 — Configure the DLP control — IN SIMULATION (Configure → Pilot)
1. **Build the DLP policy in simulation/test mode** so it surfaces what *would* match and **blocks nothing**. The helper creates it in `TestWithNotifications` (or `TestWithoutNotifications`) scoped to the pilot:
   - `INDLEGAL-Configure.ps1 -Control DLP -Mode TestWithNotifications -WhatIf` → review → `-Commit` (creates `DLP – Legal Privileged – Simulate` via `New-DlpCompliancePolicy` across Exchange/SharePoint/OneDrive/Teams/Endpoint scoped to the pilot, plus a `New-DlpComplianceRule` matching the **privileged/matter labels** and/or the sensitive info types your legal function specified — **the match criteria are legal's determination**).
2. Let the simulation run, then review its matches: are the right items caught, and — critically — is legitimate legal sharing being **over-matched**? Tune the rule (labels, info types, exceptions for approved external counsel/court sharing) **still in simulation**. **Do not switch to Enable until the match review is clean and legal signs off.**
3. **Pass gate:** the DLP policy exists in a **test/simulation** mode, scoped to the pilot, and its match report is reviewed. **Rollback:** remove the policy (`-Control DLP -Remove -Commit`); in simulation nothing was ever blocked, so there is nothing to unwind.

## Step 5 — Configure the matter-records retention control (Configure → Pilot)
1. **Pilot with a non-regulatory records label first** to prove behavior safely. Create the retention label + publish policy with the helper, `-WhatIf` first:
   - `INDLEGAL-Configure.ps1 -Control Retention -WhatIf` → review → `-Commit` (creates a **records** — not regulatory — matter-retention label and the `Retention – Legal Matter Records – Publish` policy scoped to the pilot matter workloads, at the duration your records function specified — **duration/trigger are records' determination**).
2. Validate the label applies and preserves matter content (Testing Gate 5). Where the records schedule requires reviewed disposal, configure the `Disposition – Legal Records – Review` stage in-portal so end-of-retention disposal is reviewed, not automatic. **Only after legal/records sign-off**, and only where the schedule requires it, create any **regulatory-records** (immutable, non-removable) label — gated hardest of all.
3. **Legal hold note:** where a matter is under **legal hold**, the hold overrides disposal. **Creating, scoping, or releasing a hold is the legal function's action in eDiscovery** — this step references it (`Get-CaseHoldPolicy` read-only in Discovery) but never performs it. **Pass gate:** `INDLEGAL-Discovery.ps1` lists the retention label/policy with the expected records behavior and scope. **Rollback:** the **non-regulatory** pilot label/policy is removable (`-Control Retention -Remove -Commit`); a **regulatory-records** label is **not** removable by design — verify behavior in your tenant before committing.

## Step 6 — Configure the audit-evidence control (Configure)
1. Confirm unified audit is on (Requirement 2.7). Create the evidence-retention policy pilot-first:
   - `INDLEGAL-Configure.ps1 -Control Audit -PolicyName "Audit Retention – Legal Evidence – LongTerm" -WhatIf` → review → `-Commit` (creates a `New-UnifiedAuditLogRetentionPolicy` for the record types/operations your legal function requires as evidence — e.g. label changes, DLP matches, file/mail activity — at the agreed duration and a unique priority). **Verify accepted `RetentionDuration` values and that the long-term tier is licensed** (Requirement 2.1).
2. **Pass gate:** `INDLEGAL-Discovery.ps1` lists the audit retention policy with the expected duration/priority. **Rollback:** `INDLEGAL-Configure.ps1 -Control Audit -PolicyName "…" -Remove -Commit` (already-retained records age out under remaining rules).

## Step 7 — Track the program in Compliance Manager (Configure, in-portal)
1. In the Purview portal → **Compliance Manager**, create/assign the assessment `Assessment – Legal Controls – Program` from a relevant **assessment template** (**template availability depends on your licensing — verify in-portal**). Map its improvement actions to the Purview controls configured above.
2. Record, per improvement action, the implementing Purview object and its evidence location (this cross-links to the `Control Map – Legal – Purview` register). **Pass gate:** the assessment reflects the configured controls with evidence links. *(Compliance Manager assessment content and applicability are legal/compliance's determination; no cmdlet invents this — it is authored in-portal.)*

## Step 8 — Validate the controls and generate evidence (Validate)
1. Run `INDLEGAL-Validate.ps1` (read-only) to score the program across gates: both labels present (privileged encrypted), DLP present **in simulation/test**, matter-records retention present and scoped, audit ingestion on with the evidence policy in place, and the pilot scope covered.
2. Run `INDLEGAL-Report.ps1` (read-only) to produce `Evidence – Legal Controls – Binder` — a control → Purview object → configuration → proof export (CSV/JSON) for the legal/compliance file, cross-referenced to `Control Map – Legal – Purview`.
3. Complete the **Testing Guide** before expanding. **Pass gate:** the validation scorecard is green for the pilot scope and the evidence binder is generated.

## Step 9 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and legal/records sign off: publish the labels to the full legal population, **switch the DLP policy from simulation (Test) to Enable** on the approved scope, expand the matter-retention and audit-evidence policies, and — where the schedule requires — apply the regulatory-records label under sign-off. Each change is under change control.
2. Confirm the `Disposition – Legal Records – Review` stage governs end-of-retention disposal for the matters the schedule requires. **Coordinate — do not perform — legal-hold overrides with the legal function** (holds are created/released by legal in eDiscovery).
3. Schedule the read-only chain (`INDLEGAL-Discovery.ps1` → `INDLEGAL-Validate.ps1` → `INDLEGAL-Report.ps1`) on a cadence so drift — a DLP policy slipped back to test, an unpublished label, a lapsed license, audit turned off, a removed retention scope — is caught, and re-generate the evidence binder ahead of audits or matters. **Pass gate:** controls enforced on the approved scope, evidence binder current, monitoring cadence scheduled. Hand the register, binder, and runbook to legal/records as the standing procedure.
