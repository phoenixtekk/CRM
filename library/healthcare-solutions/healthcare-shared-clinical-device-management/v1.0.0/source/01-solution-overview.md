# 1. Solution Overview — Healthcare Shared Clinical Device Management — WOWs, Kiosks & Tablets in Microsoft Intune

## What this solution is
Clinical floors run on **shared Windows devices that no single person owns**: **WOWs**
(workstations-on-wheels rolled bed-to-bed), **kiosks** at registration and check-in,
**nurse-station PCs** used by every clinician on shift, and **clinical tablets** passed hand to
hand. This solution provisions, standardizes, and locks those devices down with **Microsoft
Intune** so any authorized clinician can walk up, sign in fast, find the same clinical apps every
time, and the device stays awake on a cart battery through a 12-hour shift.

The model is deliberately **shared and owner-less**. Devices provision **unattended** with an
**Autopilot self-deploying** profile (no user present at first boot), run in **Windows Shared PC
mode** (the SharedPC CSP, surfaced in Intune as the *Shared multi-user device* settings) so many
shift users cycle through cleanly, and — where a device has a single purpose — are hard-locked
with **Assigned Access** kiosk mode. A standardized **clinical app baseline** is delivered as
**Required** so the same software is present on every device of a given type.

## How it works
1. A device is registered to **Windows Autopilot** (by hardware hash or OEM/CSP registration) and tagged for the shared-clinical model.
2. An **Autopilot self-deploying** profile provisions the device **with no user interaction** — it joins Microsoft Entra ID and enrolls in Intune at first boot, on the cart or kiosk stand.
3. A **Shared PC mode** configuration profile (SharedPC CSP) puts the device into **Shared multi-user** state: fast guest/account handling, automatic cleanup of cycled accounts, and account-management thresholds tuned for many users per device.
4. Where the device is **single-purpose** (a check-in kiosk, a wayfinding station), an **Assigned Access** kiosk profile restricts it to one app (single-app) or a defined set (multi-app).
5. A **clinical app baseline** (Win32/store apps) is assigned **Required** to the device group, so the standard clinical software installs on every device of that type.
6. **Power and sleep** settings keep **WOWs awake on battery** (display may dim; the device does not sleep), so a clinician never returns to a locked, asleep cart mid-round.
7. Optional **tap hand-off** (Imprivata badge tap) sits on top for fast clinician switching — referenced here, configured in the dedicated Imprivata solution.
8. Intune reports each device's enrollment type, shared-PC/kiosk state, group membership, app install status, and (critically) that **no personal primary user** is bound to the shared device.

## What you can require
- **Unattended provisioning** of shared devices via an **Autopilot self-deploying** profile.
- **Shared PC mode** (Shared multi-user) for many-users-per-device account handling and cleanup.
- **Kiosk lockdown** (Assigned Access single-app or multi-app) where a device is single-purpose.
- A **Required clinical app baseline** standardized across each device type.
- **Always-on / no-sleep on battery** power behavior for WOWs and carts.
- A **no-personal-owner** posture — shared devices carry **no primary user affinity**.

## Why the shared, no-owner model matters
- **Single-user device affinity is wrong for a cart.** Intune's primary-user / user-affinity model assumes one human owns the device. A WOW used by 30 clinicians a day must have **no primary user** so it isn't tied to one person's identity, license, or compliance state.
- **Self-deploying (not user-driven) Autopilot** is the correct enrollment mode because there is no user at the cart to drive setup — the device must come up on its own.
- **Shared PC mode** exists precisely for this: it manages a large rotation of accounts, cleans up after them, and keeps the device fast and uncluttered shift after shift.

## Limitations (be honest with buyers)
- **Self-deploying Autopilot requires TPM 2.0 and attestation** — the device must support and pass it; consumer-grade hardware may not.
- **Assigned Access kiosk is for single-purpose devices only.** A WOW that must run several clinical apps should use Shared PC mode (with optional multi-app kiosk), **not** a single-app lock.
- **Epic Hyperdrive / Hyperspace and Imprivata internals are out of scope** here — this solution standardizes the shared-device platform and references the dedicated Epic and Imprivata solutions for those products.
- **True roaming profiles are not used** on shared carts; Shared PC mode favors fast, disposable sessions over persistent per-user state.

## The standard deployment model
> **Register to Autopilot → self-deploying provision → Shared PC mode standardize → kiosk
> lock-down where single-purpose → clinical app baseline → keep awake on cart → pilot → validate
> → expand.** Phase model: **Assess → Enroll/Provision → Standardize → Lock-down → Pilot →
> Validate → Expand.**
