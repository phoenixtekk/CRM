# Implementation Guide — Continuous Compliance Monitoring & Audit-Evidence Automation

This guide gives you the **exact, ordered steps** to stand up continuous compliance monitoring and
audit-evidence automation for your CIS/STIG baseline on Intune + Entra. Follow the category
deployment model: **Assess → Configure → Pilot → Validate → Expand**, with a pass/fail gate at each
stage. All discovery/measurement is **read-only**; the only changing actions (Remediation,
Set-ScopeTargeting) default to **preview (-WhatIf)**.

Work through the stages in order. Do not skip the pilot.

---

## Stage 0 — Prepare (once)

1. Confirm every item in **02-requirements.md** and **global-requirements-security.md** is satisfied.
2. Install the Microsoft Graph PowerShell SDK on the operator workstation (elevated PowerShell):
   ```
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```
3. Copy the five **CCAUDIT-*.ps1** scripts to a working folder, for example
   `C:\CCAUDIT\scripts`, and create an output folder `C:\CCAUDIT\out` (your local staging → copy
   finished evidence to the controlled destination from R3).
4. Sign in once to confirm scopes:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Discovery.ps1 -OutputPath C:\CCAUDIT\out
   ```
   Consent the read scopes when prompted. **Gate 0 (pass):** the script connects and writes a
   discovery file with no permissions error.

---

## Stage 1 — Assess: define the monitored control set (the baseline reference)

You are turning your deployed CIS/STIG baseline into a **machine-readable expected state** the scripts
measure against.

1. **Discover current configuration.** Run control-state discovery to inventory the Intune and Entra
   objects that encode your baseline:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Discovery.ps1 -OutputPath C:\CCAUDIT\out
   ```
   It writes `CCAUDIT-Discovery-<timestamp>.csv/json` listing the discovered configuration profiles,
   compliance policies, Security Baselines, and Entra Conditional Access / authentication-method
   policies with their current settings.

2. **Select the monitored controls.** From the discovery output, choose the controls that make up
   your monitored set — the CIS/STIG settings you must prove. Record, for each control: a stable
   **control identifier** (use your CIS/STIG reference verbatim — deferred to CIS/DISA), the **Intune
   or Entra object** that carries it, the setting name, and the **expected value**.

3. **Create the baseline reference file.** Save the selected controls as
   **`CCAUDIT-Baseline.json`** in the working folder — this is your expected-state reference. Use the
   template the Discovery script emits (`-EmitBaselineTemplate`) so field names match what Validation
   reads. Store it under change control (R1/G8).

   **Gate 1 (pass):** `CCAUDIT-Baseline.json` exists, each entry has a control ID, target object,
   setting, and expected value, and it is approved by your compliance lead.

---

## Stage 2 — Configure: set scope and measurement

1. **Build the pilot target group.** If **`CCAUDIT-Pilot-Devices`** does not exist, create it —
   preview first, then commit:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Set-ScopeTargeting.ps1 -GroupName CCAUDIT-Pilot-Devices -OutputPath C:\CCAUDIT\out
   ```
   Review the previewed membership (default -WhatIf). Re-run with `-Commit` to create/populate it.

2. **Dry-run measurement against the baseline.** Validate current vs. expected for the pilot group:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Validation.ps1 -BaselinePath .\CCAUDIT-Baseline.json -GroupName CCAUDIT-Pilot-Devices -OutputPath C:\CCAUDIT\out
   ```
   It writes a per-device, per-control conformance file with verdicts (Pass / Drift / Missing /
   Non-conformant).

   **Gate 2 (pass):** every monitored control is measured for every pilot device (no "not measured"
   rows caused by scope or scope-tag gaps).

---

## Stage 3 — Pilot: measure, detect drift, export evidence

1. **Baseline measurement.** Run Validation against the pilot (as above) and keep the output as the
   pilot **baseline measurement**.

