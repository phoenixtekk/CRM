# 7. Best Practices — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

These practices keep shared clinical devices reliable, standardized, and audit-ready over time.
They reinforce the phase model: **Assess → Enroll/Provision → Standardize → Lock-down → Pilot →
Validate → Expand.**

## Model and ownership
- **Keep shared devices owner-less.** Never bind a primary user / user-affinity to a WOW, kiosk, or shared tablet — it ties the device to one person's identity, license, and compliance state. Sweep for stray primary users regularly with **`CLINDEV-Validation.ps1`** / **`CLINDEV-Remediation.ps1`**.
- **Use self-deploying Autopilot for shared provisioning, not user-driven.** There is no user at the cart; the device must come up on its own. Reserve user-driven Autopilot for personally assigned devices in other solutions.
- **Match the lock to the device's purpose.** Single-purpose device (registration kiosk, wayfinding) → **Assigned Access** (single- or multi-app). Multi-app clinical device (WOW, nurse-station PC) → **Shared PC mode**, optionally with a multi-app kiosk — **never** a single-app lock.

## Grouping and targeting
- **Target one group, not loose device lists.** Assign every profile and app to **`Clinical – Shared Devices`** (dynamic, keyed on the Autopilot group tag / enrollment). New devices inherit the full configuration automatically as they self-provision.
- **Keep a permanent pilot group.** `Clinical – Shared Devices – Pilot` should always hold a spare of each device type so changes are validated off the floor before fleet rollout.
- **Use a kiosk sub-group** for single-purpose devices so the Assigned Access profile never lands on a multi-app WOW.

## Provisioning and apps
- **Block device use until provisioning completes** (ESP) so a clinician never picks up a half-built cart missing clinical apps.
- **Deliver the clinical baseline as Required and reportable** — never hand-install apps on individual carts. Name each app exactly as published; for the Epic Hyperdrive client and Imprivata agent, follow the dedicated solutions and reference (don't duplicate) their packaging.
- **Standardize device naming** (`WOW-%SERIAL%`, `KIOSK-%SERIAL%`) so the floor, the report, and the help desk speak the same language.

## Power and reliability on carts
- **Never let a WOW sleep on battery.** Display-off is fine for battery life; sleep/hibernate is not — clinicians must not return to an asleep, slow-to-resume cart mid-round.
- **Size the battery to the shift,** and set a graceful critical-battery action so an ePHI session is not lost abruptly at depletion.
- **Pair power policy to hardware.** Validate the always-on profile on the actual cart model; lid-close and standby behavior differ across tablets and laptops.

## Security and compliance
- **Run all changes through change control** within clinical maintenance windows (see `global-requirements-healthcare-solutions.md`). A clinical-device change is a regulated change.
- **Keep scripts read-only and ePHI-free.** The solution's scripts report device metadata (enrollment, profile, group, primary user, app state) — never ePHI. Default them to `-WhatIf`; require `-Apply` to act.
- **Lock kiosks against escape** and re-test escape paths after Windows feature updates, which can change Assigned Access behavior.
- **Pair with the rest of the clinical-endpoint stack** — compliance policies, BitLocker, Defender, and (if used) Imprivata tap hand-off — so the shared device is both fast *and* secure.

## Operations and lifecycle
- **Report regularly.** Run **`CLINDEV-Report.ps1`** on a schedule for counts by type/profile/compliance, and **`CLINDEV-Validation.ps1`** for per-device drift; remediate stray primary users and missing profiles promptly.
- **Roll out in waves** within maintenance windows; validate each wave before the next.
- **Re-validate after Windows updates,** especially Shared PC mode and Assigned Access behavior, before assuming the lock and the cleanup still hold.
- **Document rollback** for every profile so a misbehaving change can be un-assigned and the device restored quickly.
