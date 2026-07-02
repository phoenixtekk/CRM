# Best Practices

These practices keep peripheral, driver, and device-control management safe, reversible, and low-noise as you run it over time.

## Staged driver rollout

- **Always pilot first.** Approve drivers only to `PERIDEV-DriverUpdates-Pilot` (manual approval), let them **soak** for a defined period (for example, 3–7 days) on `SG-PERIDEV-Pilot`, then approve to production via `PERIDEV-DriverUpdates-Prod`.
- **Manual approval for pilot, deferred-automatic for production.** Use **Manually approve and deploy** on the pilot so you review every driver. For production, once a source is trusted, **Automatically approve all** with a **deferral** (e.g., 7 days) reduces toil while keeping a safety gap.
- **One change at a time in the pilot.** Don't approve a batch of drivers and change USB policy in the same window — if something breaks, you want to know which change caused it.
- **Prefer Windows Update drivers over vendor packages.** They are staged, revertible, and reported in Intune. Package a vendor driver only when Windows Update does not carry it.
- **Watch device counts.** In the driver-review list, a driver needed by only a few devices is lower risk to approve first; a driver touching the whole fleet deserves a longer pilot soak.
- **Know the rollback.** To roll back a driver, unassign/withdraw the approval and, if needed, roll back the driver on the device (Device Manager → **Roll Back Driver**). To roll back a policy, remove the group assignment and force sync (`PERIDEV-Remediation.ps1`).

## Device control (USB / removable) exceptions

- **Audit before you enforce.** Every device-control policy should ship to the pilot in **Audit** first. Read the audit events, confirm you understand real usage, then switch to **Deny**.
- **Enforce broadly, allow narrowly.** The clean pattern is: **Deny** removable storage for everyone, then **allow** an explicit exception for `SG-PERIDEV-USB-Exception` (approved, ideally encrypted, drives). Keep the exception group small and reviewed.
- **Prefer "Deny write" over "Deny all" when the goal is data-loss prevention.** Blocking writes stops exfiltration while still letting users read from vendor/media USB devices, which cuts help-desk noise.
- **Document every exception.** For each member of `SG-PERIDEV-USB-Exception`, record who approved it, why, and a review date. Exceptions are the part of device control that drifts.
- **Keep Defender healthy.** Device control only enforces while Defender Antivirus is active (requirement R5). Include Defender health in your coverage checks so a disabled AV doesn't silently drop enforcement.

## Peripherals and printers

- **Explicit-allow beats implicit-block for peripheral installation.** Maintain a known list of approved peripheral setup classes/IDs in `PERIDEV-Peripherals-DeviceInstall`; a locked-down "block everything not listed" baseline should only follow a clean audit.
- **Prefer Universal Print** for new printer deployments — no print server to maintain, and it maps cleanly through `PERIDEV-Printers-Pilot`. Keep queue packages only where a legacy queue must remain.
- **Name printers consistently** so users and the validation script can recognize the expected mapping.

## Operating the solution

- **Keep the naming convention verbatim.** `SG-PERIDEV-*`, `PERIDEV-DriverUpdates-*`, `PERIDEV-Printers-*`, `PERIDEV-DeviceControl-USB-*`, `PERIDEV-Peripherals-DeviceInstall`. The scripts and every guide assume these exact names; renaming breaks reporting and remediation.
- **Keep the pilot ahead of production, permanently.** Every future driver, printer, or USB change goes to the pilot first — not just the initial rollout.
- **Run the read-only scripts on a schedule.** `PERIDEV-Discovery.ps1` and `PERIDEV-Report.ps1` are safe to run regularly to catch drift (a device that fell out of coverage, a disabled Defender, an unexpected new removable-storage policy).
- **Default to `-WhatIf` for anything that changes state.** `PERIDEV-Remediation.ps1` and `PERIDEV-Set-ScopeTargeting.ps1` default to `-WhatIf`; review the planned actions before re-running to apply.
- **Communicate user-visible changes.** Drivers and USB blocking are noticed. A short heads-up to the pilot and a known way to report issues keeps confidence high.
