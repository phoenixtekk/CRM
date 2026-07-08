# 3. Implementation Guide — Microsoft Purview SOX Compliance Program

Follow these steps **in order**. Configuration uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` — labels,
DLP, retention, `*-UnifiedAuditLogRetentionPolicy`), **Exchange Online PowerShell**
(`Connect-ExchangeOnline` — `Search-UnifiedAuditLog`, `Get/Set-AdminAuditLogConfig`), and **Microsoft
Graph** (licensing/roles). Every write is gated: scripts run **read-only or `-WhatIf` by default** and
only change state with `-Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention
from the Overview and are reused verbatim.

> **Model:** Assess the current state, design the SOX-to-Purview control map, configure the controls,
> **pilot** on the finance ring in simulation/test, validate each control and its evidence, then expand
> to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**
> **Audit is not retroactive** — enable logging before the period you intend to evidence.

## Step 1 — Assess current state and licensing (Assess)
1. Run `PURVSOX-Scope.ps1` (read-only) to confirm connectivity to S&C PowerShell, Exchange Online, and Graph; report the Purview **role groups** and members (Requirement 2.2), the **licensing** that gates advanced DLP/auto-labeling/long-term audit/Compliance Manager (2.1), and whether **Compliance Manager** and **DLP** are reachable (2.6).
2. Run `PURVSOX-Discovery.ps1` (read-only). It reports:
   - `UnifiedAuditLogIngestionEnabled` (is the evidence foundation on? — 2.4),
   - existing **sensitivity labels** and label policies, **DLP policies** and their **Mode** (Enable/Test/Disable), **retention policies**, and **audit log retention policies**,
   - which of the program's named artifacts already exist.
3. Record the gaps. **Pass gate:** you have a written current-state for audit, labels, DLP, retention, audit-retention, roles, and licensing.

## Step 2 — Map SOX objectives to Purview controls (Design)
1. With your SOX/ICFR, finance, records, and internal-audit owners (Requirement 2.5), confirm the control map from the Overview — each Purview control to its ITGC objective (access to programs & data, change management, IT operations, segregation of duties, records retention).
2. Agree the **in-scope financial data** (sites/Teams/mailboxes/OneDrive), the **classification intent** for the label, the **records-retention schedule** (their determination), and the **evidence** the external auditor expects.
3. Define the **pilot finance ring** `SOX Pilot – Finance Ring – Stage1` (Requirement 2.7) and the evidence runbooks in scope. **Pass gate:** the control map, scope, retention schedule, and pilot are documented and approved.

## Step 3 — Enable the evidence foundation: unified audit (Configure)
1. If Step 1 showed unified audit **off**, enable it under change control:
   `PURVSOX-ConfigureControls.ps1 -EnableUnifiedAudit -WhatIf` → review → re-run with `-Commit`. (Runs `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`; activation can take time.)
2. **Pass gate:** re-run `PURVSOX-Discovery.ps1` — ingestion is `True`. **Rollback:** enabling audit is non-destructive; it can be disabled again under change control, but doing so stops SOX evidence capture — avoid.

## Step 4 — Configure the financial-data classification (Configure → Pilot)
1. Create the sensitivity label `Financial – SOX Reporting – Confidential`, **pilot-first**:
   `PURVSOX-ConfigureControls.ps1 -Control Label -Name "Financial – SOX Reporting – Confidential" -WhatIf` → review the exact `New-Label` it would run → `-Commit`.
2. Publish it to the pilot ring only (limited-scope label policy), not tenant-wide:
   `PURVSOX-ConfigureControls.ps1 -Control LabelPolicy -Name "Financial – SOX Reporting – Confidential" -PilotUsers "financepilot@contoso.com" -WhatIf` → `-Commit`. (Auto-labeling, if licensed, is configured in **simulation mode** in the portal before it is turned on — 2.1.)
3. **Pass gate:** the label appears for pilot users and can be applied to a test financial document. **Rollback:** unpublish the label policy (`Remove` the scoped policy); the label definition can remain unpublished.

## Step 5 — Configure the financial-data DLP policy in SIMULATION (Configure → Pilot)
1. Create the DLP policy `DLP – SOX Financial Data – Simulation` **in test/simulation mode** (never enforce first):
   `PURVSOX-ConfigureControls.ps1 -Control Dlp -Name "DLP – SOX Financial Data – Simulation" -Workloads SharePoint,OneDrive,Exchange -PilotUsers "financepilot@contoso.com" -WhatIf` → review → `-Commit`. The script creates the policy with `-Mode TestWithNotifications` and a rule that keys off the `Financial – SOX Reporting – Confidential` label (and/or financial sensitive-info types you specify) — so it **reports** matches without blocking.
2. Let it run over the pilot window to gather exposure evidence. **Pass gate:** `PURVSOX-Validate.ps1` shows the policy in a **Test** mode and DLP simulation is registering matches. **Rollback:** `PURVSOX-ConfigureControls.ps1 -Control Dlp -Name "…" -Remove -Commit`.

