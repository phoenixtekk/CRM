# Testing — Continuous Compliance Monitoring & Audit-Evidence Automation

Use these **pass/fail gates** to prove the solution works before you rely on it for an audit. The
three core outcomes you must demonstrate are: **a control is measured**, **drift is detected**, and
**evidence is exported**. Run the gates on the pilot group (**`CCAUDIT-Pilot-Devices`**) first, then
confirm the fleet cadence.

Record the result of each gate (Pass / Fail), the date, and the operator. Do not expand to the fleet
until Gates T1–T6 pass.

---

## T1 — Connectivity & scope (read-only)

**Test:** Run `CCAUDIT-Discovery.ps1 -OutputPath C:\CCAUDIT\out`.
**Pass:** Script connects to Microsoft Graph with the read scopes, completes without a permissions
error, and writes `CCAUDIT-Discovery-<timestamp>.csv/json` containing your baseline's Intune profiles,
compliance policies, Security Baselines, and Entra Conditional Access / auth-method policies.
**Fail:** Permissions error, empty output, or missing baseline objects → see R2 and Troubleshooting.

---

## T2 — Baseline reference is complete

**Test:** Open `CCAUDIT-Baseline.json`.
**Pass:** Every monitored control has a stable **control ID**, a **target object** (Intune/Entra),
the **setting name**, and an **expected value**; the file is approved under change control.
**Fail:** Any control missing an expected value or target object → re-run Discovery with
`-EmitBaselineTemplate` and complete the entry.

---

## T3 — Control measured (current vs. baseline)

**Test:** Run `CCAUDIT-Validation.ps1 -BaselinePath .\CCAUDIT-Baseline.json -GroupName CCAUDIT-Pilot-Devices -OutputPath C:\CCAUDIT\out`.
**Pass:** Every monitored control is measured for **every** pilot device — each row has a verdict of
**Pass / Drift / Missing / Non-conformant** and an observed value. No "not measured" rows.
**Fail:** Controls or devices missing from the output, or verdicts blank → check group membership,
scope tags, and Graph read scopes (R2, R5, Troubleshooting).

---

## T4 — Drift detected

**Test:** In a change window, deliberately change one non-critical monitored setting on one pilot
device or pilot-scoped policy (record it). Re-run `CCAUDIT-Validation.ps1`.
**Pass:** The changed control shows **Drift** for the expected device with the new observed value; all
untouched controls remain **Pass**. Detection is specific (only the seeded control flips).
**Fail:** The change is not detected, or unrelated controls flip → verify you edited a *monitored*
control and that Validation reads the same object; see Troubleshooting.

---

## T5 — Evidence exported (audit-ready)

**Test:** Run `CCAUDIT-Report.ps1 -ValidationPath <latest validation json> -OutputPath C:\CCAUDIT\out`.
**Pass:** `CCAUDIT-Evidence-<timestamp>.csv/json` is written and each record contains **collection
timestamp, tenant, operator identity, control ID, target object, expected value, observed value, and
verdict**. `CCAUDIT-POAM-<timestamp>.csv` is written with **one row per failing control** including
device count, severity, and empty **milestone/owner** columns. Files copy successfully to the
controlled destination (R3).
**Fail:** Missing fields, no POA&M rows for known failures, or destination write fails → check R3/R4
and Troubleshooting.

---

## T6 — Remediation closes the gap (preview → commit → re-measure)

**Test:** Run `CCAUDIT-Remediation.ps1 -ValidationPath <latest validation json>` (default -WhatIf) and
review the preview; re-run with `-Commit`; then re-run `CCAUDIT-Validation.ps1`.
**Pass:** Preview lists the exact drifted control to be re-applied and changes nothing; after
`-Commit`, re-measurement shows the control back to **Pass**; the evidence trail records the fix.
**Fail:** Preview changes state, commit does not close the gap, or re-measure still shows Drift → do
not use Remediation on the fleet; investigate per Troubleshooting.

---

## T7 — Scheduled fleet cadence

**Test:** After Gates T1–T6 pass, point Validation/Report at the fleet group
(**`CCAUDIT-Fleet-Devices`**) and run the scheduled Discovery → Validation → Report cycle once
unattended.
**Pass:** The cycle completes on schedule, evidence lands in the controlled destination, and any drift
appears as POA&M rows.
**Fail:** Task does not run unattended, or evidence does not accumulate → check the scheduled-task
account's Graph consent and destination permissions.

---

**Overall pass criteria:** T1–T6 pass on the pilot and T7 passes on the fleet. Only then treat the
solution as production audit evidence.
