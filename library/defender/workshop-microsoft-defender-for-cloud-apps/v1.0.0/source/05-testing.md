# 5. Testing & Knowledge-Check — Workshop: Microsoft Defender for Cloud Apps

Testing a workshop means (1) confirming each lab's **pass gate** and (2) a **knowledge-check** that each attendee can operate MDA unaided. Use the lab-helper scripts by name to validate the environment; use the check-questions to validate the people.

## Part A — Environment / lab validation (scripts)

### A1. Readiness (before the workshop)
Run **`WSMCA-Validate.ps1`**. Expected: Graph connectivity + read scopes granted, MDA alert data reachable, connected-app signal present, advanced-hunting reminder confirmed. All green = ready to teach.

### A2. Discovery sanity
Run **`WSMCA-Discovery.ps1`**. Expected: MDA alert count, connected-app presence, and an OAuth app count. Confirms Cloud Discovery, connectors, and OAuth data exist to teach against.

### A3. OAuth inventory (after Lab 3)
Run **`WSMCA-OAuthApp-Lab.ps1`**; confirm it lists OAuth apps with risk hints and that the **`OAuthRisk-Shortlist – CloudApps Lab – Pilot`** was captured.

### A4. Report-only session policy present (after Lab 4)
In **Cloud apps → Policies → Policy management**, confirm **`Monitor-Downloads – CloudApps Lab – Pilot`** exists and is **Monitor only** (not Block).

### A5. Saved queries present (after Labs 1/3/5)
In **Advanced hunting → Queries**, confirm **`Discovery-ShadowIT – CloudApps Lab – Pilot`**, **`OAuthApps – CloudApps Lab – Pilot`**, and **`Anomaly-Investigation – CloudApps Lab – Pilot`** exist and run without error.

## Part B — Knowledge-check (per attendee)

Score each attendee; passing = correct on at least 8 of 10.

1. **CASB basics:** What four questions does a CASB answer, and which MDA feature answers each?
2. **Cloud Discovery:** What feeds Cloud Discovery, and what drives an app's risk score?
3. **Shadow IT:** What does tagging an app **Unsanctioned** do, and what else is needed to actually block it?
4. **Connectors vs discovery:** How is an **app connector** different from **Cloud Discovery**?
5. **App governance:** Name two risk indicators app governance surfaces on an app.
6. **OAuth risk:** Give two OAuth app risk factors and why each is dangerous *(e.g. broad consent scopes, unverified publisher)*.
7. **Session policy:** Why author a session policy **report-only / monitor** first, and what is the enforce path?
8. **Anomaly detection:** Name three anomaly-detection alert types and one triage question for each.
9. **Hunting:** Which advanced-hunting table holds cloud-app activity, and give a field you'd pivot on. *(CloudAppEvents.)*
10. **Boundary & governance:** Which decisions (app sanctioning, consent revocation, user suspension) require the customer's approval, and who approves them?

## Part C — Live demonstration (capstone)
Each attendee, unaided, on a **second** app/alert:
- Opens Discovered apps, ranks by risk, and states one app's disposition.
- Runs one saved hunting query and interprets a result.
- Names the fitting response action and the approval required.

**Overall pass criteria:** every attendee meets Part B (≥8/10) and completes Part C; environment checks A1–A5 pass. Record results; anyone below threshold repeats the relevant lab.
