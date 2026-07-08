# 5. Testing Guide — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

Run these after each stage. Every test is safe (read-only, or DLP **test**-mode / limited-scope); the
Communication-Compliance review and DLP test matches are the **gates** before any enforcement or scope
expansion. Pass/fail is explicit.

## Test 1 — Environment, licensing, roles, and auditing
**Do:** Run `AIPROMPT-ScopeConfig.ps1`; open **Communication Compliance**, **DLP**, and **DSPM for AI** in
the Purview portal.
**Expected:** Sign-in succeeds; auditing reports as **on** (`UnifiedAuditLogIngestionEnabled`); the three
blades load without an access error; the AI-governance features are enumerated. Any absent capability is
noted, not assumed.
**Gate:** Do not proceed until auditing is on and the required blades are visible.

## Test 2 — Governance-config inventory is complete
**Do:** Run `AIPROMPT-Discovery.ps1`; compare against **Information Protection → Labels**, **DLP →
Policies**, and **Communication Compliance → Policies** in the portal.
**Expected:** `AI Governance Config – Estate – Discovery` lists every sensitivity label, sensitive
information type, DLP policy (flagging any Copilot/AI-scoped), and existing Communication-Compliance policy
shown in the portal — the baseline of levers and existing governance.

## Test 3 — AI usage monitoring populates
**Do:** Run `AIPROMPT-Monitor.ps1`; open **DSPM for AI → Reports**.
**Expected:** `AI Usage – Copilot – Monitor` and `Sensitive AI Interactions – Estate – Assess` are written
and list AI interactions (user, app, sensitive/labeled resources); the DSPM-for-AI sensitive-interactions
report renders. *Note:* AI monitoring depends on auditing (Test 1) and on Copilot/AI having been used —
empty results pre-adoption are expected.

## Test 4 — Privacy-by-design is in effect (Communication Compliance)
**Do:** Purview portal → **Communication Compliance → Settings → Privacy**; open the AI policy's pending
items as an **Analyst**.
**Expected:** **Anonymization is on** — usernames display as system aliases to Analysts; only gated
Investigators can de-anonymize. Analyst and Investigator roles are held by different accounts.
**Gate:** Do not run the pilot on real people until anonymization is confirmed on and roles are separated.

## Test 5 — Communication-Compliance AI policy is pilot-scoped only
**Do:** Inspect `AI Interactions – Copilot – CommCompliance` in the portal; run
`AIPROMPT-Configure-Governance.ps1 -Action CommComplianceReview` (read-only).
**Expected:** The policy is scoped **only to `AI Governance – Pilot – Ring1`**, uses the agreed
classifiers/sensitive-info conditions and the Copilot/AI monitored source (or is noted as audit-signal-only
where the source is absent), with the assigned reviewers. The checklist output matches the design.
**Gate:** If the policy is scoped broader than the pilot ring, narrow it before continuing.

## Test 6 — DLP-for-AI helper makes no change in dry-run
**Do:** Run `AIPROMPT-Configure-Governance.ps1 -Action DlpForAI -DlpAiLocation "<loc>" -WhatIf`; then re-run
`AIPROMPT-Discovery.ps1`.
**Expected:** The dry-run prints the DLP policy it *would* create; the discovery inventory is unchanged —
`-WhatIf` created nothing. **This is the gate that proves the helper is safe by default.**

## Test 7 — DLP-for-AI policy is created in test mode only
**Do:** Run the helper with `-Commit` for the pilot (`AI Prompt DLP – Copilot – Test`); inspect it in the
portal.
**Expected:** The DLP policy is in **test/disabled** mode (enforces nothing), scoped to the pilot ring, on
the **Copilot/AI location** you passed via `-DlpAiLocation`, matching the agreed labels/SITs.
**Gate:** If it landed in an enforcing state, stop and correct before continuing.

## Test 8 — Pilot matches are acceptable (enforcement/expansion gate)
**Do:** Let the pilot run the agreed window; review the Communication-Compliance **pending items** and the
DLP **test** matches in the portal for false positives, with the pseudonymized reviewers; confirm with
HR/privacy/legal.
**Expected:** Flagged prompts/responses and DLP test matches align with intent, with an acceptable
false-positive rate, and reviewer workflow behaves as designed with anonymization intact.
**Gate:** **Do not enforce or expand (Step 8 of implementation) until this passes and HR/privacy/legal
sign off.**

## Test 9 — Monitoring aligns with policy matches
**Do:** Re-run `AIPROMPT-Monitor.ps1`; cross-read `Sensitive AI Interactions – Estate – Assess` with the
policy's flagged items.
**Expected:** The sensitive interactions surfaced by monitoring are the ones the policy is catching —
evidence the monitoring and the governing policy are consistent, not divergent.

## Test 10 — Validation evidence is captured
**Do:** Run `AIPROMPT-Validate.ps1`.
**Expected:** `AI Governance Validation – Estate – Evidence` confirms the DLP policy is in **test** mode, the
Communication-Compliance policy is pilot-scoped, and AI interactions are being captured — the defensible
evidence record for the pilot.

## Test 11 — Rollback works
**Do:** On the DLP-for-AI test policy, exercise the documented rollback (return to test / delete); narrow the
Communication-Compliance scope back to the pilot ring.
**Expected:** The DLP policy reverts with no residual content change; the Communication-Compliance scope
narrows cleanly; the validation evidence export confirms the before-state is restorable.
