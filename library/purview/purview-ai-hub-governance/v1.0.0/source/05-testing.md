# 5. Testing & Validation Guide — Purview AI Hub Governance (DSPM for AI)

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not enforce the DLP-for-AI policy or widen scope until the relevant tests pass —
because DLP over AI is high-impact, the **test/simulation pilot** is your safety gate. Checks use the
Purview portal (DSPM for AI), Security & Compliance PowerShell, and Graph; the provided scripts automate
the read-only ones.

> **Reminder:** you are validating that AI governance *behaves as designed* (visibility on, labels honored,
> DLP simulates without blocking, detections raise reviewable signals) — not deciding *what AI usage is
> acceptable* or *adjudicating cases*; those are governance/HR/legal determinations from §2.

## Test 1 — AI visibility is on
- **How:** `AIHUB-Discovery.ps1` (or `Get-AdminAuditLogConfig`), then DSPM for AI → Activity explorer/reports.
- **Pass:** unified audit is enabled and AI-interaction activity (Copilot and related) appears for pilot
  users (allow ingestion latency).
- **Fail:** audit off → `AIHUB-Config.ps1 -EnableAudit -Commit`; no activity → allow latency, confirm pilot
  users are actually using AI, and **verify the current AI audit record types for your tenant**.

## Test 2 — Copilot honors sensitivity labels (entitlement)
- **How:** as a pilot user, ask Copilot to summarize/return content the user is **not** entitled to (labeled/
  encrypted content outside their rights).
- **Pass:** Copilot does **not** surface content the user isn't entitled to; labeled output retains its label/
  protection.
- **Fail:** Copilot surfaces content the user shouldn't see → confirm the labels are published and the content
  is actually labeled/encrypted (Req 2.5); **verify current Copilot label-honoring behaviour for your tenant.**

## Test 3 — The DLP-for-AI policy is in simulation (never enforcing during pilot)
- **How:** `AIHUB-Validation.ps1` (or `Get-DlpCompliancePolicy "AI-DLP-ProtectLabeled-Sim"`).
- **Pass:** the policy **Mode** is a **Test\*** (simulation) mode — it is **not** `Enable` — and it is scoped
  to `grp-ai-pilot@contoso.com` only.
- **Fail:** the policy is `Enable` during the pilot → set it back to test immediately (`AIHUB-Config.ps1
  -SetDlpMode -Mode TestWithoutNotifications -Commit`); a training/pilot DLP policy must never enforce.

## Test 4 — The DLP-for-AI policy simulates matches on the right content
- **How:** with pilot content labeled `Highly Confidential`, exercise the AI flow the policy governs; review
  the simulation matches in the portal and via `AIHUB-Report.ps1`.
- **Pass:** the policy **matches** the labeled content in simulation (a would-be protect action is recorded)
  **without blocking** real work; ordinary content is not matched.
- **Fail (false negatives):** labeled content isn't matched → confirm the rule condition targets the correct
  label and the AI scope/action is set in the portal (Step 5). **Fail (false positives):** ordinary content
  matches → tighten the condition and re-simulate.

## Test 5 — Risky-AI detections raise reviewable signals (privacy-by-design)
- **How:** in Insider Risk Management and Communication Compliance, confirm `AI-IRM-RiskyAIUsage` and
  `AI-CC-PromptResponse` are enabled and generate reviewable signals for the pilot; confirm pseudonymization
  and role separation are applied.
- **Pass:** the detections produce signals a designated reviewer can triage, with the agreed privacy settings;
  reviewers are role-separated from general admin.
- **Fail:** no signals (confirm the policy scope/conditions) or privacy settings not applied (correct per
  Req 2.8). **Outcomes are HR/legal determinations** — you are validating detection, not adjudicating.

## Test 6 — (If in scope) consumer-AI egress is surfaced
- **How:** on an onboarded pilot device with the Purview browser extension, paste sample sensitive content
  into a consumer AI site; review DSPM-for-AI / endpoint reports.
- **Pass:** the activity is surfaced in the reports (in audit/simulation) for the onboarded device.
- **Fail:** nothing surfaces → confirm device onboarding and extension deployment (Req 2.7); **verify current
  browser/extension support for your tenant.**

## Test 7 — Enforcement change is deliberate and reversible
- **How:** after the pilot passes, move the DLP policy to `Enable` for the pilot ring
  (`AIHUB-Config.ps1 -SetDlpMode -Mode Enable -Commit`) and confirm with `AIHUB-Validation.ps1`.
- **Pass:** the policy enforces only for the intended scope; a documented rollback (set back to test / disable)
  is confirmed.
- **Fail:** enforcement leaked beyond the intended scope → correct the scope and re-validate before widening.

## Test 8 — Reports and evidence are complete
- **How:** `AIHUB-Report.ps1 -CsvFolder <path>`; review the exported AI-interaction activity and DLP-for-AI
  match summary.
- **Pass:** the report reflects AI interactions and DLP simulation/enforcement matches for the pilot scope —
  the evidence the governance owner needs.
- **Fail:** a gap → confirm audit/latency and the policy scope, then re-export.

---
### Exit criteria (all must be true before enforcing / widening scope)
`AI visibility on · Copilot honors labels · DLP-for-AI in simulation (never Enable) during pilot · DLP
simulates the right matches, acceptable false-positive rate · risky-AI detections raise reviewable signals
(privacy-by-design, role-separated) · consumer-AI egress surfaced if in scope · enforcement deliberate and
reversible · reports/evidence complete · outcomes deferred to HR/legal`