## Step 6 — Configure SOX records retention (Configure → Pilot)
1. Create the retention policy `Retention – SOX Financial Records – Governed` on the **pilot scope**, with the **duration your records/legal function set** (their determination — Requirement 2.5):
   `PURVSOX-ConfigureControls.ps1 -Control Retention -Name "Retention – SOX Financial Records – Governed" -Workloads SharePoint -PilotSites "https://contoso.sharepoint.com/sites/FinancePilot" -RetainDays 2555 -WhatIf` → review → `-Commit`. (`-RetainDays` is a placeholder you set from the schedule; the script does **not** invent a period.)
2. **Pass gate:** the retention policy exists scoped to the pilot with the agreed duration/action. **Rollback:** `-Remove -Commit` (already-retained content ages out by remaining rules). **Note:** disposition/records **file-plan** determinations are deferred — this configures retention, it does not decide the schedule.

## Step 7 — Configure the financial-access audit retention policy (Configure)
1. Create `Audit Retention – Financial Data Access – SOX` so the access/change trail is kept for the review period, **pilot-first**:
   `PURVSOX-ConfigureControls.ps1 -Control AuditRetention -Name "Audit Retention – Financial Data Access – SOX" -RecordTypes SharePointFileOperation,ExchangeItem -Duration OneYear -Priority 150 -WhatIf` → review → `-Commit`. **Verify accepted `RetentionDuration` values and that any long-term tier is licensed in your tenant** (2.1) before committing; priorities must be **unique** (lower = evaluated first).
2. **Pass gate:** `PURVSOX-Discovery.ps1` lists the policy with the expected duration/priority. **Rollback:** `-Control AuditRetention -Name "…" -Remove -Commit`.

## Step 8 — Map the controls in Compliance Manager (Configure)
1. In the Purview portal → **Compliance Manager**, add the SOX/ICFR (or a custom) assessment and name it `SOX ICFR – Purview Controls – Assessment` (Requirement 2.6). **Verify a suitable template is available for your licensing/tenant**; if not, use a custom assessment.
2. For each improvement action that the Purview controls satisfy (classification, DLP, audit, retention, access), attach the **evidence** the runbooks produce (Step 9) and mark implementation/test status with your reviewer (kept separate from the configurer — SoD, 2.2). **Pass gate:** the assessment reflects the configured controls with linked evidence.

## Step 9 — Build the evidence runbooks (Configure)
Encode the auditor's recurring requests as saved, repeatable searches — each a documented set of `PURVSOX-EvidenceReport.ps1` / `Search-UnifiedAuditLog` invocations with a short "what this answers":
1. `Evidence – Financial Data Access – Runbook`: who accessed labeled financial content? → operations `FileAccessed,FileDownloaded,FileSyncDownloadedFull` on the in-scope SharePoint/OneDrive sites; correlate with the label.
2. `Evidence – Control Change Management – Runbook`: who changed a DLP/label/retention/role configuration? → operations `New-DlpCompliancePolicy,Set-DlpCompliancePolicy,New-Label,Set-Label,New-RetentionCompliancePolicy,Set-RetentionCompliancePolicy,Add member to role.` (change management ITGC).
3. `Evidence – Access Provisioning – Runbook`: who was granted access to financial data? → operations `Add member to group.,Add member to role.,SharingInvitationCreated,AnonymousLinkCreated` scoped to the finance sites.
4. Store each runbook (exact commands + interpretation notes) alongside this guide. **Pass gate:** each runbook returns interpretable results for benign/test activity over the pilot scope.

## Step 10 — Validate the program and its evidence (Validate)
1. Run `PURVSOX-Validate.ps1` (read-only) to confirm each control is in its expected state: audit on, label published to pilot, **DLP in a Test/simulation mode**, retention scoped with the agreed duration, audit-retention policy present.
2. Run `PURVSOX-EvidenceReport.ps1` to produce `SOX Program – Purview Controls – Report` — a control-to-evidence scorecard, and walk each runbook (Step 9). Complete the **Testing Guide** before expanding.
3. **Pass gate:** the report is green on every control for the pilot and each evidence runbook produces its artifact.

## Step 11 — Expand to enforcement and operationalize (Expand)
1. Once the pilot passes and exposure evidence is reviewed, move the DLP policy from **simulation to enforce** (`-Control Dlp -Name "…" -SetMode Enable -WhatIf` → `-Commit`) and extend the label, retention, and audit-retention coverage to the full agreed scope.
2. Schedule the read-only chain (`PURVSOX-Discovery.ps1` → `PURVSOX-Validate.ps1` → `PURVSOX-EvidenceReport.ps1`) on a cadence so control drift — DLP flipped off, audit disabled, a policy removed, a role change — is caught between audits, and re-run the evidence runbooks when the auditor requests a period.
3. Hand the control map, the assessment, and the evidence runbooks to your SOX/ICFR and internal-audit owners as the standing program. **Pass gate:** enforcement is live for the agreed scope, evidence is producible on demand, and the monitoring cadence is scheduled.
