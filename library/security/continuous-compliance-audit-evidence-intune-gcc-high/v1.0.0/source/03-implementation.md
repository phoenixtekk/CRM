# Implementation Guide — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

This guide gives you the **exact, ordered steps** to stand up continuous compliance monitoring and
audit-evidence automation for your CIS/STIG baseline on Intune + Entra **in a GCC High tenant**. Follow
the category deployment model: **Assess → Configure → Pilot → Validate → Expand**, with a pass/fail
gate at each stage. All discovery/measurement is **read-only**; the only changing actions (Remediation,
Set-ScopeTargeting) default to **preview (-WhatIf)**.

**Everything uses the US sovereign-cloud portals** — sign in at **`https://login.microsoftonline.us`**,
administer Intune at **`https://intune.microsoft.us`** and Entra at **`https://entra.microsoft.us`**.
If a portal loads at a `.com` host, **stop — you are in the Commercial cloud.** The scripts connect to
**US Gov Graph** (`graph.microsoft.us`, `-Environment USGov`; DoD/IL5 tenants use
`dod-graph.microsoft.us`, `-Environment USGovDoD`).

**Naming — create and reuse these object names verbatim** (in later steps and in the scripts):

| Object | Name to create and reuse |
| --- | --- |
| Pilot Entra security group | `CCAUDITG-Pilot-Devices` |
| Fleet Entra security group | `CCAUDITG-Fleet-Devices` |
| Baseline reference file | `CCAUDITG-Baseline.json` |
| Evidence exports | `CCAUDITG-Evidence-<timestamp>.csv/json` |
| POA&M exports | `CCAUDITG-POAM-<timestamp>.csv` |

**GCC High parity reminders are inlined at the step where they matter.** Full detail:
`gcc-high-parity-notes.md`. Work through the stages in order. **Do not skip the pilot.**

---

## Stage 0 — Prepare (once)

1. Confirm every item in **02-requirements.md** and **global-requirements-security.md** is satisfied.
2. Install the Microsoft Graph PowerShell SDK on the operator workstation (elevated PowerShell):
   ```
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```
3. Copy the five **CCAUDITG-*.ps1** scripts to a working folder, for example `C:\CCAUDITG\scripts`,
   and create an output folder `C:\CCAUDITG\out` (your local staging → copy finished evidence to the
   controlled, **in-boundary** destination from R3).
4. Sign in once to confirm scopes **against US Gov**:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Discovery.ps1 -OutputPath C:\CCAUDITG\out
   ```
   (The script passes `-Environment USGov` by default; add `-Environment USGovDoD` on a DoD tenant.)
   Consent the read scopes when prompted at **`login.microsoftonline.us`**.
   **Gate 0 (pass):** the script connects to **US Gov Graph** (`Get-MgContext` shows a
   `graph.microsoft.us` host) and writes a discovery file with no permissions error.

   > **Parity caveat:** if the connect lands on `graph.microsoft.com`, you are in the Commercial cloud
   > — re-run with the correct `-Environment` value. This is the single most common GCC High mistake.

---

## Stage 1 — Assess: define the monitored control set (the baseline reference)

You are turning your deployed **GCC High** CIS/STIG baseline into a **machine-readable expected state**
the scripts measure against.

1. **Discover current configuration.** Run control-state discovery to inventory the Intune and Entra
   objects that encode your baseline:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Discovery.ps1 -OutputPath C:\CCAUDITG\out -EmitBaselineTemplate
   ```
   It writes `CCAUDITG-Discovery-<timestamp>.csv/json` listing the discovered configuration profiles,
   compliance policies, Security Baselines, and Entra Conditional Access / authentication-method
   policies with their current settings, plus a `CCAUDITG-Baseline.template.json` to complete.

2. **Select the monitored controls.** From the discovery output, choose the controls that make up your
   monitored set — the CIS/STIG settings you must prove. Record, for each control: a stable **control
   identifier** (use your CIS/STIG reference verbatim — deferred to CIS/DISA), the **Intune or Entra
   object** that carries it, the setting name, and the **expected value**.

   > **Parity caveat:** only monitor controls whose enforcement mechanism **exists in GCC High**. Do
   > **not** add controls that depend on **BIOS/DFCI profiles**, **Windows Autopatch / update rings**,
   > **Device Health Attestation**, or **Remote Help** — these are **planned-not-yet-available** in GCC
   > High (`gcc-high-parity-notes.md` §3). Manage those out-of-band and mark them as such in your POA&M.

3. **Create the baseline reference file.** Save the selected controls as **`CCAUDITG-Baseline.json`**
   in the working folder — this is your expected-state reference. Use the template the Discovery script
   emits so field names match what Validation reads. Store it under change control (R1/G8).

   **Gate 1 (pass):** `CCAUDITG-Baseline.json` exists, each entry has a control ID, target object,
   setting, and expected value, and it is approved by your compliance lead / ISSO.

---

## Stage 2 — Configure: set scope and measurement

