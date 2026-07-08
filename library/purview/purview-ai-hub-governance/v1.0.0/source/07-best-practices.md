# 7. Best Practices — Purview AI Hub Governance (DSPM for AI)

Field-tested practices for governing AI usage from DSPM for AI — getting visibility and control **without
breaking legitimate AI productivity** and **without over-collecting** in HR-sensitive areas. These
complement the Implementation and Testing guides.

## Start with visibility, then control
- **See before you block.** Turn on audit and read the DSPM-for-AI reports **first**. Understand which AI
  apps are used and whether sensitive data appears before you enforce anything — visibility is cheap and
  reversible; enforcement is not.
- **Let labels do the heavy lifting.** Copilot honors sensitivity labels and encryption natively. A good
  label taxonomy already keeps AI from surfacing content users aren't entitled to — invest there before
  adding AI-specific DLP.
- **Withhold from AI only what truly must be.** Keeping content out of AI processing is powerful but reduces
  AI usefulness. Reserve the DLP-for-AI "protect labeled content" control for the **most sensitive** label
  (e.g. `Highly Confidential`), not broadly.

## Rollout discipline (DLP over AI is high-impact — simulate first)
- **Simulation is mandatory, not optional.** A DLP-for-AI policy runs in **TestWithoutNotifications** on the
  pilot ring until the match quality is proven. `AIHUB-Validation.ps1` asserts the policy is **not** `Enable`
  during the pilot — treat any `Enable` during pilot as a stop-and-fix.
- **`-WhatIf` before every commit.** The scriptable writes (audit enablement, the DLP policy, mode changes)
  preview with `-WhatIf` and change nothing until `-Commit`. Read the preview.
- **Enforce the pilot ring first, then widen.** Move to `Enable` for `grp-ai-pilot@contoso.com` before the
  broad scope, and re-validate after each increase.
- **Verify the AI DLP action in the portal.** The exact DLP location/action that governs AI/Copilot is
  **portal-driven and evolving** — confirm it in DSPM for AI after creating the policy; **verify the current
  action for your tenant**. Don't assume a scripted skeleton is the whole control.

## Privacy-by-design for the HR-sensitive detections
- **Pseudonymize and separate roles.** Insider-risk and communication-compliance data is sensitive. Turn on
  **pseudonymization** where applicable and keep reviewer roles **separated** from general admin — enforce
  this in configuration, not just policy.
- **Detection is not adjudication.** These policies raise **reviewable signals**; the **outcome** (is this a
  violation? what action?) is an **HR/legal determination**. Build the review workflow with HR/legal and keep
  the decision with them.
- **Minimize collection.** Scope the detections to the risky patterns that matter; don't collect everything
  because you can.

## Operating the program
- **Re-baseline on a cadence.** DSPM for AI is **new and evolving** — new AI apps, new record types, and
  changed portal paths appear. Run `AIHUB-Discovery.ps1` / `AIHUB-Report.ps1` regularly and re-check the
  DSPM-for-AI recommendations.
- **Watch for drift.** `AIHUB-Readiness.ps1` flags audit turned off, a DLP-for-AI policy stranded in test after
  expansion (or flipped to enforce prematurely), missing onboarding, or a licensing/preview change.
- **Document a rollback per control.** Each control is reversible: set DLP back to test, disable a detection,
  turn a signal off. Know the exact command/portal step before you enforce.
- **Communicate before you restrict.** Surprise AI restrictions generate tickets and shadow-AI. Tell users what
  is changing and why before enforcing.

## Security & safety hygiene
- **No credentials in code.** Scripts authenticate interactively via `Connect-IPPSSession` / `Connect-MgGraph`;
  never embed secrets. Store exported evidence securely — it may describe sensitive AI usage.
- **Read-only or `-WhatIf` by default.** Discovery/validation/reporting/readiness scripts are read-only; the
  config script defaults to `-WhatIf` and requires `-Commit` for any write. Keep it that way.
- **Verify licensing/preview/tenant before relying on a capability.** DSPM for AI mixes free, premium, and
  preview features and the portal evolves — flag, don't assume; don't invent portal paths, policy names, or
  audit record types.
