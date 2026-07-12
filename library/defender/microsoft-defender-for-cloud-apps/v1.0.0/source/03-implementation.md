# 3. Implementation Guide — Microsoft Defender for Cloud Apps

Follow these steps **in order**. Most configuration is in the **unified Defender portal** (`https://security.microsoft.com` → **Cloud apps**); Conditional Access App Control is wired in the **Entra admin center** (`https://entra.microsoft.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test. *Some MDCA settings are still consolidating from the classic portal — verify current navigation in your tenant; the Troubleshooting Guide lists fallbacks.*

> **Model:** Connect the apps and discovery, scope every policy **monitor / report-only** to a **pilot user group** first, **enable the team** on that same pilot, **prove value** with a benign audit-mode PoC, validate, and only then enforce and expand. Keep enforcing actions (block, revoke OAuth app, suspend session) and the PoC teardown `-WhatIf`- or approval-gated throughout. Never block production access to "test."

## Naming (set once, reuse verbatim)
**Phase A — Connect & Govern**
- Pilot user group (Entra): `MDCA Pilot Users – Pilot Ring – Pilot`
- App connectors effort: `MDCA App Connectors – Priority SaaS – Prod`
- OAuth app policy: `MDCA OAuth App Risk – Tenant – Report`
- Session policy (via CA App Control): `MDCA Session Control – Pilot Users – Report`
- Access policy: `MDCA Access Control – Pilot Users – Report`
- Conditional Access policy (Entra): `MDCA Session Control – Pilot Users – Report`
- Advanced-hunting saved query (signal): `MDCA Signal Validation – Tenant – Validate`

**Phase B — Enablement labs (take-home artifacts)**
- Saved hunting queries: `Discovery-ShadowIT – CloudApps – Pilot`, `OAuthApps – CloudApps – Pilot`, `Anomaly-Investigation – CloudApps – Pilot`
- Shortlists: `ShadowIT-Shortlist – CloudApps – Pilot`, `OAuthRisk-Shortlist – CloudApps – Pilot`
- Investigation doc: `Investigation – CloudApps – Pilot`

**Phase C — Proof-of-concept**
- Audit-mode activity policy: `MDCA PoC Activity Policy – Pilot Users – Audit`
- Discovery snapshot report: `MDCA PoC Discovery – Pilot – Report`
- Scorecard output file: `MDCA PoC Scorecard – Pilot Users – Validate`
- Test-signal tag (used in notes/hunting): `MDCA-PoC-TESTSIGNAL`

---

# Phase A — Connect & Govern (onboarding)

## Step A1 — Assess readiness
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MDCAFULL-Discovery.ps1` to capture the current state: MDCA activation, plan hints, admin roles, existing app connectors, Cloud Discovery source, app-governance status, and Conditional Access availability.
3. In **Entra → Groups**, create the pilot user group `MDCA Pilot Users – Pilot Ring – Pilot` and add the pilot/test users (including the account used to generate benign PoC activity in Phase C).

## Step A2 — Connect the priority apps (API connectors)
1. `security.microsoft.com` → **Cloud apps → Connected apps → App connectors → Connect an app**.
2. Connect **Microsoft 365** first, then the priority third-party apps as `MDCA App Connectors – Priority SaaS – Prod`; complete each app's admin consent / API-credential flow.
3. Confirm each connector shows **Connected** and begins pulling activity (connectors work out of band — no user impact).
4. Run `MDCAFULL-Validate.ps1 -Check Connectors` to confirm the connectors are connected and streaming.

## Step A3 — Turn on Cloud Discovery
1. `security.microsoft.com` → **Cloud apps → Cloud discovery → Settings**.
2. Enable the **Microsoft Defender for Endpoint integration** so MDE-onboarded devices feed discovery automatically (preferred). Where MDE is not the source, configure a **log collector** for the secure web gateway.
3. Confirm discovery data appears under **Cloud apps → Cloud discovery → Dashboard**.
4. Run `MDCAFULL-Validate.ps1 -Check Discovery` to confirm discovery data is flowing.

## Step A4 — Enable app governance and OAuth app policy (report-only)
1. `security.microsoft.com` → **Cloud apps → App governance** — enable it and let it inventory the tenant's OAuth apps. *App governance may require a specific plan — verify current availability.*
2. Create the OAuth app policy `MDCA OAuth App Risk – Tenant – Report` in **report-only** to flag over-privileged scopes, unverified publishers, and unusual consent patterns — **no auto-revoke** yet.
3. Run `MDCAFULL-OAuthRisk.ps1` to list the current risky OAuth apps (read-only) and `MDCAFULL-Report.ps1 -Section OAuth` for the shortlist template.
4. *Revoking an app consent is disruptive and stays approval-gated — the decision is the security team's.*

## Step A5 — Create session/access policies via Conditional Access App Control (pilot, report-only)
1. In **Entra** → **Protection → Conditional Access → New policy**, create `MDCA Session Control – Pilot Users – Report`: assign **Users = `MDCA Pilot Users – Pilot Ring – Pilot`**, target cloud apps, and under **Session** choose **Use Conditional Access App Control → Use custom policy** (routes sessions to MDCA). *Verify current App Control licensing and supported apps.*
2. In `security.microsoft.com` → **Cloud apps → Policies → Policy management**, create the session policy `MDCA Session Control – Pilot Users – Report` (e.g. monitor downloads on unmanaged devices) in **monitor** mode, and the access policy `MDCA Access Control – Pilot Users – Report` in **monitor** mode — both scoped to the pilot users.
3. Run `MDCAFULL-Validate.ps1 -Check Policy` to confirm the policies exist, are report-only, and are scoped to the pilot group.

## Step A6 — Add anomaly-detection and activity policies (monitor-first)
1. `security.microsoft.com` → **Cloud apps → Policies** — confirm the built-in **anomaly detection** policies are on (impossible travel, mass download, risky OAuth), tuned to the pilot scope where possible.
2. Add any needed **activity** or **file** policies in **report-only** first.
3. Run `MDCAFULL-Report.ps1 -Section Policies` to capture the current policy inventory and posture.

## Step A7 — Validate signal on the pilot
1. In **Hunting → Advanced hunting**, paste the **signal-validation** section of `MDCAFULL-LabQueries.kql`, run it, and **Save as `MDCA Signal Validation – Tenant – Validate`**. It confirms `CloudAppEvents` (and OAuth app data) stream from the connectors and discovery. `MDCAFULL-Validate.ps1 -Check Signal` cross-checks read-only.
2. As a pilot user, perform a benign action a monitor policy watches (e.g. a download on an unmanaged device) and confirm the expected **alert** appears in **Incidents & alerts** — without enforcement blocking anything.

---

# Phase B — Enable the team (hands-on labs)

Run the five labs **in order** against the same `MDCA Pilot Users – Pilot Ring – Pilot` scope. Every step is **read-only or report-only**; the one configuration action (the report-only session policy, already created in Step A5) and any disable/enforce are **facilitator-driven and approval-gated**. The take-home output is the saved queries, shortlists, and investigation doc.

## Lab 0 — Readiness check
1. Sign in as the **facilitator** and open the **Cloud apps** section.
2. Confirm a **Cloud Discovery** dashboard with data, at least one **Connected app**, and **App governance** enabled (from Phase A).
3. Run `MDCAFULL-Discovery.ps1` and `MDCAFULL-Validate.ps1` — confirm green. **Pass gate:** discovery + validate green; Cloud Discovery, a connector, and app governance all visible.

## Lab 1 — Cloud Discovery & shadow IT
**Goal:** run/read a discovery report, rank apps by risk, tag Sanctioned/Unsanctioned.
1. Open **Cloud apps → Cloud Discovery → Dashboard**; review total apps, traffic, and top apps by users/traffic.
2. Open **Discovered apps**; sort by **Risk score**; discuss what drives the score (compliance, security, legal factors).
3. Pick 3–5 high-risk, high-usage apps. For a clearly unsanctioned one, use the **tag** action to mark **Unsanctioned** (facilitator; note that tagging alone is informational unless a block is wired via a proxy/appliance). Mark an approved one **Sanctioned**.
4. In **Advanced hunting**, paste the **shadow-IT / discovery** section of `MDCAFULL-LabQueries.kql`; run it; **Save as `Discovery-ShadowIT – CloudApps – Pilot`**.
5. Build the **`ShadowIT-Shortlist – CloudApps – Pilot`** — top risky apps and a recommended disposition (sanction / restrict / block-later). **App-sanctioning decisions are the customer's** — the shortlist is a recommendation.
6. **Pass gate:** each attendee can explain the risk score and name the top shadow-IT app and its proposed disposition.

## Lab 2 — App governance & connected apps
**Goal:** examine a connected app's activity and use app governance to read app behavior.
1. Open **Cloud apps → Connected apps**; open the **Microsoft 365** connector; review **Activity log**, **Files**, and **Accounts** tabs.
2. Open **Cloud apps → App governance**; review the app inventory: permissions, data access, usage, and any **risk factors / alerts**.
3. Pick one app with notable permissions/usage; walk its behavior (API calls, data accessed, users). Discuss "normal" vs "suspicious."
4. In **Advanced hunting**, run the **connected-app activity** section of `MDCAFULL-LabQueries.kql` against `CloudAppEvents`; review results.
5. **Pass gate:** each attendee can navigate a connected app's activity log and state one app-governance risk indicator and what it means.

## Lab 3 — OAuth app risk (approval-gated rehearsal)
**Goal:** inventory OAuth apps, read consent/permission risk, and rehearse disable/revoke.
1. Open the **OAuth apps** inventory (**Cloud apps → OAuth apps**, and/or **App governance**). Review third-party apps granted access, their **permission level**, **community use**, and **publisher verification**.
2. Run `MDCAFULL-OAuthRisk.ps1` — a **read-only** enumeration of service principals and OAuth grants with risk hints (high-privilege scopes, unverified publisher, broad consent). It changes nothing.
3. In **Advanced hunting**, run the **OAuth apps** section of `MDCAFULL-LabQueries.kql`; **Save as `OAuthApps – CloudApps – Pilot`**.
4. Build the **`OAuthRisk-Shortlist – CloudApps – Pilot`** — the riskiest apps by consent scope and verification status.
5. **Response rehearsal (approval-gated):** discuss how you would **disable / revoke consent** for a risky app (from the OAuth apps inventory or Entra Enterprise applications). **Describe/queue for approval; do not revoke a production app** — revoking consent can break a legitimate integration. Revocation is a change the customer's app owners/security approve.
6. **Pass gate:** each attendee names two OAuth risk indicators and states who must approve a consent revocation.

## Lab 4 — Session & access policies, report-only first
**Goal:** understand the Conditional Access App Control session policy in **monitor/report-only** mode and the enforce path.
1. Confirm the app is routed through **Conditional Access App Control** (the CA policy `MDCA Session Control – Pilot Users – Report` from Step A5). *Verify current setup in your tenant.*
2. Open the session policy `MDCA Session Control – Pilot Users – Report` in **Cloud apps → Policies → Policy management**; confirm it is **Monitor only** (not Block), scoped to the pilot group.
3. Generate benign activity (a download in the pilot session) and observe it **logged, not blocked**.
4. Discuss the enforce path: how you would change **Monitor only → Block download** after validation, staged to a ring, with a rollback. **Enforcement is staged and change-approved — not done during training.**
5. **Pass gate:** each attendee can describe the monitor→enforce progression and the rollback.

## Lab 5 — Anomaly detection & investigation
**Goal:** read anomaly-detection alerts, triage, and rehearse response.
1. Open **Incidents & alerts → Alerts**; filter **Service source = Defender for Cloud Apps**. Review anomaly-detection alert types (impossible travel, mass download, unusual admin activity, ransomware-like activity).
2. Take one alert (or a `CloudAppEvents` hit) through triage: which user/app, what activity, is it expected, what would escalate it.
3. In **Advanced hunting**, run the **anomaly investigation** section of `MDCAFULL-LabQueries.kql`; **Save as `Anomaly-Investigation – CloudApps – Pilot`**. Cross-check the user's activity across apps.
4. Capture findings in **`Investigation – CloudApps – Pilot`**: what happened, which user/app, confidence, recommended action.
5. **Response rehearsal (approval-gated):** review response options (suspend user, require sign-in, mark app unsanctioned/block via proxy). **Rehearse and queue for approval; do not action a production user.** **Incident-response decisions are the SOC/security team's.**
6. **Pass gate:** a completed investigation doc plus each attendee stating the fitting response and who approves it.

## Lab wrap-up
1. Confirm the take-home artifacts: the three saved hunting queries, the report-only session policy, the two shortlists, and the investigation doc.
2. Run the **knowledge-check** in `05-testing.md` (Part B).

---

# Phase C — Prove value (guided proof-of-concept)

Run the PoC on the same pilot users, **benign and audit-mode only**. All test signal is Microsoft's sample discovery log and benign policy-matching activity — **never real exfiltration or attacks**. Enforcement stays **off**; every change is previewed with `-WhatIf` first.

## Step C1 — Enable an audit-mode policy for the pilot
1. Run `MDCAFULL-PoC.ps1 -Action Enable -WhatIf` to preview (changes nothing): plan, roles, discovery source, connectors, and whether the pilot group exists.
2. `security.microsoft.com` → **Cloud apps → Policies → Policy management → Create policy → Activity policy**. Name it `MDCA PoC Activity Policy – Pilot Users – Audit`. Scope the filter to `MDCA Pilot Users – Pilot Ring – Pilot`, choose a benign, repeatable trigger (e.g. a specific administrative activity or a download threshold), and set **Governance actions = none** (audit only — no block, no session control).
3. Re-run `MDCAFULL-PoC.ps1 -Action Enable` (without `-WhatIf`) to guide/mark the audit-policy creation scoped to the pilot group.

## Step C2 — Generate benign test signal
1. Run `MDCAFULL-PoC.ps1 -Action Signal` (or follow its printed steps). It performs only **benign, documented** actions tagged `MDCA-PoC-TESTSIGNAL`:
   - **Cloud Discovery:** `Cloud apps → Cloud discovery → Actions → Create Cloud Discovery snapshot report` → upload Microsoft's **sample Cloud Discovery log**. This produces the Shadow IT report `MDCA PoC Discovery – Pilot – Report` from safe, sample data.
   - **Policy-matching activity:** as the test account, perform the **benign** action the audit policy watches for (e.g. download a few non-sensitive files from a monitored app). Nothing is exfiltrated.
2. **Do not** exfiltrate real data, connect a malicious app, or grant a risky OAuth consent. The sample log and benign activity are sufficient.
3. Note the time of each signal for the scorecard latency comparison.

## Step C3 — Validate and demonstrate the detections
1. Run `MDCAFULL-Validate.ps1 -Check PoC` — it confirms (read-only): the discovery report populated, the audit policy `MDCA PoC Activity Policy – Pilot Users – Audit` matched, an alert surfaced (`AlertInfo`), and activity appears in `CloudAppEvents`.
2. Walk the demo in the portal: `Cloud apps → Cloud discovery → Dashboard` (the Shadow IT report), `Cloud apps → Activity log` (the benign activity), `Cloud apps → Alerts` / **Incidents & alerts** (the policy match).
3. Confirm **no governance action** was taken (audit only) and no production user affected.

## Step C4 — Score against your criteria
1. Run `MDCAFULL-PoC.ps1 -Action Score -CriteriaPath .\criteria.json -OutFile "MDCA PoC Scorecard – Pilot Users – Validate.json"`. It maps each observation (discovery populated, policy matched, alert surfaced, activity visible) to your pass/fail criteria and writes the scorecard.
2. Review the scorecard with stakeholders — the decision artefact.

## Step C5 — Tear down (clean rollback)
1. Run `MDCAFULL-PoC.ps1 -Action Teardown -WhatIf` first to preview, then for real.
2. Teardown: **delete** the policy `MDCA PoC Activity Policy – Pilot Users – Audit`, **delete** the discovery report `MDCA PoC Discovery – Pilot – Report`, **remove** any optional PoC connector, and **resolve** the `MDCA-PoC-TESTSIGNAL` alerts. Keep the scorecard as your record. *The teardown is a destructive action — it stays `-WhatIf`-gated by default.*

---

# Enforce and expand tenant-wide
1. **Policies:** after validation, move the pilot session/access policies from **monitor** to **enforce** for the pilot group, confirm no false positives, then broaden the CA policy `MDCA Session Control – Pilot Users – Report` scope in waves toward the full tenant.
2. **Connectors:** add connectors for the remaining SaaS apps.
3. **OAuth governance:** review flagged apps with the security team; only then consider approval-gated revocation for the riskiest.
4. **Discovery:** expand the discovery source coverage (more MDE devices / log-collector sources).
5. **Team:** use the labs and runbook to onboard new analysts.
6. Re-baseline with `MDCAFULL-Report.ps1 -SaveBaseline` and track coverage/OAuth-risk drift each cycle.

---
### Order of operations
`Assess → connect apps (M365 first) → turn on Cloud Discovery → enable app governance + OAuth report policy → create session/access policies via CA App Control (pilot, report-only) → add anomaly/activity policies → validate signal → run the five enablement labs → run the benign audit-mode PoC (enable → signal → validate → score → teardown) → enforce + expand`
