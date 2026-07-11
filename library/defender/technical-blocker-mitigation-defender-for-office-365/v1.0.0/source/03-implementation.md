# 3. Implementation Guide — Technical Blocker Mitigation: Defender for Office 365

Follow these steps **in order**. This is a **diagnostic loop**, not a build: you assess to pinpoint the blocker, apply one targeted documented fix, re-test the affected recipients, and only then resume the rollout. All scripts are **read-only**; every *fix* is a manual step you apply deliberately. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Assess (pinpoint) → Configure (fix) → Pilot (re-test affected recipients) → Validate (confirm applied) → Expand (resume rollout). Never change mail flow to "test," and keep mail-remediation actions approval-gated throughout.

## Naming (set once, reuse verbatim)
- Affected recipient subset: `MDO Blocker Triage – Affected Recipients – Diagnose`
- Advanced-hunting saved query (policy/telemetry check): `MDO Policy Blocker Check – Tenant – Diagnose`
- Support bundle output: `MDO Support Bundle – <case> – Escalate`
- Discovery snapshot file: `MDO-blocker-discovery.json`

## Step 1 — Assess: pinpoint the blocker (read-only)
1. Connect read-only: `Connect-ExchangeOnline` (View-Only role) and, for hunting, `Connect-MgGraph`.
2. Run `TBMMDO-Discovery.ps1`. It captures the evaluation chain in one snapshot (`MDO-blocker-discovery.json`): licensed MDO plans, accepted domains, preset-security-policy state, custom Safe Links / Safe Attachments / anti-phishing policies with their **priority order**, whether each is **enabled**, and their **scope** (included/excluded recipients).
3. Assemble `MDO Blocker Triage – Affected Recipients – Diagnose` from the mailboxes showing the symptom.
4. Read the snapshot top-down against the evaluation chain (Overview §"How evaluation actually works") and identify the **earliest broken link** — plan, routing, precedence, or feature scope.

## Step 2 — Assess: analyze mail routing and precedence (read-only)
1. Run `TBMMDO-MailFlow.ps1`. It reports accepted domains, inbound connectors, and any gateway/hybrid routing hints — confirming whether inbound mail actually reaches EOP first.
2. Review the **policy precedence** section of the discovery output: for the affected recipients, which **single** policy of each type actually wins (preset over custom, by priority). A "configured but never-applied" policy is almost always losing on precedence or scope.
3. Record which link is broken before changing anything.

## Step 3 — Configure: apply the one targeted fix (manual, documented)
Apply **only** the fix for the blocker you identified. Each is a deliberate manual step — the scripts never make these changes.

- **Mail-flow / routing conflict:** Correct the routing so inbound mail reaches **EOP** first — fix the public **MX**, or adjust/remove the **inbound connector** or third-party gateway that bypasses filtering. *This changes mail delivery — pilot on the affected recipients' domain path and confirm delivery before wider change.*
- **Policy precedence:** In **Email & collaboration → Policies & rules → Threat policies**, adjust **priority** so the intended policy wins for the affected recipients, or remove the **exclusion** that drops them out of scope. Remember only one policy of each type applies per recipient.
- **Safe Links / Safe Attachments not applying:** Enable the policy and add `MDO Blocker Triage – Affected Recipients – Diagnose` to its **included** scope (or use a preset policy scoped to them). Confirm the feature toggles (URL rewrite / dynamic delivery) are on.
- **Licensing gap:** Assign the MDO plan the feature needs (P1 for Safe Links/Attachments, P2 for Explorer/Attack Sim) in **Billing → Licenses**. *Verify the exact plan requirement in your tenant.*

## Step 4 — Pilot: re-test the fix on the affected recipients only
1. Apply the fix scoped to `MDO Blocker Triage – Affected Recipients – Diagnose` only — not the tenant.
2. Send the safe test message (Requirements 2.5) to a recipient in the subset.
3. Give policy propagation time (threat-policy changes can take time to apply), then validate.

## Step 5 — Validate: confirm the policy now applies
1. Run `TBMMDO-Validate.ps1`. It runs the saved query `MDO Policy Blocker Check – Tenant – Diagnose` against `EmailEvents` / `UrlClickEvents` for the affected recipients and confirms the protection engaged (link rewritten / attachment detonated / message acted on).
2. Cross-check in **message trace** that the expected MDO action appears for the test message.
3. Run `TBMMDO-Report.ps1` for the before/after evidence.
4. Complete the **Testing Guide** for the blocker class before expanding.

## Step 6 — Expand: resume the stalled rollout
1. With the affected recipients green, broaden the corrected policy scope / preset to the remaining recipients in waves.
2. Re-run `TBMMDO-Validate.ps1` after each wave and compare with `TBMMDO-Report.ps1`.
3. If a wave re-introduces the symptom, return to Step 1 for that subset — precedence can differ by recipient group.

## Step 7 — Escalate (only if it is a service issue, not your config)
1. If routing reaches EOP, the winning policy is correct and scoped, the plan is assigned, and the test still is not protected, it may be a Microsoft service issue.
2. Run `TBMMDO-SupportBundle.ps1` to assemble `MDO Support Bundle – <case> – Escalate` — the discovery snapshot, mail-flow analysis, the affected recipients, message-trace IDs, and timestamps.
3. Open a Microsoft support case, attach the bundle, and reference the escalation criteria in the Troubleshooting Guide. *Incident-response decisions remain the SOC's; this is a service-support escalation.*

---
### Order of operations
`Assess (discovery + mail-flow/precedence) → identify earliest broken link → apply the one targeted fix → re-test the affected recipients → validate the policy applies → resume rollout → escalate with a bundle only if it is a service issue`
