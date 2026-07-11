# 3. Implementation — Enablement Kit Runbook: Microsoft Defender for Cloud Apps

This is the **facilitator + student runbook**. Run the labs in order against the **pilot** scope from R2/R3. Every object uses the naming convention **`<Purpose> – <Scope> – <Stage>`** and is reused by name in later labs, testing, and the scripts. All steps are **read-only or report-only / preview-first**; the one configuration action (a **report-only** session policy) and any disable/enforce are **facilitator-driven and approval-gated**.

**Naming convention used throughout**
- Report-only session policy: **`Monitor-Downloads – CloudApps Lab – Pilot`**.
- Saved hunting queries: **`Discovery-ShadowIT – CloudApps Lab – Pilot`**, **`OAuthApps – CloudApps Lab – Pilot`**, **`Anomaly-Investigation – CloudApps Lab – Pilot`**.
- Shadow-IT shortlist output: **`ShadowIT-Shortlist – CloudApps Lab – Pilot`**.
- OAuth risk shortlist: **`OAuthRisk-Shortlist – CloudApps Lab – Pilot`**.
- Investigation doc: **`Investigation – CloudApps Lab – Pilot`**.

> Navigation reflects the current Defender portal (`https://security.microsoft.com` → **Cloud apps**). Some MDA settings are still consolidating from the classic portal — *verify current navigation in your tenant*; the troubleshooting guide lists fallbacks.

---

## Lab 0 — Readiness check (Assess)
1. Sign in as the **facilitator** and open the **Cloud apps** section.
2. Confirm: a **Cloud Discovery** dashboard with data (R2), at least one **Connected app** (R3), and **App governance** enabled (R4).
3. Run `powershell -ExecutionPolicy Bypass -File .\WSMCA-Discovery.ps1` — confirm it reports MDA alerts, connected-app signal, and an OAuth app count.
4. Run `powershell -ExecutionPolicy Bypass -File .\WSMCA-Validate.ps1` — confirm readiness checks pass.
5. **Pass gate:** discovery + validate green; Cloud Discovery, a connector, and app governance all visible. Resolve via R1–R6 if not.

---

## Lab 1 — Cloud Discovery & shadow IT (Configure/learn)
**Goal:** run/read a discovery report, rank apps by risk, and tag Sanctioned/Unsanctioned.

1. Open **Cloud apps → Cloud Discovery → Dashboard**. Review total apps, traffic, and top apps by users/traffic.
2. Open **Discovered apps**. Sort by **Risk score**. Discuss what drives the score (compliance, security, legal factors in the app catalog).
3. Pick 3–5 high-risk, high-usage apps. For a clearly unsanctioned one, use the **tag** action to mark **Unsanctioned** (facilitator; discuss that tagging alone is informational unless a block is wired via a proxy/appliance). Mark an approved one **Sanctioned**.
4. In **Advanced hunting**, paste the **Discovery / shadow-IT** section of `WSMCA-LabQueries.kql`; run it; **Save as `Discovery-ShadowIT – CloudApps Lab – Pilot`**.
5. Build the **`ShadowIT-Shortlist – CloudApps Lab – Pilot`** — the top risky apps and a recommended disposition (sanction / restrict / block-later). **App-sanctioning decisions are the customer's** — the shortlist is a recommendation.
6. **Pass gate:** each attendee can explain the risk score and name the top shadow-IT app and its proposed disposition.

---

## Lab 2 — App governance & connected apps (Pilot)
**Goal:** examine a connected app's activity and use app governance to read app behavior.

1. Open **Cloud apps → Connected apps**; open the **Microsoft 365** (or other) connector; review **Activity log**, **Files**, and **Accounts** tabs.
2. Open **Cloud apps → App governance**. Review the app inventory: permissions, data access, usage, and any **risk factors / alerts** on apps.
3. Pick one app with notable permissions/usage; walk its behavior (API calls, data accessed, users). Discuss what "normal" vs "suspicious" looks like.
4. In **Advanced hunting**, run the **Connected-app activity** section of `WSMCA-LabQueries.kql` against `CloudAppEvents`; review results.
5. **Pass gate:** each attendee can navigate a connected app's activity log and state one app-governance risk indicator and what it means.

