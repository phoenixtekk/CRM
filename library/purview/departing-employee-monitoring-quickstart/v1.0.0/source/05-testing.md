# Testing & Validation — Departing-Employee Data-Theft Monitoring Quickstart

Run these gates in order. Each has an explicit **pass/fail** signal. **Do not expand scope** (Phase 7)
until every gate passes **and** HR/legal have confirmed the alert→case→hand-off workflow is acceptable.
Where a test involves a real user's activity, use a **sanctioned test account/action** with HR/legal
awareness — do not covertly test on a real employee.

Use the scripts where noted; they are read-only or `-WhatIf` and change nothing you don't approve.

---

## Gate 1 — Role separation is clean (privacy control)

**Why:** The person who defines risk must not be the person who unmasks identity; both must be
independently audited.
**How:** Run `IRMDEPART-Discovery.ps1`. Review the role-group membership table.
**Pass:** The four functional groups (**Admins / Analysts / Investigators / Auditors**) have minimal,
correct membership; **no single person holds a conflicting combination** (e.g. Admin **and**
Investigator); the combined **Insider Risk Management** role group is **not** assigned to operators.
**Fail:** Any conflicting combination, or over-broad membership → fix in **Roles & scopes** before
continuing.

## Gate 2 — Anonymization is ON

**Why:** Reviewers must see pseudonymized identities by default.
**How:** Purview → **Insider Risk Management → Settings → Privacy**; `IRMDEPART-Discovery.ps1` flags the
posture to confirm in-portal.
**Pass:** **"Show anonymized versions of usernames"** is selected; the reviewer experience shows coded
identifiers, not names.
**Fail:** Anonymization off without a **written** privacy/legal exception → re-enable it.

## Gate 3 — Trigger and indicators are ready

**Why:** The departing-user policy can only score a user once the **trigger** fires, and can only detect
activities whose **indicators** are enabled.
**How:** Run `IRMDEPART-Test-HRConnector.ps1`; cross-check in **Settings → Policy indicators / Data
connectors / Device onboarding**.
**Pass:** Unified audit-log ingestion **on**; the **HR connector** shows a recent successful upload (or
you are deliberately using the Entra-account-deletion trigger); the required **Office and Device
indicator families are enabled**; **device onboarding** shows onboarded devices (for device indicators).
**Fail:** Audit ingestion off, HR connector stale, a needed indicator off, or no devices onboarded → fix
the specific prerequisite (see `02-requirements.md` R4–R6 and `03-implementation.md` Phase 3).

## Gate 4 — The policy is On and healthy, scoped to the pilot

**Why:** A misconfigured or over-scoped policy produces noise or over-collection.
**How:** Purview → **Insider Risk Management → Policies**; `IRMDEPART-Set-Policy.ps1 -WhatIf` to
re-validate prerequisites/plan.
**Pass:** `IRM-DepartingUser-DataTheft` shows **Status = On** and **healthy** (no configuration warning),
scoped to **`SG-Departing-Pilot`** only.
**Fail:** The policy shows a health/configuration warning, or is scoped beyond the pilot → correct before
testing detections.

## Gate 5 — The trigger actually scopes a leaver

**Why:** The whole capability hinges on the leaver signal reaching the policy; prove it before relying on
detections.
**How:** Ensure a **pilot test account** (in `SG-Departing-Pilot`) has a **resignation/termination date**
in the HR-connector upload (or is deleted, if using the account-deletion trigger). Confirm in the portal
that the user is brought **in scope for detection** within the activation window.
**Pass:** The test leaver is scoped for detection after the trigger (leaver date / account deletion).
**Fail:** The user is never scored/in-scope → check the HR upload succeeded and the leaver date is
recent/valid (`IRMDEPART-Test-HRConnector.ps1`), or that the account-deletion trigger is selected.

## Gate 6 — A sanctioned test exfiltration produces a scored alert

**Why:** Proves the end-to-end detection path (trigger → indicator → score → alert) actually works.
**How:** With the Gate-5 **pilot test leaver** on an **onboarded** device, perform a **benign,
sanctioned** exfiltration action within the detection window — e.g. copy a harmless test file to
removable media, or email a test file to an external test address.
**Pass:** The activity appears as **scored activity** and raises an **alert** in the queue with a
severity, within the policy's activation window.
**Fail:** No alert after the detection window → confirm the trigger fired (Gate 5), the indicator is
enabled, and the device is onboarded (Gate 3).

## Gate 7 — Alert triages and escalates into an audited case

**Why:** The operational review flow and the audit trail are the point.
**How:** As an **Analyst**, triage the Gate-6 alert (confirm), then escalate to a **case**. As an
**Auditor**, check the IRM audit log.
**Pass:** The alert can be **confirmed/dismissed** with a note; a confirmed alert becomes a **case**; any
**de-anonymization** in the case is recorded in the **IRM audit log** (visible to Auditors).
**Fail:** Cannot triage/escalate (likely a role issue — Gate 1), or reviewer actions are not audited →
re-check role assignments and settings.

## Gate 8 — HR/legal hand-off confirmed

**Why:** Determinations are theirs, not the administrator's.
**How:** Walk the case workflow with HR/legal; confirm they accept how evidence is routed (notification /
eDiscovery / Communication Compliance / resolve) and who decides outcomes.
**Pass:** HR/legal confirm the hand-off is acceptable and the **determination/outcome sits with them**.
**Fail:** Ambiguity about who decides outcomes → resolve **before** expanding scope.

## Gate 9 — Reporting rollup is coherent

**Why:** Leadership needs a defensible, privacy-respecting summary.
**How:** Run `IRMDEPART-Report.ps1` (read-only) and compare the rollup to the portal Alerts/Cases
dashboards.
**Pass:** The rollup (counts by operation/time over the window) reconciles with the portal, with no
identity exposure beyond what the report is authorized to show.
**Fail:** Rollup diverges materially from the portal → the portal dashboards are authoritative; reconcile
before reporting.

---

### Exit criteria (all must be true before Expand)

- [ ] Role separation clean; no conflicting combinations (Gate 1)
- [ ] Anonymization ON (Gate 2)
- [ ] Trigger + indicators ready; audit ingestion on (Gate 3)
- [ ] Policy On + healthy, pilot-scoped (Gate 4)
- [ ] Trigger scopes a test leaver (Gate 5)
- [ ] Sanctioned test → scored alert (Gate 6)
- [ ] Alert → audited case (Gate 7)
- [ ] HR/legal hand-off confirmed (Gate 8)
- [ ] Reporting reconciles with portal (Gate 9)
