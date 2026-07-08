# 6. Troubleshooting Guide — Purview AI Hub Governance (DSPM for AI)

Symptom → likely root cause → fix. Use **`AIHUB-Discovery.ps1`** (posture), **`AIHUB-Readiness.ps1`**
(licensing / audit / pilot sanity), **`AIHUB-Validation.ps1`** (audit + DLP mode/scope), and
**`AIHUB-Report.ps1`** (AI activity + DLP matches) to confirm before and after each fix. DSPM for AI is
**new, partly preview, and evolving** — portal paths, policy names, and audit record types change, and
much of the experience is **portal-driven**; where flagged, **verify against current Microsoft guidance /
your tenant** rather than assuming. The DSPM-for-AI portal reports are the authoritative view; the scripts
supplement them.

## A. Visibility / setup

### No AI-interaction activity appears
- **Audit disabled.** AI visibility depends on unified audit. **Fix:** `AIHUB-Readiness.ps1`; if off,
  `AIHUB-Config.ps1 -EnableAudit -Commit` (Req 2.4); allow ingestion latency.
- **No AI usage yet / record type differs.** **Fix:** confirm pilot users are actually using AI; the AI
  audit **record type/operations evolve** — **verify the current AI record type for your tenant** and widen
  the report window (`AIHUB-Report.ps1 -Days 30`).

### The DSPM-for-AI experience or a recommended policy isn't available
- **Licensing / preview.** Some capabilities need E5 / E5 Compliance and some are **in preview**. **Fix:**
  `AIHUB-Readiness.ps1` licensing signal; confirm the plan and the capability's preview status — **verify
  your licensing/tenant**.

## B. Copilot / label protection

### Copilot surfaces content the user shouldn't see
- **Content not labeled/encrypted, or labels not published.** Copilot honors labels/encryption only where
  they're applied. **Fix:** confirm the content is actually labeled and the labels are published (Req 2.5);
  **verify current Copilot label-honoring behaviour for your tenant** (Test 2).

### Labeled output loses its label after AI processing
- **Label inheritance gap.** **Fix:** confirm the label policy and Copilot integration; **verify current
  behaviour** — this area evolves.

## C. DLP-for-AI policy

### The DLP-for-AI policy isn't matching labeled content in simulation
- **Rule condition wrong, or AI scope/action not set in the portal.** **Fix:** confirm the rule targets the
  correct sensitivity label; then open the policy in **DSPM for AI** and confirm the **AI/Copilot scope +
  protect action** — this part is **portal-driven and evolving**, so the scripted skeleton alone won't
  match. **Verify the current AI DLP action for your tenant** (Step 5).

### The DLP-for-AI policy is blocking real work
- **Enforcing during the pilot, or matching too broadly.** **Fix:** `AIHUB-Validation.ps1` — if `Mode` is
  `Enable` during the pilot, set it back to test immediately (`AIHUB-Config.ps1 -SetDlpMode -Mode
  TestWithoutNotifications -Commit`); if the condition is too broad, tighten it and re-simulate. A pilot
  DLP-for-AI policy must **never** enforce.

### Enforcement leaked beyond the pilot ring
- **Scope too wide.** **Fix:** confirm the policy scope targets `grp-ai-pilot@contoso.com` only (portal);
  correct and re-validate before widening.

## D. Insider-risk / communication-compliance detections

### No risky-AI signals are generated
- **Policy not enabled / conditions not met / roles.** **Fix:** confirm `AI-IRM-RiskyAIUsage` and
  `AI-CC-PromptResponse` are enabled in their solutions with the intended scope; confirm the reviewer holds
  the right role. These are **portal-configured** (limited cmdlets).

### Privacy settings aren't applied (pseudonymization / role separation)
- **Configured without privacy-by-design.** **Fix:** re-configure per Req 2.8 — turn on pseudonymization
  where applicable and separate reviewer roles from general admin. **Outcomes are HR/legal determinations**
  — you configure detection and review, not the case decision.

## E. Consumer-AI egress

### Sensitive data pasted into consumer AI sites isn't surfaced
- **Devices not onboarded / extension missing.** **Fix:** confirm device onboarding and the Purview browser
  extension deployment (Req 2.7); **verify current browser/extension support for your tenant** (Test 6).

## F. Drift / operations

### Audit, a policy, or a detection changed unexpectedly
- **Config drift, or a preview capability changed.** **Fix:** run `AIHUB-Discovery.ps1` / `AIHUB-Readiness.ps1`
  on a cadence; reconcile audit state, DLP-for-AI mode/scope, and the detections against the signed-off
  design; re-check the DSPM-for-AI recommendations for new/changed items.

### A DLP-for-AI policy is stranded in test after expansion (or enforcing prematurely)
- **Rollout not completed / enforced too early.** **Fix:** `AIHUB-Readiness.ps1` flags a pilot/sim-named
  policy in the wrong mode; move it deliberately (`AIHUB-Config.ps1 -SetDlpMode …`) once the pilot passes,
  and re-validate.

---
## Escalation checklist
1. `AIHUB-Readiness.ps1` — licensing signal, audit on, DLP-for-AI in the right mode, onboarding/preview reminders?
2. `AIHUB-Discovery.ps1` — is AI activity appearing? do labels exist? is there an AI/Copilot DLP policy?
3. `AIHUB-Validation.ps1` — audit on, DLP in Test (never Enable during pilot), scoped to the pilot ring, target label present?
4. Portal (DSPM for AI) — Copilot honors labels, the AI DLP scope/action is set, and the insider-risk/comms-compliance detections are enabled privacy-by-design?
5. Still stuck → capture the exact behaviour and **verify the current Microsoft DSPM-for-AI guidance / your
   tenant** (portal paths, policy names, audit record types, preview status) before a broad change. What AI
   usage is acceptable, which content is withheld from AI, and case outcomes remain governance/HR/legal
   determinations — this guide fixes the *technical configuration*, not the *decision*.
