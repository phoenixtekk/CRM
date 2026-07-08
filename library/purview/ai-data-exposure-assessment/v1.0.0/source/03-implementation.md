# 3. Implementation Guide — AI Data-Exposure Assessment (Microsoft Purview)

Follow these steps **in order**. Posture and reports are read in the **Microsoft Purview portal**
(`https://purview.microsoft.com`); the access-surface inventory, reachability signal, risk ranking, and the
simulation fix-path validation are automated with Security & Compliance PowerShell (`Connect-IPPSSession`)
and Microsoft Graph. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview
and are reused verbatim. **The one change this assessment makes is piloted in simulation** — the pilot
script defaults to `-WhatIf` and creates the auto-labeling policy in simulation only; it never enforces.

> **Model:** Confirm scope, discover the AI access surface, measure reachability, rank the priority risks,
> validate the recommended fix in simulation, hand a defensible baseline + register to the governance
> functions, and re-assess on a recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** — where
> "Expand (enforce)" is handed off, not performed by the assessment.
>
> **Portal-path caveat.** DSPM for AI blades, cmdlets, and audit record types are evolving; the paths and
> record types below are the current map. If a blade, cmdlet, or RecordType differs in your tenant, use the
> closest equivalent and **confirm before acting** — the scripts parameterize the volatile values so you
> can override rather than assume.

## Step 0 — Confirm scope, licensing, roles, auditing, and AI-in-scope (Assess)
1. Run `AIEXPOSE-ScopeCheck.ps1` (read-only). It confirms your `Connect-IPPSSession`/`Connect-MgGraph`
   sign-in, reports whether **auditing** is on, enumerates the licensing-dependent controls (labels, DLP,
   auto-labeling), and probes whether **Copilot/AI interaction records** exist — resolving Requirements
   2.1–2.5. Writes `AIEXPOSE Scope Check – Estate – Assess`.
2. In the Purview portal confirm **DSPM for AI** is visible (Requirement 2.1/2.5). Note any absent
   capability so you scope around it.
3. Decide the framing: **pre-adoption** (no Copilot yet) or **in-adoption** (Copilot in use), and confirm
   the **pilot ring** and change window (Requirement 2.7) for the later simulation step.

**Pass/fail:** Sign-in succeeds, auditing is on, DSPM for AI is visible, framing and pilot scope agreed.
**Rollback:** None — read-only.

## Step 1 — Discover the AI access surface and reachability (Assess → Design)
1. Connect both sessions: `Connect-IPPSSession` (access surface) and `Connect-ExchangeOnline` (the audit
   log that feeds the reachability signal). Run `AIEXPOSE-Discovery.ps1 -Days 30` (read-only). It:
   - inventories **sensitivity labels**, **label policies** (publishing scope), **DLP policies/rules**, and
     **auto-labeling policies** via S&C PowerShell → `AI Access Scope – Estate – Discovery`; and
   - measures reachability from the unified audit log — **AI/Copilot interaction** activity →
     `AI Reachability – Copilot – Assess`, and the **broad-sharing** signal grouped by site →
     `Oversharing Exposure – Sites – Assess`. If your tenant's AI RecordType or sharing Operations differ,
     override with `-AiRecordType` / `-SharingOperations`.
2. Add `-IncludeSensitiveTypes` to append the **sensitive information types** in scope to
   `Sensitive Exposure – Estate – Assess` — a portable record of what "sensitive" means in your tenant.
3. Review against Requirement 2.4: a thin taxonomy or narrow DLP scope is the **first exposure finding** —
   it caps how much any fix could reduce, and the register will weight it.

**Pass/fail:** The inventory lists your labels, label policies, DLP policies/rules, and auto-labeling
policies; the two reachability exports and (with the switch) the sensitive-type export are written.
**Rollback:** None — read-only.

## Step 2 — Read the reachability in the portal and name the hotspots (Assess)
1. Purview portal → **DSPM for AI → Reports**: review the AI **data-access / oversharing** view (what AI
   can reach) and, if Copilot is in use, the **sensitive interactions** view (prompts/responses referencing
   sensitive data). These are the two exposure questions: *what can AI reach* and *what has AI touched* —
   the same two signals `AIEXPOSE-Discovery.ps1` exported in Step 1.
2. Cross-read `Oversharing Exposure – Sites – Assess` with the portal data-access view: broadly-shared sites
   likely holding **unlabeled sensitive** content are the priority reachability targets.
3. Pre-adoption, the AI-interaction set may be empty — expected. The **oversharing signal is still the
   pre-adoption exposure** to quantify before enabling Copilot.

