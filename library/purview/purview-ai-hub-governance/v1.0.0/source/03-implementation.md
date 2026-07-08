# 3. Implementation Guide — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

Follow these steps in order. This guide assesses AI-governance readiness, turns on visibility, applies
the recommended protective policies — with the **DLP-for-AI policy piloted in test/simulation** and the
insider-risk / communication-compliance detections configured via the portal one-click recommendations —
validates, then expands. Artifact names are fixed — use the exact names in §1. **DLP over AI is
high-impact, so the DLP policy runs in TEST/simulation on a pilot ring first.** Scriptable writes default
to `-WhatIf`; add `-Commit` to apply.

> Model: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).** DSPM for AI is
> new and partly **preview** — verify current portal paths, policy names, audit record types, licensing,
> and onboarding/extension support for your tenant as you go; nothing here is invented. Insider-risk and
> communication-compliance **outcomes are deferred to HR/legal**.

## Step 1 — Assess current state (read-only)
1. Run `AIHUB-Discovery.ps1`. It reports whether **unified audit** is enabled, whether **AI-interaction
   activity** (Copilot and related record types) is present in the audit log, which **sensitivity labels**
   exist (that Copilot can honor), any existing **DLP policies** and their mode, and endpoint/extension
   readiness signals. No changes are made.
2. In the Purview portal open **DSPM for AI** and review the **Overview / recommendations** and **Activity
   explorer / reports** — note which recommended policies are already in place and which are recommended.
3. Record gaps against the Requirements checklist. Do **not** proceed past: audit disabled, missing roles,
   no target label, or no pilot/privacy decision — remediate first.

## Step 2 — Turn on AI visibility (audit)
1. Ensure unified audit is enabled (Req 2.4). If not, `AIHUB-Config.ps1 -EnableAudit -WhatIf`, review, then
   `-Commit` (runs `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`). Allow ingestion
   latency before expecting AI activity.
2. In DSPM for AI, confirm the **Activity explorer / AI reports** begin to populate for pilot users' AI
   interactions. **Pass/fail:** `AIHUB-Discovery.ps1` shows audit enabled and AI-interaction events appear
   over time.

## Step 3 — Design the AI-governance policy set
1. With the accountable owner, decide: which **label** Copilot must honor and which label's content must be
   **withheld from AI** (the DLP target — e.g. `Highly Confidential`); which **risky AI patterns** the
   insider-risk / communication-compliance detections should flag; whether **consumer-AI egress** (endpoint/
   browser) is in scope (Req 2.7); and the **privacy-by-design** model for the HR-sensitive detections
   (Req 2.8).

## Step 4 — Confirm Copilot honors sensitivity labels
1. Confirm the target labels exist and are published (Req 2.5). Copilot honors labels and their encryption
   natively — a user only gets AI answers over content they are entitled to, and labeled content's
   protection is respected.
2. **Pass/fail:** as a pilot user, confirm Copilot does **not** surface content the user isn't entitled to,
   and that summarizing labeled/encrypted content behaves per the label's rights (validated in Testing).

## Step 5 — Configure the DLP-for-AI policy in TEST/simulation (pilot ring)
1. Create the protective DLP policy in **test/simulation**, scoped to the pilot ring:
   `AIHUB-Config.ps1 -CreateDlpForAI -PolicyName "AI-DLP-ProtectLabeled-Sim" -RuleName
   "AI-DLP-Rule-HighlyConfidential" -TargetLabel "Highly Confidential" -PilotGroup "grp-ai-pilot@contoso.com"
   -WhatIf`. It shows the `New-DlpCompliancePolicy` (**Mode = TestWithoutNotifications**) and
   `New-DlpComplianceRule` (condition: content labeled `Highly Confidential`) it would create — **without
   making changes**. Review, then `-Commit`.
2. **The AI/Copilot-specific scope and action are configured/confirmed in the portal.** The exact DLP
   location/action that governs AI/Copilot processing is **portal-driven and evolving** — after creating the
   policy, open it in **DSPM for AI → Policies / DLP** and confirm the AI scope and the protect action.
   **Verify the current AI DLP action for your tenant**; the script creates the policy in test mode and
   flags this.
