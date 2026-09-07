# Solution Overview

## What this solution is

A complete, wave-based program to migrate an Apple fleet **off Jamf Pro and onto Microsoft Intune**,
covering **all three Apple platforms in one solution: macOS, iPadOS, and iOS/iPhone**. It takes you
from discovery through pilot, production waves, and Jamf decommissioning — with the enrollment,
application, and configuration realities of Apple device management handled correctly so devices land
in Intune managed, compliant, and with their apps and policies intact.

This is a **migration program**, not a co-existence guide. Where a companion solution covers the
generic MDM readiness assessment or the steady-state macOS/iOS Intune baseline, this solution
references it rather than re-teaching it, and focuses on the migration itself.

## The one rule that shapes everything: one MDM per Apple device

An Apple device can be enrolled in **exactly one** MDM at a time. Jamf and Intune **cannot
co-manage** the same device. So migration is never a silent hand-off — every device must **leave
Jamf and enroll into Intune**, and *how* it does that depends on whether it is supervised (ADE) or
user-enrolled (BYOD):

- **Supervised / Automated Device Enrollment (ADE) devices** — the corporate-owned devices enrolled
  through Apple Business Manager. Moving one to a new MDM requires an **erase (Erase All Content and
  Settings)**: after you re-assign the device to Intune's MDM server in ABM, it enrolls into Intune on
  the **next Setup Assistant**. There is no way to move a supervised ADE device between MDMs without a
  wipe. Plan for it.
- **User-enrolled / BYOD (and non-supervised) devices** — unenroll from Jamf (which removes the MDM
  profile), then re-enroll into Intune via the **Company Portal** or **account-driven user
  enrollment**. **No wipe** required.

## Apple Business Manager (ABM) is the pivot

The migration turns on **ABM → Devices**, where every corporate device (or the default assignment) is
assigned to an MDM server. You **re-assign** devices from the **Jamf MDM server** to the **Intune MDM
server** — Intune's enrollment program (ADE) token, connected under *Intune → Devices → Enrollment →
Apple → Enrollment program tokens*. Re-assignment is instant in ABM, but for supervised devices it
only takes effect on the next erase + Setup Assistant.

## Apps and configuration have to come across too

- **VPP / Apps and Books.** App licenses are bound to the MDM that assigned them. You connect the
  **Apple VPP (Apps and Books) token** to Intune, **revoke** the licenses in Jamf, and **re-deploy**
  the apps from Intune. One VPP token per location.
- **Configuration.** Jamf configuration profiles, smart groups, and policies are **rebuilt** as Intune
  configuration profiles (Settings Catalog / templates), assignments, and compliance policies — they
  do not transfer; you translate them.
- **macOS extras.** FileVault recovery keys must be **re-escrowed** to Intune (the Jamf-escrowed key
  does not move); Jamf Connect login/SSO becomes **Intune Platform SSO** (macOS 13+) or the Enterprise
  SSO app extension; Jamf packages/scripts become Intune macOS apps (VPP, unmanaged PKG/DMG) and shell
  scripts; Microsoft Defender for Endpoint is **re-onboarded**.
- **iOS/iPadOS extras.** Restrictions, Wi-Fi, per-app VPN, web clips, home-screen layout, and kiosk /
  Autonomous Single App Mode are rebuilt as Intune profiles; **SCEP/PKCS certificates** are re-issued
  through the Intune connectors.

## Three migration approaches — blended by wave

1. **Wipe-and-enroll** — required for **ADE/supervised** devices: ABM re-assign → erase → Setup
   Assistant → auto-enrolls in Intune. Cleanest end state.
2. **Unenroll-and-re-enroll** — for **BYOD/user-enrolled** devices: no wipe.
3. **Attrition / refresh** — new and refreshed devices enroll into Intune first; the Jamf fleet drains
   over the hardware-refresh cycle.

Most fleets use a **blend, wave by wave**: BYOD and new devices move with no disruption, supervised
devices are scheduled for a wipe window, and Jamf keeps running for everything not yet migrated.

## The standard deployment model

**Assess (inventory Jamf + confirm Intune/ABM/VPP readiness) → Build the Intune target per platform →
Pilot wave (a few Macs, iPads, iPhones) → Validate → Production waves → Decommission Jamf.** No
device is cut over until its Intune enrollment and compliance are verified, and Jamf stays available
for rollback until each wave is signed off.

## Benefits

- **All three Apple platforms in one program** — macOS, iPadOS, and iOS/iPhone, with the platform
  differences (supervised vs BYOD, VPP, FileVault, SSO) handled explicitly.
- **No surprises on wipe scope** — you know up front which devices need an erase and which do not.
- **Apps and policies preserved** — VPP re-assignment and profile translation are part of the plan.
- **Reversible per wave** — Jamf stays live until each wave is validated.
- **Trackable** — scripts reconcile the Jamf inventory against Intune enrollment so you always know
  what has migrated, what is pending, and what failed.

## Limitations & scope

- **Supervised devices require a wipe** to change MDM — an Apple platform rule, not an Intune
  limitation. This program plans and schedules it; it cannot avoid it.
- **No dual-MDM coexistence** — a device is on Jamf *or* Intune. The program manages a per-wave
  cutover, not simultaneous management.
- Deep single-platform steady-state configuration (macOS baseline, iOS lockdown, etc.) is covered by
  the companion Intune baseline solutions and referenced here, not rebuilt.
- **Sovereign clouds:** ABM + Intune is supported in GCC High / DoD and the migration mechanics are
  identical; only the portal host differs (`intune.microsoft.us` / `endpoint.microsoft.us`), noted
  inline. A single deliverable covers both.
