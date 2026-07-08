# 3. Implementation Guide — Information Protection Assessment & Readiness (Microsoft Purview)

Follow these steps **in order**. The **Purview portal** and **Security & Compliance PowerShell** /
**Graph** steps are given cmdlet-/click-exact. This is an **assessment**: Steps 1–5 are **read-only**
discovery, scoring, and roadmap; Step 6 pilots **one** recommended fix in **simulation** (creates a
policy that changes nothing); Step 7 validates; Step 8 hands off to change-controlled follow-on. No
labels, DLP, or auto-labeling are **enforced** by this engagement.

Consoles / endpoints used:
- **Microsoft Purview portal** — `https://purview.microsoft.com` (Information Protection, DLP,
  Content/Activity Explorer; DSPM where licensed)
- **Security & Compliance PowerShell** — `Connect-IPPSSession` (labels, DLP, auto-labeling, SITs)
- **Microsoft Graph** — `Connect-MgGraph` (pilot group membership, optional)

> **Model:** Measure posture (read-only) → rank gaps → produce the roadmap → pilot **one** fix in
> **simulation** → validate → hand off enforcement. **Assess → Design → Configure → Pilot (simulate) →
> Validate → Expand.**

> **Artifact names (use verbatim):** discovery `Information Protection - Estate - Discovery`; gap register
> `Information Protection - Gaps - Register`; roadmap/scorecard `Information Protection - Roadmap -
> Scorecard`; simulation pilot policy `Information Protection - Pilot - Simulation`; optional pilot label
> policy `Information Protection - Label Policy - Pilot`; pilot scope group `Information Protection -
> Pilot Users`.

> **Risk + rollback (read first):** Steps 1–5 and 7 are **read-only** — they create only CSV/report
> files locally and change nothing in the tenant. **Step 6** creates an **auto-labeling policy in
> SIMULATION** (`Mode = TestWithoutNotifications`) — it evaluates content and reports what it *would*
> label and **applies no label to anything**; it is still a created object. **Rollback for Step 6:**
> delete the simulation policy (`Remove-AutoSensitivityLabelPolicy "Information Protection - Pilot -
> Simulation"`) — because it labeled nothing, there is nothing to revert. The optional pilot label policy
> publishes to `Information Protection - Pilot Users` **only**; unpublish it to roll back. **Never enable
> or enforce** any policy in this engagement.

---

## Phase 1 — Assess (read-only discovery)

### Step 1 — Confirm scope and connectivity
1. Confirm the in-scope workloads and classification intent (Requirement 2.4) and the readiness baseline
   (2.5) are agreed and written down.
2. Connect: `Connect-IPPSSession` (and `Connect-MgGraph -Scopes "Group.Read.All"` if you will pilot to a
   group in Step 6). Run **`IPASSESS-ScopeHealth.ps1`** — it confirms the S&C + Graph sessions, reports
   which capabilities (labels, DLP, auto-labeling, SITs) are **readable**, and flags any that are **not
   available — verify your licensing/tenant** (Requirement 2.1). Gated features are recorded, not assumed.

