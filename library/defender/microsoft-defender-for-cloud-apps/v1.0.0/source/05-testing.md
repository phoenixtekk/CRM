# 5. Testing Guide — Microsoft Defender for Cloud Apps

Testing spans all three phases: **Part A** validates the deployment (Phase A), **Part B** is the enablement knowledge-check (Phase B), and **Part C** is the proof-of-concept gate (Phase C). Each test has a **pass/fail gate**; do not enforce or expand until the pilot passes. Objects are referenced by the exact names from the Implementation Guide. Run the scripts by name to validate the environment.

---

# Part A — Deployment validation (Phase A)

## A1 — App connectors connected
**Procedure:** Run `MDCAFULL-Validate.ps1 -Check Connectors`. In `security.microsoft.com` → **Cloud apps → Connected apps → App connectors**, confirm each connector in `MDCA App Connectors – Priority SaaS – Prod` shows **Connected**.
**Pass:** Microsoft 365 (and each priority app) is connected and pulling activity.
**Fail:** A connector shows an error/disconnected — see Troubleshooting *Connector not connecting*.

## A2 — Cloud Discovery flowing
**Procedure:** Run `MDCAFULL-Validate.ps1 -Check Discovery`. In **Cloud apps → Cloud discovery → Dashboard**, confirm discovered apps and traffic appear.
**Pass:** Discovery data (apps, users, traffic) is visible from the configured source.
**Fail:** Dashboard empty — see Troubleshooting *No discovery data*.

## A3 — App governance and OAuth policy active
**Procedure:** Run `MDCAFULL-OAuthRisk.ps1` and `MDCAFULL-Report.ps1 -Section OAuth`. In **Cloud apps → App governance**, confirm OAuth apps are inventoried and `MDCA OAuth App Risk – Tenant – Report` is present and report-only.
**Pass:** App governance is on, OAuth apps are inventoried, and the report policy flags risky apps without revoking.
**Fail:** App governance off or no inventory — see Troubleshooting *App governance not inventorying*.

## A4 — Session/access policy scoped and report-only
**Procedure:** Run `MDCAFULL-Validate.ps1 -Check Policy`. In **Cloud apps → Policies**, confirm `MDCA Session Control – Pilot Users – Report` and `MDCA Access Control – Pilot Users – Report` exist, are **monitor/report-only**, and are scoped to `MDCA Pilot Users – Pilot Ring – Pilot`.
**Pass:** Both policies exist, are report-only, and target only the pilot users.
**Fail:** Policy missing, enforcing, or wrongly scoped — re-create per Implementation Step A5.

## A5 — Conditional Access App Control routes sessions
**Procedure:** As a pilot user, sign in to a targeted app; confirm the session is proxied (the MDCA session banner/URL suffix appears) per the CA policy `MDCA Session Control – Pilot Users – Report`.
**Pass:** The pilot user's session is routed through MDCA (App Control active) without blocking access.
**Fail:** Session not proxied — see Troubleshooting *App Control not proxying*.

## A6 — Cloud-app signal streaming
**Procedure:** Run `MDCAFULL-Validate.ps1 -Check Signal` and the saved query `MDCA Signal Validation – Tenant – Validate`. Confirm `CloudAppEvents` returns recent rows from the connectors/discovery.
**Pass:** `CloudAppEvents` streams recent activity.
**Fail:** Empty — see Troubleshooting *No cloud-app signal*.

## A7 — A monitor policy fires (no enforcement)
**Procedure:** As a pilot user, perform a benign action a monitor policy watches (e.g. a download on an unmanaged device). In **Incidents & alerts**, confirm the expected alert appears — and access is **not** blocked.
**Pass:** The monitor policy generates the alert; the pilot user is not disrupted.
**Fail:** No alert or access was blocked — re-check the policy mode/scope (Implementation Step A5).

## A8 — Enforcement/revoke stays approval-gated
**Procedure:** Run `MDCAFULL-Report.ps1 -Section Policies` and confirm no policy auto-blocks or auto-revokes during the pilot.
**Pass:** All enforcing/revoke actions require approval; nothing auto-executes on the pilot.
**Fail:** An enforcing action is live before agreed — reset to report-only and confirm with the security team.

---

# Part B — Enablement knowledge-check (Phase B)

## B-env — Lab environment checks
- **After Lab 3:** run `MDCAFULL-OAuthRisk.ps1`; confirm it lists OAuth apps with risk hints and the `OAuthRisk-Shortlist – CloudApps – Pilot` was captured.
- **After Lab 4:** in **Cloud apps → Policies**, confirm `MDCA Session Control – Pilot Users – Report` is **Monitor only** (not Block).
- **After Labs 1/3/5:** in **Advanced hunting → Queries**, confirm `Discovery-ShadowIT – CloudApps – Pilot`, `OAuthApps – CloudApps – Pilot`, and `Anomaly-Investigation – CloudApps – Pilot` exist and run without error.

