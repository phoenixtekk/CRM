# 3. Implementation Guide — Microsoft Purview NIST 800-53 Compliance Program

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — DLP, labels,
retention, `*-UnifiedAuditLogRetentionPolicy`), **Exchange Online PowerShell** (`Connect-ExchangeOnline` —
`Get/Set-AdminAuditLogConfig`, mailbox audit), and **Microsoft Graph** (licensing/roles). Every write is
gated: scripts run **read-only or `-WhatIf`/simulation by default** and only change state with `-Commit`.
Artifact names follow the `<Purpose> – <Framework/Family> – <Stage>` convention from the Overview and are
reused verbatim.

> **Model:** Assess what 800-53 requires and what Purview already does, design the control-to-Purview map,
> configure the supporting controls, **pilot in simulation/test** on a limited scope, validate the evidence
> exists per family, then expand to enforcement. Pattern:
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**
> **The authorization determination on the resulting evidence is the AO's — deferred.** **Audit is not
> retroactive** — enable AU evidence before the assessment window, not during it.

## Step 1 — Assess licensing, roles, and current Purview control posture (Assess)
1. Run `CMPNIST-Scope.ps1` (read-only). It confirms connectivity to S&C PowerShell, Exchange Online, and
   Graph, checks that an **E5 / E5 Compliance**-bearing plan is present (Requirement 2.1), and reports which
   role-gated read operations succeed (Requirement 2.2).
2. Run `CMPNIST-Discovery.ps1` (read-only). It inventories the Purview controls that back the NIST families:
   - **AU** — `UnifiedAuditLogIngestionEnabled`, org mailbox auditing, existing audit-log retention policies;
   - **SC/MP/SI** — existing **DLP policies** (`Get-DlpCompliancePolicy`) and their **mode** (Enable / Test);
   - **AC/SC** — published **sensitivity labels** and label policies (`Get-Label`, `Get-LabelPolicy`);
   - **retention** — retention policies/labels (`Get-RetentionCompliancePolicy`).
3. In the Purview portal, confirm **Compliance Manager** is visible and the **NIST SP 800-53** template is
   listable under `Compliance Manager → Assessment templates` (visibility depends on role + licensing —
   Requirements 2.1/2.2). **Pass gate:** you have a written current-state per control family — what exists,
   what mode it's in, and what's a gap.

## Step 2 — Create the Compliance Manager assessment (Assess → Design)
1. In the Purview portal → **Compliance Manager → Assessments → Add assessment**, create
   **`NIST 800-53 – Rev5 – Assessment`** from the **NIST SP 800-53 Rev. 5** template, scoped to the in-scope
   product/group (Requirement 2.4). *(Assessment creation and improvement-action evidence are portal
   operations — verify current Compliance Manager automation options for your tenant; the scripts inventory
   and validate the underlying controls, they do not create the assessment.)*
2. Review the improvement actions the template surfaces and note which are **Microsoft-managed** vs **your
   controls** — you evidence the latter. **Pass gate:** the assessment exists and its improvement actions are
   visible with an initial score.

## Step 3 — Build the control-to-Purview map (Design)
1. With your compliance/security stakeholders and the **tailored baseline** (Requirement 2.5), record
   **`NIST 800-53 – Control-to-Purview – Map`**: for each in-scope family, the Purview capability that
   implements it and the concrete artifact that will evidence it. Baseline mapping:
   - **AU** → Purview **Audit** + `Control Evidence – NIST AU – Audit Retention`.
   - **SC-8 / SC-28 (protect data in transit/at rest)** → **sensitivity-label encryption** + **message
     encryption** + `Control Evidence – NIST SC-MP – DLP (Simulation)`.
   - **MP-7 (media protection)** → **endpoint/removable-media DLP** (same policy or a dedicated one).
   - **AC-3 / AC-6 (access enforcement / least privilege)** → **label-based encryption & usage rights** and
     **DLP sharing restrictions** (note: identity/Conditional Access is **Entra**, recorded as inherited).
   - **SI-4 (monitoring)** → **DLP** alerts + **DSPM** posture.
   - **CA / RA** → the Compliance Manager **assessment** + **DSPM** (visibility; **authorization deferred**).
   - **CM / PL / PM** → Compliance Manager improvement actions & program record.
2. Explicitly list the families Purview **does not** cover technically (PE, PS, AT, most of IR) as **deferred
   to your program** — the map must be honest about coverage.
3. Define the **pilot scope** `NIST Pilot – Control Set – Stage1` (Requirement 2.7). **Pass gate:** the map is
   documented and approved, with each in-scope control marked *Purview-covered* or *deferred*.

## Step 4 — Configure the AU family: audit + audit-evidence retention (Configure)
1. If Step 1 showed unified audit **off**, enable it under change control:
   `CMPNIST-Set-ControlPolicy.ps1 -EnableUnifiedAudit -WhatIf` → review → re-run with `-Commit`. (Runs
   `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`; activation can take time; not retroactive.)
