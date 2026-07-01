# 3. Implementation Guide — Endpoint PowerShell Deployment & Patch Automation Toolkit

Follow these steps **in order**, in the Microsoft Intune admin center (`https://intune.microsoft.com`).

> Model: deploy a detect/remediate pair as an Intune remediation, run it on a schedule against a
> small pilot, validate, then expand to the fleet. The pilot is the gate before any production rollout.

Reuse these object names verbatim (convention `<Purpose> – <Scope> – <Stage>`):
- Remediation package: `Endpoint Drift Remediation – Windows – Production`
- Patch-state remediation: `Patch State Check – Windows – Production`
- Pilot group: `Endpoint Automation Pilot – Windows – Pilot`
- Production group: `Endpoint Automation Broad – Windows – Production`
- Schedule: `Endpoint Automation Schedule – Windows – Daily`

## Step 1 — Create the device groups
1. Go to Entra → Groups → New group → Security → name `Endpoint Automation Pilot – Windows – Pilot`
   (a few representative devices). Click `Create`.
2. Create a second group named `Endpoint Automation Broad – Windows – Production` (the rest of the
   fleet). Click `Create`.

## Step 2 — Stand up and review the toolkit locally
1. On your admin workstation, unzip the five scripts to a working folder.
2. Run `PSAUTO-Discovery.ps1` to confirm automation readiness (Graph SDK present, execution policy,
   64-bit host, remediations reachable).
3. Open `PSAUTO-Validation.ps1` (the sample detection script) and `PSAUTO-Remediation.ps1` (the
   paired remediation) and set the desired-state values for your environment at the top of each file.
4. Run `PSAUTO-Remediation.ps1` once — it defaults to `-WhatIf` and prints exactly what it would
   change, changing nothing. Confirm the planned actions look correct.

## Step 3 — Create the detect/remediate remediation
1. In Intune go to Devices → Manage devices → Remediations (Scripts and remediations).
2. Click `Create script package`.
3. Basics: Name `Endpoint Drift Remediation – Windows – Production`; add a short description. Click
   `Next`.
4. Settings:
   - `Detection script file`: upload `PSAUTO-Validation.ps1`.
   - `Remediation script file`: upload `PSAUTO-Remediation.ps1` (set its `-Apply` default, or leave
     `-WhatIf` for a report-only first pass — see Step 6).
   - `Run this script using the logged-on credentials`: `No` (run as SYSTEM).
   - `Enforce script signature check`: `No` (or `Yes` if you signed the scripts — see Requirements 2.5).
   - `Run script in 64-bit PowerShell`: `Yes`.
   Click `Next`.

## Step 4 — Assign and schedule the remediation
1. On the `Assignments` tab, click `Add groups` and add `Endpoint Automation Pilot – Windows – Pilot`.
2. Next to the assigned group set the schedule for `Endpoint Automation Schedule – Windows – Daily`:
   choose `Daily` and a time (or `Hourly` / `Once` to suit the task).
3. Click `Next`, review, and click `Create`.

## Step 5 — Add a patch-state check remediation (optional)
1. Repeat Step 3 with a detection script that flags devices missing a required update or below a
   target build, and a remediation that triggers a Windows Update scan.
2. Name it `Patch State Check – Windows – Production`, assign to the pilot group, and set the same
   daily schedule. Click `Create`.

## Step 6 — Wire deployment / cleanup automation
1. For software deploy/remove and post-failure cleanup, use `PSAUTO-Deploy-CleanupRunner.ps1`.
2. Run it first with its default `-WhatIf` on a pilot device to confirm the planned install/uninstall
   and cleanup actions, then re-run with `-WhatIf:$false` to apply.
3. Optionally point `-LogPath` at your results destination (Requirements 2.6) for a durable record,
   and schedule it as its own remediation pair or local scheduled task.

## Step 7 — Validate on the pilot
1. On a pilot device, force an Intune sync (Settings → Accounts → Access work or school → Info →
   Sync), or wait for the schedule.
2. In Intune open `Endpoint Drift Remediation – Windows – Production` → Device status; confirm pilot
   devices show a detection result and, where they had drifted, a successful remediation.
3. Run `PSAUTO-Report.ps1` to confirm the result fleet-wide. Complete the Testing Guide.

## Step 8 — Expand to production
1. Once the pilot passes the Testing Guide gate, edit the remediation's `Assignments` and add
   `Endpoint Automation Broad – Windows – Production`.
2. Keep the same `Endpoint Automation Schedule – Windows – Daily` schedule.
3. Re-validate each cycle with `PSAUTO-Report.ps1` and chase any devices that have not converged.

---
### Order of operations
`Groups → review toolkit → create detect/remediate → assign + schedule → (patch check) → deploy/cleanup runner → validate (pilot gate) → expand`