### Step 2 — Inventory the information-protection estate
1. Run **`IPASSESS-Discovery.ps1`** (read-only). It inventories, via Security & Compliance PowerShell:
   - **Sensitivity labels** (`Get-Label`) — name, priority, enabled, and the **protection** settings that
     matter to posture: `EncryptionEnabled`, `EncryptionProtectionType`, content markings
     (`ApplyContentMarkingHeaderEnabled` / `...FooterEnabled` / `ApplyWaterMarkingEnabled`), and
     `ContentType` (the label's scope: File/Email, Site/Group, etc.).
   - **Label policies** (`Get-LabelPolicy`) — which labels are **published**, and to whom (the coverage
     that turns a created label into a used one).
   - **DLP** (`Get-DlpCompliancePolicy` / `Get-DlpComplianceRule`) — policy **Mode** (Enable / Test with
     or without notifications / Disable) and **Workload** coverage, plus the rules' conditions/actions.
   - **Auto-labeling** (`Get-AutoSensitivityLabelPolicy`) — each policy's **Mode** (simulation vs. enabled)
     and the label it applies.
   - **Sensitive information types** (`Get-DlpSensitiveInformationType`, with `-IncludeSensitiveTypes`) —
     built-in + custom SITs that define "sensitive" for the tenant.
2. Output: `Information Protection - Estate - Discovery` (CSV). This is the **"what protects the estate
   today"** baseline.
3. In the portal, complement the script with **coverage** you cannot fully script: Purview →
   **Information Protection → Content explorer** (label distribution across SharePoint/OneDrive/Exchange)
   and **Activity explorer** (labeling activity). Note counts for the scorecard. If **DSPM** is licensed,
   note its recommendations too (**verify your licensing/tenant**).

## Phase 2 — Design (score and rank)

### Step 3 — Score the posture against the baseline
1. Run **`IPASSESS-Validation.ps1`** (read-only) against the discovery CSV. It scores each of the six
   dimensions (taxonomy, publishing/coverage, encryption/protection, auto-labeling, DLP coverage/mode,
   SITs) **PASS / WARN / FAIL** against the baseline (Requirement 2.5) — e.g. a label that exists but is
   **not published** is a WARN; a DLP policy **stuck in Test** across all in-scope workloads is a WARN;
   an in-scope workload with **no DLP at all** is a FAIL; a "Confidential"-tier label with
   **`EncryptionEnabled = False`** is flagged for review.
2. Review each PASS/WARN/FAIL with the stakeholders and confirm the target where the default baseline
   doesn't fit the organization.

### Step 4 — Build the gap register
1. Run **`IPASSESS-Report.ps1-Section GapRegister`** (read-only). It turns the scored findings into
   `Information Protection - Gaps - Register` (CSV): one row per gap with **dimension, finding,
   severity, recommended action, effort, and owner-function** (compliance/records/security).
2. Confirm each gap with the accountable stakeholder (Requirement 2.7). **Determinations** (whether a gap
   *must* be closed for a regulation) are recorded against the owner function — **not** decided here.

### Step 5 — Produce the prioritized roadmap and scorecard
1. Run **`IPASSESS-Report.ps1 -Section Roadmap`** (read-only). It ranks the gap register into
   `Information Protection - Roadmap - Scorecard`: **quick wins** (publish an existing label, move a DLP
   policy from Test toward pilot, enable a missing content marking) vs. **strategic** (stand up
   auto-labeling, extend DLP to a new workload, build custom SITs), each with severity and effort, plus a
   one-page **posture scorecard** (score per dimension).
2. This is the primary deliverable. Deliver it to the stakeholders as the decision artifact.

## Phase 3 — Pilot one fix in SIMULATION (safe)

### Step 6 — Validate the top recommended fix in simulation (creates nothing enforceable)
Pick the **highest-value, lowest-risk** gap that can be proven in simulation — typically **auto-labeling
a well-defined SIT to an existing label**.
1. Preview first (no change): `.\IPASSESS-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel
   "Confidential" -WhatIf`. It prints exactly what it would create.
2. Create the **simulation** policy: `.\IPASSESS-PilotRemediation.ps1 -Action AutoLabelSim
   -SensitivityLabel "Confidential" -Commit`. This runs
   `New-AutoSensitivityLabelPolicy -Name "Information Protection - Pilot - Simulation" -Mode
   "TestWithoutNotifications" ...` — **simulation**: it evaluates content and reports what it **would**
   label and **applies no label**. Then add a matching rule with your SIT conditions
   (`New-AutoSensitivityLabelRule`) and review results in the portal.
3. **Alternative low-risk pilot:** publish an **existing unpublished** label to `Information Protection -
   Pilot Users` **only** (optional pilot label policy `Information Protection - Label Policy - Pilot`) to
   prove the publish path — the pilot group sees the label; no one else is affected.
4. **DLP** gaps are validated by moving a policy toward **Test with policy tips** in the portal (detects
   and reports, blocks nothing) — this engagement does **not** `Enable` DLP.

> Whatever you pilot, it is **simulation/test/pilot-group only**. Do **not** `Enable`/enforce. The point
> is to prove the **fix path**, so the roadmap is credible — not to deploy it.

## Phase 4 — Validate and hand off

### Step 7 — Validate the pilot and finalize the deliverable (pilot gate)
1. Review the **simulation results** in the portal (Information Protection → Auto-labeling → the policy →
   **Simulation**): it should show the content it **would** have labeled, confirming the fix path is
   sound. Re-run **`IPASSESS-Validation.ps1`** to confirm the pilot object exists in the expected
   (simulation) mode and nothing was enforced. Complete the **Testing Guide** pilot gate.
2. Fold the validated fix into the roadmap as a **proven quick win** and finalize `Information Protection
   - Roadmap - Scorecard`.

### Step 8 — Hand off enforcement (follow-on, out of scope)
1. Present the scorecard, gap register, and roadmap to the compliance/security stakeholders.
2. **Roll back the pilot** if you do not intend to proceed immediately: `Remove-AutoSensitivityLabelPolicy
   "Information Protection - Pilot - Simulation"` (it labeled nothing) and/or unpublish the pilot label
   policy. Enforcing/expanding any recommendation is a **separate, change-controlled engagement**, not
   this assessment.

---
### Order of operations
`confirm scope + connect (ScopeHealth) → discover estate (Discovery, read-only) → score vs. baseline
(Validation) → build gap register (Report:GapRegister) → produce roadmap + scorecard (Report:Roadmap) →
pilot ONE fix in SIMULATION (PilotRemediation -WhatIf → -Commit) → validate simulation results →
hand off enforcement as follow-on (roll back the pilot)`