## B-know — Per-attendee knowledge-check
Score each attendee; passing = correct on at least 8 of 10.
1. **CASB basics:** What four questions does a CASB answer, and which MDCA feature answers each?
2. **Cloud Discovery:** What feeds Cloud Discovery, and what drives an app's risk score?
3. **Shadow IT:** What does tagging an app **Unsanctioned** do, and what else is needed to actually block it?
4. **Connectors vs discovery:** How is an **app connector** different from **Cloud Discovery**?
5. **App governance:** Name two risk indicators app governance surfaces on an app.
6. **OAuth risk:** Give two OAuth app risk factors and why each is dangerous *(e.g. broad consent scopes, unverified publisher)*.
7. **Session policy:** Why author a session policy **report-only / monitor** first, and what is the enforce path?
8. **Anomaly detection:** Name three anomaly-detection alert types and one triage question for each.
9. **Hunting:** Which advanced-hunting table holds cloud-app activity, and give a field you'd pivot on. *(CloudAppEvents.)*
10. **Boundary & governance:** Which decisions (app sanctioning, consent revocation, user suspension) require the customer's approval, and who approves them?

## B-capstone — Live demonstration
Each attendee, unaided, on a **second** app/alert: opens Discovered apps and ranks by risk (states one disposition), runs one saved hunting query and interprets a result, and names the fitting response action and the approval required.

**Part B pass:** every attendee meets B-know (≥8/10) and completes B-capstone; the B-env checks pass. Anyone below threshold repeats the relevant lab.

---

# Part C — Proof-of-concept gates (Phase C)

## C1 — Audit policy scoped
**Procedure:** Run `MDCAFULL-PoC.ps1 -Action Enable -WhatIf`; confirm `MDCA PoC Activity Policy – Pilot Users – Audit` is scoped to the pilot group with **no governance action** (audit only).
**Pass:** The policy targets the pilot users only and takes no action. **Fail:** see Troubleshooting *Policy scope or action wrong*.

## C2 — Benign signal generated
**Procedure:** Run `MDCAFULL-PoC.ps1 -Action Signal`; confirm the sample discovery log uploaded and the benign policy-matching activity was performed.
**Pass:** Both benign signals generated; no real exfiltration. **Fail:** see Troubleshooting *Signal not generated*.

## C3 — Discovery report populated
**Procedure:** `Cloud apps → Cloud discovery → Dashboard` shows `MDCA PoC Discovery – Pilot – Report`; `MDCAFULL-Validate.ps1 -Check PoC` confirms discovery data.
**Pass:** The Shadow IT report populated from the sample log with app risk scores. **Fail:** see Troubleshooting *Discovery report empty*.

## C4 — Activity policy matched and alert surfaced
**Procedure:** Confirm the audit policy matched the benign activity and an alert surfaced (`Cloud apps → Alerts` / **Incidents & alerts**); `MDCAFULL-Validate.ps1 -Check PoC` checks `AlertInfo`.
**Pass:** The policy matched in audit mode and an alert was raised (audit still alerts; it just does not govern). **Fail:** see Troubleshooting *Policy did not match* / *No alert surfaced*.

## C5 — Activity-log / hunting visibility
**Procedure:** `Cloud apps → Activity log` shows the benign activity; `MDCAFULL-Validate.ps1 -Check PoC` runs KQL over `CloudAppEvents`.
**Pass:** The activity is visible and hunting returns recent rows. **Fail:** allow warm-up; see Troubleshooting *No activity visibility*.

## C6 — Scorecard produced
**Procedure:** Run `MDCAFULL-PoC.ps1 -Action Score` and confirm `MDCA PoC Scorecard – Pilot Users – Validate.json` is written with a pass/fail per criterion.
**Pass:** A complete scorecard maps every observation to your criteria. **Fail:** re-run the relevant validate step first.

## C7 — Clean teardown
**Procedure:** Run `MDCAFULL-PoC.ps1 -Action Teardown -WhatIf`, then for real; re-run `MDCAFULL-Validate.ps1 -Check PoC`.
**Pass:** The policy, discovery report, and connector are removed and test alerts resolved. **Fail:** see Troubleshooting *Teardown left residue*.

---
### Exit gate
Part A (A1–A8) passes on the pilot **before** you enforce any policy or expand scope. Part B passes to certify the team. Part C (C1–C6) passes to call the PoC conclusive; C7 passes to close it out cleanly. Re-run A1, A2, A6, and A7 after each expansion wave and compare against the saved baseline; keep the scorecard file as the decision record.
