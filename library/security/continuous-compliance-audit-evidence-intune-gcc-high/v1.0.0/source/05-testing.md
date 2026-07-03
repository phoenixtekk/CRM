# Testing — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

Use these **pass/fail gates** to prove the solution works before you rely on it for a Gov audit. The
three core outcomes you must demonstrate are: **a control is measured**, **drift is detected**, and
**evidence is exported** — all against the **US sovereign cloud**. Run the gates on the pilot group
(**`CCAUDITG-Pilot-Devices`**) first, then confirm the fleet cadence.

Record the result of each gate (Pass / Fail), the date, and the operator. Do not expand to the fleet
until Gates T1–T6 pass.

---

## T0 — Correct cloud (GCC High / DoD)

**Test:** Run `CCAUDITG-Discovery.ps1 -OutputPath C:\CCAUDITG\out` and then `Get-MgContext`.
**Pass:** The connection is against **US Gov** — the Graph host is `graph.microsoft.us` (GCC High) or
`dod-graph.microsoft.us` (DoD), and sign-in was at `login.microsoftonline.us`.
**Fail:** The context shows `graph.microsoft.com` (Commercial) → re-run with the correct
`-Environment USGov` / `-Environment USGovDoD`; you were querying the wrong cloud.

---

## T1 — Connectivity & scope (read-only)

**Test:** Run `CCAUDITG-Discovery.ps1 -OutputPath C:\CCAUDITG\out`.
**Pass:** Script connects to US Gov Graph with the read scopes, completes without a permissions error,
and writes `CCAUDITG-Discovery-<timestamp>.csv/json` containing your baseline's Intune profiles,
compliance policies, Security Baselines, and Entra Conditional Access / auth-method policies.
**Fail:** Permissions error, empty output, or missing baseline objects → see R2 and Troubleshooting.

---

## T2 — Baseline reference is complete

**Test:** Open `CCAUDITG-Baseline.json`.
**Pass:** Every monitored control has a stable **control ID**, a **target object** (Intune/Entra), the
**setting name**, and an **expected value**; the file is approved under change control. No control
depends on a mechanism that is **unavailable in GCC High** (BIOS/DFCI, update rings, DHA — see
`gcc-high-parity-notes.md` §3).
**Fail:** Any control missing an expected value or target object, or a control tied to an unavailable
GCC High mechanism → re-run Discovery with `-EmitBaselineTemplate`, complete the entry, or move the
out-of-band control to your manual POA&M.

---

## T3 — Control measured (current vs. baseline)

**Test:** Run `CCAUDITG-Validation.ps1 -BaselinePath .\CCAUDITG-Baseline.json -GroupName CCAUDITG-Pilot-Devices -OutputPath C:\CCAUDITG\out`.
**Pass:** Every monitored control is measured for **every** pilot device — each row has a verdict of
**Pass / Drift / Missing / Non-conformant** and an observed value. No "not measured" rows.
**Fail:** Controls or devices missing from the output, or verdicts blank → check group membership,
scope tags, and Graph read scopes (R2, R5, Troubleshooting).

---

## T4 — Drift detected

**Test:** In a change window, deliberately change one non-critical monitored setting on one pilot
device or pilot-scoped policy (record it). Re-run `CCAUDITG-Validation.ps1`.
**Pass:** The changed control shows **Drift** for the expected device with the new observed value; all
untouched controls remain **Pass**. Detection is specific (only the seeded control flips).
**Fail:** The change is not detected, or unrelated controls flip → verify you edited a *monitored*
control and that Validation reads the same object; see Troubleshooting.

---

## T5 — Evidence exported (audit-ready)

**Test:** Run `CCAUDITG-Report.ps1 -ValidationPath <latest validation json> -OutputPath C:\CCAUDITG\out`.
**Pass:** `CCAUDITG-Evidence-<timestamp>.csv/json` is written and each record contains **collection
timestamp, tenant, operator identity, control ID, target object, expected value, observed value, and
verdict**. `CCAUDITG-POAM-<timestamp>.csv` is written with **one row per failing control** including
device count, severity, and empty **milestone/owner** columns. Files copy successfully to the
controlled, in-boundary destination (R3).
**Fail:** Missing fields, no POA&M rows for known failures, or destination write fails → check R3/R4
and Troubleshooting.

---

## T6 — Remediation closes the gap (preview → commit → re-measure)

**Test:** Run `CCAUDITG-Remediation.ps1 -ValidationPath <latest validation json>` (default -WhatIf) and
review the preview; re-run with `-Commit`; then re-run `CCAUDITG-Validation.ps1`.
**Pass:** Preview lists the exact drifted control to be re-applied and changes nothing; after
`-Commit`, re-measurement shows the control back to **Pass**; the evidence trail records the fix.
**Fail:** Preview changes state, commit does not close the gap, or re-measure still shows Drift → do not
use Remediation on the fleet; investigate per Troubleshooting.

---

## T7 — Scheduled fleet cadence (in-boundary)

**Test:** After Gates T1–T6 pass, point Validation/Report at the fleet group
(**`CCAUDITG-Fleet-Devices`**) and run the scheduled Discovery → Validation → Report cycle once
unattended on a host inside your Gov boundary.
**Pass:** The cycle completes on schedule at your continuous-monitoring cadence (for example monthly),
connects to **US Gov Graph** unattended, evidence lands in the controlled destination, and any drift
appears as POA&M rows.
**Fail:** Task does not run unattended, connects to the wrong cloud, or evidence does not accumulate →
check the scheduled-task account's **US Gov** Graph consent and destination permissions.

---

**Overall pass criteria:** T0–T6 pass on the pilot and T7 passes on the fleet. Only then treat the
solution as production audit evidence for your GCC High / DoD authorization.
