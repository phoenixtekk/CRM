# Testing & Validation — Microsoft Purview Insider Risk Management

Run these gates in order. Each has an explicit **pass/fail** signal. **Do not expand scope** (Phase 7)
until every gate passes **and** HR/legal have confirmed the alert→case→hand-off workflow is acceptable.
Where a test involves a real user's activity, use a **sanctioned test account/action** with HR/legal
awareness — do not covertly test on a real employee.

Use the scripts where noted; they are read-only or `-WhatIf` and change nothing you don't approve.

---

## Gate 1 — Role separation is clean (privacy control)

**Why:** The person who defines risk must not be the person who unmasks identity; both must be
independently audited.
**How:** Run `PURVIRM-Discovery.ps1`. Review the role-group membership table.
**Pass:** The four functional groups (**Admins / Analysts / Investigators / Auditors**) have minimal,
correct membership; **no single person holds a conflicting combination** (e.g. Admin **and**
Investigator); the combined **Insider Risk Management** role group is **not** assigned to operators.
**Fail:** Any conflicting combination, or over-broad membership → fix in **Roles & scopes** before
continuing.

## Gate 2 — Anonymization is ON

**Why:** Reviewers must see pseudonymized identities by default.
**How:** Purview → **Insider Risk Management → Settings → Privacy**; `PURVIRM-Discovery.ps1` flags the
posture to confirm in-portal.
**Pass:** **"Show anonymized versions of usernames"** is selected; the analyst experience shows coded
identifiers, not names.
**Fail:** Anonymization off without a **written** privacy/legal exception → re-enable it.

## Gate 3 — Indicators, connectors, and integrations are ready

**Why:** A policy can only detect what its indicators/triggers can see.
**How:** Run `PURVIRM-Test-Readiness.ps1`; cross-check in **Settings → Policy indicators / Data
connectors / Device onboarding**.
**Pass:** The required **indicator families are enabled**; **device onboarding** shows onboarded
devices (for device indicators); the **HR connector** shows a recent successful upload (or you are
deliberately using the Entra-account-deletion trigger); **Defender for Endpoint** is connected (for
security-policy violations).
**Fail:** A needed indicator is off, no devices onboarded, HR connector stale, or MDE not connected →
fix the specific prerequisite (see `02-requirements.md` R4–R6 and `03-implementation.md` Phase 3).

## Gate 4 — Each policy is On and healthy, scoped to the pilot

**Why:** Misconfigured or over-scoped policies produce noise or over-collection.
**How:** Purview → **Insider Risk Management → Policies**; `PURVIRM-Set-PolicyFromTemplate.ps1 -WhatIf`
to re-validate prerequisites/plan.
**Pass:** `IRM-DepartingUser-DataTheft`, `IRM-DataLeaks-General`, and `IRM-SecurityPolicyViolations`
each show **Status = On** and **healthy** (no configuration warning), scoped to **`SG-IRM-Pilot`** only.
**Fail:** Any policy shows a health/configuration warning, or is scoped beyond the pilot → correct
before testing detections.

## Gate 5 — Analytics reviewed before reliance

**Why:** Analytics sizes the program and tunes expectations **without** naming individuals.
**How:** **Insider Risk Management → Analytics** → run scan; review with HR/legal.
**Pass:** Analytics scan completed and the report reviewed with HR/legal.
**Fail:** No analytics run before scoping → run it first.

## Gate 6 — A sanctioned test activity produces a scored alert

**Why:** Proves the end-to-end detection path (trigger → indicator → score → alert) actually works.
**How:** With a **pilot test account** that is **in scope** and (for the departing-user policy) marked
as a leaver in the HR feed, perform a **benign, sanctioned** exfiltration action on an **onboarded**
device — e.g. copy a harmless test file to removable media, or email a test file to an external test
address — within the detection window.
**Pass:** The activity appears as **scored activity** and raises an **alert** in the queue with a
severity, within the policy's activation window.
**Fail:** No alert after the detection window → check the trigger fired (leaver date / DLP match / MDE
alert), the indicator is enabled, and the device is onboarded (Gate 3).

## Gate 7 — Alert triages and escalates into an audited case

**Why:** The operational workflow and the audit trail are the point.
**How:** As an **Analyst**, triage the Gate-6 alert (confirm), then escalate to a **case**. As an
**Auditor**, check the IRM audit log.
**Pass:** The alert can be **confirmed/dismissed** with a note; a confirmed alert becomes a **case**;
any **de-anonymization** in the case is recorded in the **IRM audit log** (visible to Auditors).
**Fail:** Cannot triage/escalate (likely a role issue — Gate 1), or reviewer actions are not audited →
re-check role assignments and settings.

## Gate 8 — HR/legal hand-off confirmed

**Why:** Determinations are theirs, not the administrator's.
**How:** Walk the case workflow with HR/legal; confirm they accept how evidence is routed
(notification / eDiscovery / Communication Compliance / resolve) and who decides outcomes.
**Pass:** HR/legal confirm the hand-off is acceptable and the **determination/outcome sits with them**.
**Fail:** Ambiguity about who decides outcomes → resolve **before** expanding scope.

## Gate 9 — Reporting rollup is coherent

**Why:** Leadership needs a defensible, privacy-respecting summary.
**How:** Run `PURVIRM-Report.ps1` (read-only) and compare the rollup to the portal Alerts/Cases
dashboards.
**Pass:** The rollup (counts by severity/status over the window) reconciles with the portal, with no
identity exposure beyond what the report is authorized to show.
**Fail:** Rollup diverges materially from the portal → the portal dashboards are authoritative;
reconcile before reporting.

---

### Exit criteria (all must be true before Expand)

- [ ] Role separation clean; no conflicting combinations (Gate 1)
- [ ] Anonymization ON (Gate 2)
- [ ] Indicators/connectors/MDE ready (Gate 3)
- [ ] Three policies On + healthy, pilot-scoped (Gate 4)
- [ ] Analytics reviewed (Gate 5)
- [ ] Sanctioned test → scored alert (Gate 6)
- [ ] Alert → audited case (Gate 7)
- [ ] HR/legal hand-off confirmed (Gate 8)
- [ ] Reporting reconciles with portal (Gate 9)