2. **Seed a controlled drift (test).** In a change window, deliberately change one non-critical
   monitored setting on one pilot device / one pilot-scoped policy (record the change). This proves
   detection works. Do **not** seed authentication-impacting drift.

3. **Detect the drift.** Re-run Validation. Confirm the seeded change appears as **Drift** for the
   expected control/device, and unchanged controls remain **Pass**.

4. **Export audit evidence + POA&M gaps.** Generate the evidence and gap exports:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Report.ps1 -ValidationPath C:\CCAUDIT\out\CCAUDIT-Validation-<timestamp>.json -OutputPath C:\CCAUDIT\out
   ```
   It writes: `CCAUDIT-Evidence-<timestamp>.csv/json` (dated per-control per-device evidence with
   tenant, operator, expected, observed, verdict) and `CCAUDIT-POAM-<timestamp>.csv` (one row per
   failing control with device count, severity, and empty milestone/owner columns to complete).

5. **Remediate the seeded drift (preview then commit).** Preview the fix, then commit:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDIT-Remediation.ps1 -ValidationPath C:\CCAUDIT\out\CCAUDIT-Validation-<timestamp>.json -OutputPath C:\CCAUDIT\out
   ```
   Default is -WhatIf (preview). Review the planned re-application of baseline targeting for the
   drifted control, then re-run with `-Commit`. Re-run Validation to confirm the control returns to
   **Pass**.

   **Gate 3 (pass):** the seeded drift was detected, evidence exported with correct fields, POA&M row
   generated, and remediation returned the control to Pass on re-measure. Copy the evidence to the
   controlled destination (R3).

---

## Stage 4 — Validate: confirm outputs meet audit requirements

1. Have your compliance/audit lead review a sample evidence export and confirm the fields, format, and
   retention match audit expectations (R4).
2. Confirm the POA&M export maps cleanly into your organization's POA&M template (control ID, weakness
   description, affected devices, severity, milestones, owner).
3. Confirm evidence lands in the controlled destination and is retained per policy.

   **Gate 4 (pass):** audit lead accepts the evidence and POA&M formats; retention confirmed.

---

## Stage 5 — Expand: fleet-wide and scheduled

1. **Broaden scope.** Point Validation/Report at your full in-scope set (a fleet group such as
   **`CCAUDIT-Fleet-Devices`**, built with Set-ScopeTargeting) instead of the pilot group.
2. **Schedule the cycle.** Create a scheduled task on the operator workstation (or a managed runbook
   host) that runs, on your chosen cadence (for example weekly):
   Discovery → Validation → Report, writing to staging and copying evidence to the controlled
   destination.
3. **Route drift.** Treat each new **Drift** / **Missing** / **Non-conformant** row as an event:
   open a POA&M item, remediate under change control (Remediation preview → commit), and re-measure to
   close.
4. **Re-baseline on approved change.** When your CIS/STIG baseline legitimately changes (approved),
   re-run Discovery, update `CCAUDIT-Baseline.json`, and re-approve it — so expected state stays
   accurate.

   **Gate 5 (pass):** the scheduled cycle runs unattended, evidence accumulates in the controlled
   destination on cadence, and drift is tracked to closure via POA&M.

---

## Script summary (order of use)

| Order | Script | Purpose | Changes anything? |
|---|---|---|---|
| 1 | `CCAUDIT-Discovery.ps1` | Inventory control state; emit baseline template | No (read-only) |
| 2 | `CCAUDIT-Set-ScopeTargeting.ps1` | Build pilot/fleet target groups | Preview by default (-WhatIf) |
| 3 | `CCAUDIT-Validation.ps1` | Per-device baseline conformance (drift verdicts) | No (read-only) |
| 4 | `CCAUDIT-Report.ps1` | Audit evidence + POA&M-ready gap export | No (read-only) |
| 5 | `CCAUDIT-Remediation.ps1` | Safe fix of drifted settings | Preview by default (-WhatIf) |

Proceed to **05-testing.md** for the formal pass/fail gates and **06-troubleshooting.md** if a step
does not behave as described.
