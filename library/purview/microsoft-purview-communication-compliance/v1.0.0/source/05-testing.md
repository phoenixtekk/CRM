# 5. Testing Guide — Microsoft Purview Communication Compliance

Run these after configuring the guardrails (Step 2) and the pilot policy (Steps 4–5), and again after
each tuning change and before expanding. Every test here is **safe and read-only or contained to the
pilot group**; the point is to prove detection, the reviewer workflow, **privacy**, and **role
separation** all work before any broad rollout. Use test communications inside the **pilot** population
only. **Outcomes remain HR/legal's determination — these tests validate the mechanism.**

## Test 1 — Role separation is in place (the core guardrail)
**Do:** Run `PURVCC-Discovery.ps1`; review the `Comms Role Separation – Evidence` snapshot of each role
group's membership.
**Expected:** Policy-builders (Admin) are separated from reviewers (Analysts) and investigators
(Investigators); Viewers are oversight-only. No one is silently both Admin **and** Analyst/Investigator
unless HR/legal explicitly accepted it. **Fail** → correct membership (Implementation Step 2) before
proceeding.

## Test 2 — Privacy controls are in effect
**Do:** In the Purview portal → `Settings → Communication Compliance` confirm the agreed **privacy
option** (pseudonymized usernames if your privacy stakeholders required it). Open an alert as a reviewer.
**Expected:** The review experience reflects the agreed privacy setting (e.g. usernames pseudonymized);
the supervised population matches the approved scope and **excludes** `Comms Excluded – Privacy`.
**Fail** → set the privacy option / fix scope.

## Test 3 — In-scope population is minimized and exclusions hold
**Do:** Run `PURVCC-Discovery.ps1` (or `PURVCC-Report.ps1`) and inspect the policy's supervised
users/groups and exclusions.
**Expected:** Scope equals the approved `Comms In-Scope – Pilot` (not "everyone"); `Comms Excluded –
Privacy` members are not monitored. **Fail** → tighten scope.

## Test 4 — Policy exists and is correctly composed
**Do:** Run `PURVCC-Report.ps1`; review the policy/rule inventory for `Comms Policy – Pilot – Simulation`.
**Expected:** The policy is scoped to the pilot group, has the intended **reviewers**, the chosen
**classifiers / sensitive info types / keywords / conditions**, the expected **channels**, and a
**sampling percentage**. **Fail** → correct via `PURVCC-Configuration.ps1` / `PURVCC-Set-Scope.ps1`.

## Test 5 — A violating message raises an alert (true positive)
**Do:** From a pilot user, send a test communication that should match (e.g. sample offensive-language
or sensitive-info content matching the policy's conditions). Allow processing time.
**Expected:** An **alert** appears for the policy in Communication Compliance → Alerts, visible to the
assigned reviewers. **Fail** → check classifier/condition selection and channel coverage.

## Test 6 — A clean message does NOT alert (false-positive check)
**Do:** From a pilot user, send an ordinary, non-violating message.
**Expected:** No alert is raised. If clean messages alert, the policy is too broad. **Fail** → tune
classifiers/keywords/conditions (Implementation Step 7).

## Test 7 — Reviewer can work an alert end-to-end
**Do:** As an **Analyst** reviewer, open the test alert; examine the flagged message in context; apply a
**remediation action** — tag (compliant/questionable/non-compliant), resolve, notify, or **escalate**.
**Expected:** The reviewer can triage and action the alert; the action is recorded. **Fail** → check
Analysts role membership and reviewer assignment.

## Test 8 — Escalation reaches an Investigator; Viewer sees no content
**Do:** Escalate the test alert to an **Investigator**; separately, sign in as a **Viewer**.
**Expected:** The Investigator receives the escalation with context; the Viewer sees reports/dashboards
but **no message content**. **Fail** → correct Investigator/Viewer role membership.

## Test 9 — Activity and audit trail are captured
**Do:** Run `PURVCC-Report.ps1` for the `Comms Review Rollup – Report`; confirm reviewer actions and
policy configuration are reflected (Communication Compliance activity is recorded in the unified audit
log).
**Expected:** Policy configuration changes and reviewer actions are traceable — the defensible,
auditable trail. **Fail** → confirm auditing is enabled in the tenant.

## Test 10 — Safe automation defaults
**Do:** Run `PURVCC-Configuration.ps1`, `PURVCC-ReviewerWorkflow.ps1`, and `PURVCC-Set-Scope.ps1` with
no action switch.
**Expected:** Each runs in **`-WhatIf`** mode and only *describes* the change; nothing is modified until
`-Commit` is supplied. Discovery and Report scripts are read-only. **Fail** → stop; do not run with
`-Commit` until the dry-run output is correct and HR/legal have signed off.

---
**Gate to expand:** Tests 1–4 (guardrails), 5–6 (accuracy), 7–8 (workflow + separation), and 9–10
(evidence + safety) all pass in the pilot → proceed to broad rollout (Implementation Step 8). Any fail →
tune and re-test. Expansion is an HR/legal-approved decision, not a technical one.
