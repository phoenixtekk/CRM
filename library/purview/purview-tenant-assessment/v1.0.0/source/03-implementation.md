# 3. Implementation Guide — Microsoft Purview Tenant Assessment

Follow these steps **in order**. The assessment uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession` —
labels, DLP, retention, and where available Communication Compliance/eDiscovery), **Exchange Online
PowerShell** (`Connect-ExchangeOnline` — audit config), and **Microsoft Graph** (licensing, roles,
security reads). Every discovery/validation/report tool is **read-only**; the remediation tool runs
**`-WhatIf` by default** and changes state only with `-Commit`, always **simulation/test/pilot-first**.
Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused
verbatim.

> **Model:** Assess every enabled capability, design the prioritized findings, configure the safe
> quick-win fixes, **pilot** them in simulation/test on a limited scope, validate the findings clear,
> then expand/track the rest as a governed backlog. Pattern:
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand.**

## Step 1 — Preflight the scope, licensing, and roles (Assess)
1. Run `PURVASSESS-Scope.ps1` (read-only). It connects to S&C PowerShell, Exchange Online, and Graph and reports:
   - which Purview-relevant **service plans** are present (E5 / E5 Compliance signals) — *licensed vs not*,
   - which capability **reads succeed** vs throw a permissions error (role coverage — Requirement 2.2),
   - which endpoints (`Connect-IPPSSession`, `Connect-ExchangeOnline`, `Connect-MgGraph`) are reachable.
2. In the Purview portal, note which capabilities appear under `Solutions` (visibility depends on role + licensing).
3. **Pass gate:** you have a written statement of what is licensed and readable, and any role/endpoint gap is resolved before assessing — so a "gap" finding is a real gap, not a missing permission.

## Step 2 — Inventory every enabled capability (Assess)
1. Run `PURVASSESS-Discovery.ps1` (read-only). For each capability it reads and records, tagging each as **enabled / not enabled / not licensed / portal-only — review manually**:
   - **Information Protection** — `Get-Label`, `Get-LabelPolicy`, `Get-AutoSensitivityLabelPolicy` (labels, publication scope, auto-labeling mode).
   - **DLP** — `Get-DlpCompliancePolicy`, `Get-DlpComplianceRule` (policies, per-workload locations, **mode** enforce vs test).
   - **Data Lifecycle & Records** — `Get-RetentionCompliancePolicy`, `Get-RetentionComplianceRule`, `Get-ComplianceTag` (policies/labels, **enabled** state, publication).
   - **Audit** — `Get-AdminAuditLogConfig` (ingestion), `Get-UnifiedAuditLogRetentionPolicy` (retention).
   - **eDiscovery** — `Get-ComplianceCase`, `Get-CaseHoldPolicy` (cases, holds).
   - **Communication Compliance** — read where the tenant exposes it (flagged portal-only if the read isn't available).
   - **Insider Risk**, **DSPM / DSPM for AI**, **Compliance Manager**, **Unified Catalog** — **portal-driven**; the tool records them as *review manually* with the exact portal location (it does not invent cmdlets).
   - **Classifiers & SITs** — `Get-DlpSensitiveInformationType`, trainable-classifier reads where available.
2. The tool writes the raw inventory that Step 4 turns into findings. **Pass gate:** every enabled capability has a recorded current-state, and every not-enabled/not-licensed/portal-only one is explicitly marked (not silently skipped).

## Step 3 — Design the findings and priority scheme (Design)
1. Agree the **priority definitions** with your stakeholders (Requirement 2.6), used verbatim in the register:
   - **P1** — critical exposure or enforced-but-risky: sensitive data unprotected, a DLP/label/retention policy enforced tenant-wide with no pilot, unified audit off, an Insider Risk/Communication Compliance policy running with no reviewers.
   - **P2** — coverage gap or drift: a workload not covered (e.g. DLP on email but not Teams), a label taxonomy published to no one, an auto-labeling policy stuck in simulation, a retention policy left **disabled**, a licensed-but-empty capability.
   - **P3** — optimization: redundant/overlapping policies, naming inconsistency, unused SITs, tuning opportunities.
2. Agree that **regulatory/records/legal** findings (is a duration correct, does a rule satisfy a regulation) are recorded as **decisions for the governance owner**, not fixed here (Requirement 2.6).
3. Define the **remediation pilot scope** `Purview Assessment – Remediation Pilot – Stage1` (Requirement 2.7). **Pass gate:** priority definitions, decision routing, and pilot scope are documented and approved.

## Step 4 — Produce the findings register, priorities, and scorecard (Design)
1. Run `PURVASSESS-Report.ps1` (read-only). From the Step 2 inventory it produces:
   - `Purview Assessment – Tenant – Findings` — every finding with **capability · observation · evidence source · risk · recommendation · priority**.
   - `Purview Assessment – Priorities – P1P2P3` — the findings rolled up by priority.
   - `Purview Assessment – Capabilities – Scorecard` — each capability's coverage/maturity read (and enabled/not-enabled/portal-only state).
2. Review the register with stakeholders; route the determination findings to their owners (Requirement 2.6). **Pass gate:** the register is reviewed and each P1/P2 has an owner and a decision (fix here / decide by governance / defer to a build engagement).

## Step 5 — Configure the safe quick-win fixes — simulation first (Configure → Pilot)
Only the low-risk, high-value fixes are applied here; standing up a whole capability is a separate
engagement (the finding points to it). Every fix is **pilot-scoped and simulation/test/`-WhatIf` first**.
Each of these prints the exact cmdlet under `-WhatIf`, then applies on `-Commit`:
1. **Move a bluntly-enforced DLP policy into simulation** (so you can see impact before it blocks users):
   `PURVASSESS-Remediate.ps1 -Fix DlpToSimulation -PolicyName "<policy>" -WhatIf` → review → `-Commit`. (Runs `Set-DlpCompliancePolicy -Mode TestWithNotifications`.)
2. **Take an auto-labeling policy to simulation** before enforcement:
   `PURVASSESS-Remediate.ps1 -Fix AutoLabelToSimulation -PolicyName "<policy>" -WhatIf` → review → `-Commit`.
3. **Enable a retention policy that was left disabled** (after the records owner confirms it should run — Requirement 2.6):
   `PURVASSESS-Remediate.ps1 -Fix EnableRetentionPolicy -PolicyName "<policy>" -WhatIf` → review → `-Commit`. (Runs `Set-RetentionCompliancePolicy -Enabled $true`.)
4. **Enable unified audit ingestion** if it is off:
   `PURVASSESS-Remediate.ps1 -Fix EnableUnifiedAudit -WhatIf` → review → `-Commit`. (Runs `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`.)
5. Scope every fix to `Purview Assessment – Remediation Pilot – Stage1` where the policy supports scoping, and record the `-WhatIf` transcript. **Pass gate:** each applied fix ran `-WhatIf` clean, was reviewed, and committed only after approval. **Rollback:** every fix is reversible — `-Fix DlpToSimulation` back to its prior mode, `-Fix EnableRetentionPolicy` → `Set-RetentionCompliancePolicy -Enabled $false`, audit enablement is non-destructive; `PURVASSESS-Remediate.ps1 -Fix <name> -Revert -Commit` restores the recorded prior state.

## Step 6 — Validate the remediated findings clear (Validate)
1. Run `PURVASSESS-Validate.ps1` (read-only). For each fix applied in Step 5 it re-reads the capability and confirms the target state (DLP policy now in `TestWithNotifications`, auto-labeling in simulation, retention policy `Enabled = True`, audit ingestion `True`).
2. Re-run `PURVASSESS-Report.ps1` and confirm the corresponding findings now show **cleared** in `Purview Assessment – Tenant – Findings`. Complete the **Testing Guide** before expanding.
3. **Pass gate:** every remediated finding validates green for the pilot scope.

## Step 7 — Readout, expand, and track (Expand)
1. Produce `Purview Assessment – Tenant – Readout` (executive summary of the scorecard + P1/P2/P3 with owners and status) and walk it with stakeholders.
2. For findings **not** fixed here — governance decisions and full-build items — record them as a **governed backlog** with owners and target dates; they are inputs to implementation engagements, not this assessment.
3. Schedule the read-only chain (`PURVASSESS-Scope.ps1` → `PURVASSESS-Discovery.ps1` → `PURVASSESS-Report.ps1`) on a cadence (e.g. quarterly) so the tenant is **re-baselined** and drift is caught — a falling P1/P2 count over successive runs is the measure of progress. **Pass gate:** the readout is delivered, the backlog is owned, and the re-baseline cadence is scheduled.
