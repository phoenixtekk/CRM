# 3. Implementation Guide — Technical Blocker Mitigation: Defender for Cloud Apps

Follow these steps **in order**. This is a **diagnostic loop**, not a build: you assess to pinpoint the blocker, apply one targeted documented fix, re-test the affected apps/policies in monitor mode, and only then resume the rollout. All scripts are **read-only**; every *fix* is a manual step you apply deliberately. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Assess (pinpoint) → Configure (fix) → Pilot (re-test affected apps, monitor-first) → Validate (confirm engaging) → Expand (resume rollout). Keep session-control enforcement (block/restrict/quarantine) approval-gated and monitor-first throughout.

## Naming (set once, reuse verbatim)
- Affected app/connector/policy subset: `MDCA Blocker Triage – Affected Apps – Diagnose`
- Conditional Access App Control policy: `Use Conditional Access App Control – Pilot Apps – Diagnose`
- Advanced-hunting saved query (connector/activity check): `MDCA Connector Blocker Check – Tenant – Diagnose`
- Support bundle output: `MDCA Support Bundle – <case> – Escalate`
- Discovery snapshot file: `MDCA-blocker-discovery.json`

## Step 1 — Assess: pinpoint the blocker (read-only)
1. Sign in to `security.microsoft.com` as **Security Reader** and open **Cloud apps → App connectors** and **Cloud discovery → Dashboard** to read current state.
2. Run `TBMMCA-Discovery.ps1`. It captures the signal chain: licensed MDCA plan, whether cloud-app activity signal is arriving (`CloudAppEvents` presence — a proxy for working connectors), whether device-based discovery signal is present, and a summary of Conditional Access policies that use **App Control**. It records the state to `MDCA-blocker-discovery.json`.
3. Run `TBMMCA-ConditionalAccess.ps1` to enumerate the CA policies whose session controls use **Conditional Access App Control**, their **enabled state**, and which apps/users they target.
4. Read both outputs top-down against the signal chain (Overview §"How signal actually works") and identify the **earliest broken link**:
   - No plan / not activated → **licensing/activation blocker**
   - Connector error/disconnected, no `CloudAppEvents` → **connector-auth blocker**
   - Discovery dashboard empty → **discovery no-data blocker**
   - No/misscoped CA App Control policy → **session-control blocker**

## Step 2 — Configure: apply the one targeted fix (manual, documented)
Apply **only** the fix for the blocker you identified. Each is a deliberate manual step — the scripts never make these changes.

- **Licensing / activation:** Assign the MDCA plan (**Billing → Licenses**) and confirm the portal is activated. For CA App Control, confirm the required Entra plan. *Verify the exact plan requirements in your tenant.*
- **Connector authentication:** In **Cloud apps → App connectors**, reconnect the affected connector — re-consent the app registration, refresh the expired token, and confirm the connector account still has the required permissions in the SaaS app. Confirm status returns to **connected**.
- **Cloud Discovery no-data:** Confirm and repair the discovery source — turn on the **Defender for Endpoint integration** under **Cloud discovery → Settings** (and confirm devices are onboarded to MDE), or fix the log collector / secure-web-gateway feed / manual upload so logs arrive.
- **Session policy / CA App Control:** In `entra.microsoft.com` → **Conditional Access**, confirm the policy `Use Conditional Access App Control – Pilot Apps – Diagnose` is **enabled**, targets the affected users/apps, and its session control is set to **Use Conditional Access App Control** (monitor-only to start). In MDCA, confirm the target app is **onboarded to session control**.

## Step 3 — Pilot: re-test the fix on the affected apps/policies only
1. Apply the fix scoped to `MDCA Blocker Triage – Affected Apps – Diagnose` only — not the whole estate — and keep session policies in **monitor** mode.
2. For a session-control fix, have the pilot user (Requirements 2.5) sign in to the target app in a browser and generate activity.
3. Give connector/discovery/session signal time to appear, then validate.

## Step 4 — Validate: confirm the blocker is cleared
1. Run `TBMMCA-Validate.ps1`. It runs the saved query `MDCA Connector Blocker Check – Tenant – Diagnose` against `CloudAppEvents` for the affected apps and returns pass/fail for activity signal.
2. In the portal, confirm the connector shows **connected**, the discovery dashboard shows data, and the session policy shows a hit in the **activity log** for the test session.
3. Run `TBMMCA-ConditionalAccess.ps1` again to confirm the App Control policy is enabled and scoped.
4. Run `TBMMCA-Report.ps1` for the before/after evidence.
5. Complete the **Testing Guide** for the blocker class before expanding.

## Step 5 — Expand: resume the stalled rollout
1. With the affected subset green, reconnect the remaining connectors / expand discovery / broaden the CA App Control scope in waves — still monitor-first for session controls.
2. Re-run `TBMMCA-Validate.ps1` after each wave and compare with `TBMMCA-Report.ps1`.
3. Only after monitoring is trusted, and with SOC approval, move any session policy from monitor to enforce. *That enforcement decision is the SOC's.*

## Step 6 — Escalate (only if it is a service issue, not your config)
1. If the plan is assigned, the connector re-consented, the discovery source confirmed, and the CA App Control policy enabled and scoped, but the blocker persists, it may be a Microsoft service issue.
2. Run `TBMMCA-SupportBundle.ps1` to assemble `MDCA Support Bundle – <case> – Escalate` — the discovery snapshot, the CA App Control analysis, the affected apps/policies, and timestamps.
3. Open a Microsoft support case, attach the bundle, and reference the escalation criteria in the Troubleshooting Guide. *Incident-response decisions remain the SOC's; this is a service-support escalation.*

---
### Order of operations
`Assess (discovery + CA App Control analysis) → identify earliest broken link → apply the one targeted fix → re-test the affected apps monitor-first → validate engaging → resume rollout → escalate with a bundle only if it is a service issue`
