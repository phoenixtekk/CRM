# 1. Solution Overview — Endpoint PowerShell Deployment & Patch Automation Toolkit

## What this toolkit is
This is a tested set of PowerShell scripts and Intune remediations (also called proactive
remediations) that automate the repetitive endpoint work an engineer otherwise does by hand:
remediating drifted settings, confirming patch state, deploying or removing software, and cleaning
up after failed installs. Instead of one-off manual fixes, you deploy parameterized scripts that run
on a schedule, report what they did, and bring every device to the same known-good state.

Three building blocks work together:
- Intune remediations (proactive remediations) — a paired detection script and remediation script
  that Intune runs on enrolled devices on a schedule. The detection script decides whether a device
  is healthy; only if it is not does Intune run the remediation script.
- Microsoft Graph PowerShell — used from an admin workstation to read fleet state (device inventory,
  remediation results) so you can report across every device.
- Scheduled local scripts — the same tested scripts, runnable on demand or on a schedule, for tasks
  that fit a runner better than a remediation pair (for example a deployment or a cleanup sweep).

## Why this approach (and why it pays off)
Manual endpoint work does not scale and is never consistent. Two admins fix the same problem two
different ways; nobody can prove what was changed; and the next time the problem recurs, the work
starts over. The detect-then-remediate pattern fixes this: you write the desired state once, Intune
checks it everywhere on a schedule, fixes only the devices that have drifted, and records the result.
The work becomes assign-once, repeat-everywhere — every device converges to one definition of
healthy, and you get a fleet-wide record instead of a memory of what you typed last Tuesday.

## How it works — the detect-then-remediate pattern
1. A detection script inspects the device and exits `0` (compliant — nothing to do) or `1`
   (non-compliant — remediation needed). It writes a short status line that Intune captures.
2. When detection exits `1`, Intune runs the paired remediation script, which makes the change and
   exits `0` on success.
3. Intune runs the pair on a schedule (hourly, daily, or once) under the SYSTEM account (or the
   logged-on user, if you choose), so devices are re-checked continuously and self-heal.
4. Results — detection state, remediation state, output, and timing — roll up in Intune under the
   remediation, and can be read fleet-wide with Microsoft Graph.

## What you can automate with it
- Configuration drift — detect a wrong/missing setting (registry value, service state, scheduled
  task) and remediate it back to the standard.
- Patch-state checks — detect devices missing a required update or below a target build and flag or
  trigger a scan.
- Software deployment and removal — run a parameterized deployment/cleanup runner to install,
  repair, or uninstall an app and tidy up leftover files after a failed install.
- Cleanup after failures — remove orphaned folders, stale temp data, or partial installs that block
  the next attempt.

## Safe-by-default design
The remediation script and the deployment/cleanup runner default to `-WhatIf`: on first run they
report exactly what they would change without changing anything. You review the planned actions on a
pilot, then re-run with `-WhatIf:$false` (or the toolkit's `-Apply` switch) to make the change. Every
script writes a clear status line and a non-zero exit code on failure so Intune and your reports
catch problems early.

## How results are reported
- Per device, in Intune, under each remediation: detection/remediation status, output, and run time.
- Fleet-wide, with `PSAUTO-Report.ps1` (Microsoft Graph), which summarizes remediation results across
  every targeted device so you can see how many have converged and chase the laggards.
- Locally, every script prints a readable status line and returns a success/failure exit code.

## Named objects this toolkit creates
Name every object you create with the convention `<Purpose> – <Scope> – <Stage>` and reuse the names
verbatim across Intune, your groups, and your documentation:
- Remediation package (detect/remediate pair): `Endpoint Drift Remediation – Windows – Production`
- Patch-state check remediation: `Patch State Check – Windows – Production`
- Pilot device group: `Endpoint Automation Pilot – Windows – Pilot`
- Production device group: `Endpoint Automation Broad – Windows – Production`
- Remediation schedule: `Endpoint Automation Schedule – Windows – Daily`

## Limitations (be honest with buyers)
- Intune remediations require Intune Plan 1 plus the Remediations entitlement (included in
  Windows Enterprise E3/E5, Education A3/A5, or the Intune add-on) — see the Requirements Guide.
- Remediation scripts run on Windows; they are not a cross-platform configuration manager.
- Each remediation script must finish quickly (Intune enforces a timeout) and run non-interactively
  under SYSTEM by default — design scripts accordingly.
- This toolkit automates tasks you define; it is not a substitute for an application-patching product
  for third-party software at scale.

## The repeatable deployment model
> Stand up the toolkit → deploy a detect/remediate pair as an Intune remediation → schedule it →
> assign to the pilot → validate → expand to production. The repeatable way:
> Assess → Configure → Pilot → Validate → Expand.