3. **Pass/fail:** `Get-DlpCompliancePolicy "AI-DLP-ProtectLabeled-Sim"` shows **Mode = Test\*** (never
   Enable during pilot) scoped to the pilot ring. **Rollback:** `AIHUB-Config.ps1 -SetDlpMode -PolicyName …
   -Mode TestWithoutNotifications -Commit` (or `Remove-DlpCompliancePolicy`).

## Step 6 — Configure the recommended insider-risk and communication-compliance detections (portal)
1. In **DSPM for AI → Recommendations**, turn on the recommended **insider-risk** policy for risky AI usage
   (name it `AI-IRM-RiskyAIUsage`) and the **communication-compliance** policy for prompts/responses
   (`AI-CC-PromptResponse`). Configure them **privacy-by-design**: pseudonymization where applicable, strict
   **role separation**, and the named reviewers agreed in Req 2.8.
2. These are **portal-configured** (PowerShell coverage is limited) — follow the portal wizard. **Outcomes
   are deferred to HR/legal**: you are enabling detection and review, not deciding cases.
3. **Pass/fail:** the policies appear enabled in their respective solutions with the agreed privacy settings;
   `AIHUB-Discovery.ps1` notes their presence where readable.

## Step 7 — (Optional) Configure consumer-AI egress signals (endpoint/browser)
1. If in scope (Req 2.7): confirm devices are onboarded and the Purview **browser extension** is deployed,
   then enable the recommended endpoint/browser signals in DSPM for AI to surface sensitive data going into
   **consumer AI sites**. Keep any blocking action in **audit/simulation** first.
2. **Verify current browser/extension support for your tenant.** **Pass/fail:** consumer-AI activity begins
   to surface in the reports for onboarded pilot devices.

## Step 8 — Validate on the pilot
1. Run `AIHUB-Validation.ps1` (read-only): confirms audit enabled, the DLP policy is in **Test** (not Enable),
   scoped to the pilot ring, and the target label exists.
2. Complete the Testing Guide: AI interactions are visible; Copilot honors labels; the DLP policy **simulates**
   matches on labeled content **without blocking**; the detections raise reviewable signals (privacy-by-design);
   consumer-AI egress surfaces if in scope.
3. **Gate:** visibility works, Copilot honors labels, the DLP policy simulates cleanly (acceptable false-
   positive rate), and detections/reports work — before enforcing or widening scope.

## Step 9 — Expand and enforce
1. Once the pilot passes and the DLP false-positive rate is acceptable, move the DLP policy from **test** to
   **enforce** for the pilot ring first, then widen scope: `AIHUB-Config.ps1 -SetDlpMode -PolicyName
   "AI-DLP-ProtectLabeled-Sim" -Mode Enable -WhatIf` then `-Commit`. Widen the insider-risk/communication-
   compliance scope per the agreed rollout.
2. **Gate:** re-validate after each scope increase (`AIHUB-Validation.ps1`); confirm a documented rollback
   (set DLP back to test / disable a policy) per control.

## Step 10 — Operate: reports, review, and evidence
1. Run `AIHUB-Report.ps1 -CsvFolder <path>` to export **AI-interaction activity** and the **DLP-for-AI match
   summary** as evidence for the governance owner.
2. Run `AIHUB-Readiness.ps1` on a cadence to catch **audit turned off, a DLP-for-AI policy left in test after
   expansion (or flipped to enforce prematurely), missing onboarding, or licensing/preview changes**.
3. Operate the insider-risk / communication-compliance **review** with role separation; **case outcomes are
   HR/legal determinations** — this solution provides the detections and evidence, not the decisions.

---
### Order of operations
`Assess → Enable audit (visibility) → Design the policy set → Confirm Copilot honors labels → DLP-for-AI in
TEST on the pilot ring → Insider-risk + communication-compliance detections (portal, privacy-by-design) →
(optional) consumer-AI egress signals → Validate → Expand/enforce → Operate (reports, review, evidence)`