1. **Build the pilot target group.** If **`CCAUDITG-Pilot-Devices`** does not exist, create it —
   preview first, then commit:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Set-ScopeTargeting.ps1 -GroupName CCAUDITG-Pilot-Devices -OutputPath C:\CCAUDITG\out
   ```
   Review the previewed membership (default -WhatIf). Re-run with `-Commit` to create/populate it. (The
   script connects to US Gov Graph by default.)

2. **Dry-run measurement against the baseline.** Validate current vs. expected for the pilot group:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Validation.ps1 -BaselinePath .\CCAUDITG-Baseline.json -GroupName CCAUDITG-Pilot-Devices -OutputPath C:\CCAUDITG\out
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
   detection works. Do **not** seed authentication-impacting drift (G8).

3. **Detect the drift.** Re-run Validation. Confirm the seeded change appears as **Drift** for the
   expected control/device, and unchanged controls remain **Pass**.

4. **Export audit evidence + POA&M gaps.** Generate the evidence and gap exports:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Report.ps1 -ValidationPath C:\CCAUDITG\out\CCAUDITG-Validation-<timestamp>.json -OutputPath C:\CCAUDITG\out
   ```
   It writes: `CCAUDITG-Evidence-<timestamp>.csv/json` (dated per-control per-device evidence with
   tenant, operator, expected, observed, verdict) and `CCAUDITG-POAM-<timestamp>.csv` (one row per
   failing control with device count, severity, and empty milestone/owner columns to complete).

   > **Parity caveat:** the Intune **ServiceNow connector is not available** in GCC High
   > (`gcc-high-parity-notes.md` §2). Import `CCAUDITG-POAM-<timestamp>.csv` into your GRC/ITSM (or your
   > FedRAMP POA&M workbook) **manually** — the CSV is shaped for that. Likewise, build any dashboard on
   > **Log Analytics**, not the (unavailable) Intune Power BI/DWH connector.

5. **Remediate the seeded drift (preview then commit).** Preview the fix, then commit:
   ```
   powershell -ExecutionPolicy Bypass -File .\CCAUDITG-Remediation.ps1 -ValidationPath C:\CCAUDITG\out\CCAUDITG-Validation-<timestamp>.json -OutputPath C:\CCAUDITG\out
   ```
   Default is -WhatIf (preview). Review the planned re-application of baseline targeting for the drifted
   control, then re-run with `-Commit`. Re-run Validation to confirm the control returns to **Pass**.

   **Gate 3 (pass):** the seeded drift was detected, evidence exported with correct fields, POA&M row
   generated, and remediation returned the control to Pass on re-measure. Copy the evidence to the
   controlled, in-boundary destination (R3).

---

## Stage 4 — Validate: confirm outputs meet audit / ATO requirements

1. Have your compliance lead / ISSO review a sample evidence export and confirm the fields, format, and
   retention match your **FedRAMP High / DoD IL** audit expectations (R4).
2. Confirm the POA&M export maps cleanly into your organization's POA&M template / FedRAMP POA&M
   workbook (control ID, weakness description, affected devices, severity, milestones, owner). Confirm
   the remediation-timeline columns align to your obligations (commonly 30/90/180 days for
   High/Moderate/Low — **verify against your ATO**, `gcc-high-parity-notes.md` §5).
3. Confirm evidence lands in the controlled, in-boundary destination and is retained per policy.

   **Gate 4 (pass):** audit lead / ISSO accepts the evidence and POA&M formats; retention and cadence
   confirmed.

---

## Stage 5 — Expand: fleet-wide and scheduled

1. **Broaden scope.** Point Validation/Report at your full in-scope set (a fleet group such as
   **`CCAUDITG-Fleet-Devices`**, built with Set-ScopeTargeting) instead of the pilot group.
2. **Schedule the cycle.** Create a scheduled task on the operator workstation (or a managed runbook
   host **inside your Gov boundary**) that runs, on your continuous-monitoring cadence (for example
   **monthly** for FedRAMP High, or weekly): Discovery → Validation → Report, writing to staging and
   copying evidence to the controlled destination.

   > **Parity caveat:** run the schedule on a host inside your authorization boundary that reaches
   > **US Gov endpoints** (`graph.microsoft.us`, `login.microsoftonline.us`). The scheduled account must
   > have consented the **US Gov** scopes interactively once.

3. **Route drift.** Treat each new **Drift** / **Missing** / **Non-conformant** row as an event: open a
   POA&M item, remediate under change control (Remediation preview → commit), and re-measure to close.
4. **Re-baseline on approved change.** When your CIS/STIG baseline legitimately changes (approved),
   re-run Discovery, update `CCAUDITG-Baseline.json`, and re-approve it — so expected state stays
   accurate.

   **Gate 5 (pass):** the scheduled cycle runs unattended, evidence accumulates in the controlled
   destination on cadence, and drift is tracked to closure via POA&M.

---

## Script summary (order of use)

| Order | Script | Purpose | Changes anything? |
|---|---|---|---|
| 1 | `CCAUDITG-Discovery.ps1` | Inventory control state (US Gov Graph); emit baseline template | No (read-only) |
| 2 | `CCAUDITG-Set-ScopeTargeting.ps1` | Build pilot/fleet target groups | Preview by default (-WhatIf) |
| 3 | `CCAUDITG-Validation.ps1` | Per-device baseline conformance (drift verdicts) | No (read-only) |
| 4 | `CCAUDITG-Report.ps1` | Audit evidence + POA&M-ready gap export | No (read-only) |
| 5 | `CCAUDITG-Remediation.ps1` | Safe fix of drifted settings | Preview by default (-WhatIf) |

All scripts default to **`-Environment USGov`**; pass **`-Environment USGovDoD`** on a DoD/IL5 tenant.

Proceed to **05-testing.md** for the formal pass/fail gates and **06-troubleshooting.md** if a step
does not behave as described.