**Pass/fail:** The oversharing hotspots are visible by site and named as the priority set.
**Rollback:** None — read-only.

## Step 3 — Rank the priority exposure risks (Design)
1. Run `AIEXPOSE-RiskRegister.ps1` (read-only). It reads the discovery inventory and the oversharing export
   and produces the ranked **`Exposure Risk Register – Estate – Rank`** — each site scored by reachability
   breadth (broad-share events) with a **no-lever penalty** when no DLP exists to protect content, sorted
   highest exposure first. Each row carries a **Rationale** and a **suggested fix family** (restrict
   sharing / apply label / scope DLP-for-AI).
2. The score is **decision support, not a determination.** With compliance/records/privacy/legal (GR §5),
   review the register and agree which top risks are candidates for remediation and what AI-exposure level
   is acceptable. **The determination is theirs**; you provide the ranked evidence.

**Pass/fail:** The register is written, ranked, and reviewed with stakeholders; the candidate top risks are
recorded. **Rollback:** None — read-only.

## Step 4 — Validate the recommended fix path in SIMULATION (Configure → Pilot)
Validate that the recommended fix for a top risk *would work*, without changing any content. This is the
assessment's only change and it is **simulation only**.

1. **Dry-run first.** Run
   `AIEXPOSE-PilotRemediation.ps1 -Action AutoLabelSim -SensitivityLabel "Confidential" -WhatIf`
   (the default). It prints the policy it *would* create and changes nothing.
2. **Create the simulation policy.** Re-run with `-Commit`. With `-Commit` it creates the auto-labeling
   policy `Exposure Remediation – Pilot – Simulation` in **simulation mode** (`TestWithoutNotifications`) —
   it labels *nothing*, it only reports what it *would* label. Add a matching auto-labeling **rule** with
   your sensitive-info-type conditions, then review the **simulation results** in the portal to confirm the
   fix would land on the right content.
3. **Sharing targets (no policy).** Run
   `AIEXPOSE-PilotRemediation.ps1 -Action SharingTargets -RiskRegisterCsv .\AIEXPOSE-RiskRegister-Estate-Rank.csv`
   to produce the prioritized site list for site-owner sharing review. The script **does not** change
   sharing — it only produces the target list for a change-controlled follow-on.

**Pass/fail:** The pilot policy exists in **simulation** (labels nothing); the sharing target list is
produced — nothing is enforced, no content changed.
**Rollback:** Delete the simulation policy (it enforces nothing and changed no content).

## Step 5 — Validate the assessment and confirm the simulation-only posture (Validate)
1. Run `AIEXPOSE-Validate.ps1` (read-only). It confirms all expected exports exist and are consistent
   (scope check, discovery, reachability, oversharing, and a descending-ranked register) and — if the pilot
   policy was created — confirms it is in **simulation** mode and enforces nothing. Writes
   `AIEXPOSE Validate – Estate – Assess`.
2. In the portal, review the auto-labeling **simulation results** for the pilot: the would-be labels should
   match intent (an acceptable false-positive rate) — this is the evidence the fix path is sound. See
   Testing (doc 5) for the explicit gates.
3. If any validation check is **FAIL** (a missing export, or a policy found in an enforcing mode), correct
   it before hand-off. A pilot policy in any non-simulation mode is a stop condition.

**Pass/fail:** All exports present and consistent; the pilot policy (if present) is confirmed
simulation-only. **Rollback:** Return any non-simulation policy to `TestWithoutNotifications` or delete it.

## Step 6 — Hand off the defensible baseline and set a re-assessment cadence (Expand → handoff)
1. Package the deliverables — `AI Access Scope – Estate – Discovery`, `AI Reachability – Copilot – Assess`,
   `Oversharing Exposure – Sites – Assess`, and the ranked **`Exposure Risk Register – Estate – Rank`** —
   as the defensible AI-exposure baseline for the governance functions to decide against.
2. **Enforcement is explicitly a follow-on.** Turning the validated fix into an enforced reduction program
   (auto-labeling on, DLP-for-AI enforcing, sharing restrictions applied at scope) is a separate,
   change-controlled engagement — not part of this assessment. The simulation validation de-risks that
   decision.
3. Stand up the recurring re-assessment: tag the cadence `AI Exposure Re-Assessment – Estate – Recurring`
   and schedule the read-only `ScopeCheck → Discovery → RiskRegister` chain (e.g. monthly or
   before each AI rollout wave) so exposure stays measured as data and AI usage change.

**Pass/fail:** Baseline + register handed off; enforcement scoped as a follow-on; recurring re-assessment
scheduled. **Rollback:** None — read-only handoff; the simulation policy, if kept, remains simulation-only.