---

## Lab 3 — OAuth app risk (Pilot, approval-gated rehearsal)
**Goal:** inventory OAuth apps, read consent/permission risk, and rehearse disable/revoke.

1. Open the **OAuth apps** inventory (**Cloud apps → OAuth apps**, and/or **App governance**). Review third-party apps that have been granted access, their **permission level**, **community use**, and **publisher verification**.
2. Run `powershell -ExecutionPolicy Bypass -File .\WSMCA-OAuthApp-Lab.ps1` — a **read-only** enumeration of service principals and OAuth grants with risk hints (high-privilege scopes, unverified publisher, broad consent). It changes nothing.
3. In **Advanced hunting**, run the **OAuth apps** section of `WSMCA-LabQueries.kql`; **Save as `OAuthApps – CloudApps Lab – Pilot`**.
4. Build the **`OAuthRisk-Shortlist – CloudApps Lab – Pilot`** — the riskiest apps by consent scope and verification status.
5. **Response rehearsal (approval-gated):** discuss how you would **disable / revoke consent** for a risky app (from the OAuth apps inventory or Entra Enterprise applications). **In the enablement kit, describe/queue for approval; do not revoke a production app** — revoking consent can break a legitimate integration. Revocation is a change the customer's app owners/security approve.
6. **Pass gate:** each attendee names two OAuth risk indicators and states who must approve a consent revocation.

---

## Lab 4 — Session & access policies, report-only first (Validate)
**Goal:** author a Conditional Access App Control session policy in **monitor / report-only** mode and understand the enforce path.

1. Confirm the app is routed through **Conditional Access App Control** (session control requires the Entra Conditional Access integration — *verify current setup in your tenant*).
2. Open **Cloud apps → Policies → Policy management → Create policy → Session policy**.
3. Create **`Monitor-Downloads – CloudApps Lab – Pilot`**: session control type **Monitor only** (or an action set to **Test/report** where offered), scoped to the pilot group and the pilot app. **Do not** set it to **Block** for the enablement kit.
4. Generate benign activity (a download in the pilot session) and observe it logged — **monitored, not blocked**.
5. Discuss the enforce path: how you would change **Monitor only → Block download** after validation, staged to a pilot ring, with a rollback. **Enforcement is staged and change-approved — not done during training.**
6. **Pass gate:** the report-only policy exists and each attendee can describe the monitor→enforce progression and the rollback.

---

## Lab 5 — Anomaly detection & investigation (Validate/Expand)
**Goal:** read anomaly-detection alerts, triage, and rehearse response.

1. Open **Incidents & alerts → Alerts**; filter **Service source = Defender for Cloud Apps**. Review anomaly-detection alert types (impossible travel, mass download, unusual admin activity, ransomware-like activity).
2. Take one alert (or a `CloudAppEvents` hit) through triage: which user/app, what activity, is it expected, what would escalate it.
3. In **Advanced hunting**, run the **Anomaly investigation** section of `WSMCA-LabQueries.kql`; **Save as `Anomaly-Investigation – CloudApps Lab – Pilot`**. Cross-check the user's activity across apps.
4. Capture findings in **`Investigation – CloudApps Lab – Pilot`**: what happened, which user/app, confidence, recommended action.
5. **Response rehearsal (approval-gated):** review MDA response options (suspend user, require sign-in, mark app unsanctioned/block via proxy). **Rehearse and queue for approval; do not action a production user.** **Incident-response decisions are the SOC/security team's.**
6. **Pass gate:** a completed investigation doc plus each attendee stating the fitting response and who approves it.

---

## Wrap-up (Expand)
1. Confirm the take-home artifacts: the three saved hunting queries, the report-only session policy, the two shortlists, and the investigation doc.
2. Run the **knowledge-check** in `05-testing.md`.
3. Agree the **expand** plan: move policies from report-only to staged enforcement through the customer's change process, and use the runbook to onboard new analysts.