2. Create the audit-evidence retention policy to the compliance/records requirement (Requirement 2.6):
   `CMPNIST-Set-ControlPolicy.ps1 -AuditRetentionName "Control Evidence – NIST AU – Audit Retention" -RecordTypes AzureActiveDirectory,ExchangeItem,SharePointFileOperation -Duration OneYear -Priority 100 -WhatIf`
   → review the exact `New-UnifiedAuditLogRetentionPolicy` → `-Commit`. **Verify accepted `RetentionDuration`
   values + licensing** before committing.
3. **Pass gate:** `CMPNIST-Discovery.ps1` shows ingestion `True` and the AU retention policy present with the
   agreed duration. **Rollback:** enabling audit is non-destructive; remove the retention policy with
   `CMPNIST-Set-ControlPolicy.ps1 -AuditRetentionName "…" -Remove -Commit`.

## Step 5 — Configure the SC/MP/SI supporting DLP control in SIMULATION (Configure → Pilot)
1. Create the control-support DLP policy **in simulation/test mode** (never straight to enforce):
   `CMPNIST-Set-ControlPolicy.ps1 -DlpPolicyName "Control Evidence – NIST SC-MP – DLP (Simulation)" -Workloads Exchange,SharePoint,OneDrive,Endpoint -PilotGroup "NIST Pilot – Control Set – Stage1" -WhatIf`
   → review the exact `New-DlpCompliancePolicy -Mode TestWithoutNotifications` + `New-DlpComplianceRule` it
   would run → re-run with `-Commit`. The policy is created in **test mode** (`TestWithoutNotifications`), so
   it **detects and evidences without blocking** users.
2. Confirm the rule's sensitive-information / label conditions match your impact-level data (Requirement 2.4);
   the determination of *which* information types apply is compliance/security's, not the script's.
3. **Pass gate:** `CMPNIST-Discovery.ps1` lists the DLP policy with `Mode = TestWithoutNotifications` scoped to
   the pilot. **Rollback:** `CMPNIST-Set-ControlPolicy.ps1 -DlpPolicyName "…" -Remove -Commit` (simulation
   policies are non-blocking; removal is clean).

## Step 6 — Configure the AC/SC label & encryption evidence (Configure)
1. Confirm at least one **sensitivity label with encryption/usage rights** is published to the pilot scope to
   evidence AC-3/SC-28 (label taxonomy/design is a separate solution — here you confirm/reference it). If none
   exists, that gap is recorded in the map and handed to the labeling workstream.
2. Where message-level protection is required (SC-8), confirm **message encryption** is available/configured.
   These are **portal/label** configurations; `CMPNIST-Discovery.ps1` reports published labels and label
   policies as evidence they exist. **Pass gate:** the labels/encryption that the map cites as AC/SC evidence
   are present and published to the pilot, or the gap is recorded and assigned.

## Step 7 — Validate control evidence exists per family (Validate)
1. Run `CMPNIST-Validate.ps1` (read-only). Against `NIST 800-53 – Control-to-Purview – Map`, it checks each
   Purview-covered family has its evidence: audit on + AU retention present, the DLP policy present (and its
   mode), labels published, retention configured, and the assessment referenced. It emits a per-family
   **pass/fail** with the missing item named.
2. Resolve any red family (return to the relevant step). **Pass gate:** every Purview-covered family is green
   for the pilot scope; every deferred family is explicitly marked deferred.

## Step 8 — Produce the control-evidence report / package (Validate → Evidence)
1. Run `CMPNIST-Report.ps1` to produce **`NIST 800-53 – Control Evidence – Report`** — the family-to-Purview
   artifact map with status, exportable (CSV/HTML) for the assessment package.
2. Attach the concrete artifacts to the corresponding **Compliance Manager improvement actions** in the portal
   (policy exports from Discovery, the audit-config snapshot, the DLP-policy definition, published-label list)
   per your evidence-handling requirement (Requirement 2.8). **Pass gate:** the report is generated and each
   Purview-covered control has an attached artifact. **The AO/assessor judges sufficiency and makes the
   authorization determination — deferred.**

## Step 9 — Expand to enforcement and maintain (Expand)
1. Once the pilot passes and the simulation DLP policy shows the expected (benign) detections, move it to
   enforce under change control:
   `CMPNIST-Set-ControlPolicy.ps1 -DlpPolicyName "Control Evidence – NIST SC-MP – DLP (Simulation)" -SetMode Enable -WhatIf` → review → `-Commit` (sets `-Mode Enable`). Consider renaming/annotating the policy to drop
   "(Simulation)" once enforcing, and extend scope beyond the pilot group.
2. Schedule the read-only chain (`CMPNIST-Discovery.ps1` → `CMPNIST-Validate.ps1` → `CMPNIST-Report.ps1`) on a
   cadence so **control drift** — audit disabled, a DLP policy deleted or flipped to test, a label unpublished,
   a lapsed license — is caught between assessments and the evidence stays current.
3. Hand the map, the validation scorecard, and the evidence report to your compliance/security function as the
   maintained program. **Pass gate:** enforcement is live for the agreed scope, the monitoring cadence is
   scheduled, and the evidence package is current. **Authorization remains the AO's decision.**
