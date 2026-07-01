# 1. Solution Overview — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

## What this solution is

This is a multi-platform **program** to migrate an organization's entire endpoint estate off **VMware Workspace ONE UEM** and onto **Microsoft Intune** — Windows, iOS/iPadOS, Android, and macOS — as one repeatable, documented operating model. It is a **program playbook**, not a single wizard: it pairs a phased methodology with per-platform runbooks so a program lead and a team of admins can execute a controlled, reversible, no-loss migration across live, enrolled production devices.

The program covers four platform workstreams, each with its own enrollment model, app delivery channel, and parity surface:

1. **Windows** — move from Workspace ONE Windows management to Intune MDM via Entra join / hybrid join and Windows automatic enrollment; rebuild configuration profiles, compliance, and apps (Win32/Store/MSI).
2. **iOS/iPadOS** — move from Workspace ONE Apple management to Intune; re-establish Apple Push (APNs) and (for corporate devices) Apple Business Manager / Automated Device Enrollment; rebuild profiles and app assignments (VPP/managed store apps).
3. **Android** — move from Workspace ONE Android management to Intune managed Google Play (Android Enterprise — work profile, fully managed, or dedicated); rebuild policies and managed app assignments.
4. **macOS** — move from Workspace ONE Mac management to Intune; re-establish APNs and (for corporate Macs) ABM/ADE; rebuild configuration profiles, compliance, and apps (PKG/DMG/managed store).

## The single most important reality: an endpoint cannot be enrolled in two MDMs at once

A device has **one** active MDM enrollment per platform channel. Workspace ONE and Intune are **separate UEM platforms**; there is no in-place "convert" that flips a device from one to the other while preserving state. Consequently, migrating a device means **un-enrolling it from Workspace ONE and (re-)enrolling it into Intune**, and rebuilding the management state (profiles, compliance, apps) that Workspace ONE was delivering. Key implications that shape every phase:

- **Policies and apps are rebuilt, not copied.** There is no Workspace ONE → Intune configuration export that lands as native Intune policy. Each in-scope profile, compliance rule, and app is **re-authored** in Intune to achieve **parity** with what Workspace ONE delivered.
- **Identity must resolve in Entra first.** Devices and users must exist and authenticate in Microsoft Entra ID before Intune can enroll and target them.
- **Enrollment plumbing is per platform.** APNs (Apple), ABM/ADE token (corporate Apple), managed Google Play (Android), and Windows automatic enrollment must each be live in Intune before that platform's devices can move.
- **Coexistence is real but bounded.** During transition both platforms exist in the org, but a given **device** is managed by one at a time. The program runs a controlled coexistence window per wave (source still managing un-migrated devices, target managing migrated ones), not indefinite dual-management of the same device.
- **Cutover is reversible per device.** Because cutover is "leave source, join target," the rollback is "re-enroll to source" — but only inside the change window and before the source assignment is removed.
- **Re-enrollment is user-visible.** Most platforms require user action or a wipe/reset for corporate ADE devices. This drives the wave model, comms, and the pilot gate.

## Why this is one of the highest-risk endpoint projects there is

A UEM exit touches every employee's primary work device. Done ad hoc it stalls in finger-pointing between the source team, the target team, and the helpdesk; done without parity it silently drops a VPN profile or a Wi-Fi cert and breaks access mid-day; done without waves it turns a bad pilot into a fleet-wide outage. The value of running it **as a program** is:

- **One coordinated effort** instead of four uncoordinated platform migrations — shared discovery, one wave plan, one set of acceptance gates, one rollback posture.
- **Parity is proven before cutover.** Every device migrates into a known-good Intune state that was validated on a pilot wave first.
- **No device and no app is left behind.** Decommission of Workspace ONE happens only after each wave's devices pass validation in Intune.
- **The whole program is evidenced** — every wave, profile set, enrollment profile, and group is named and recorded, so status and rollback are unambiguous.

## How it works (the flow)

1. **Discover** the Workspace ONE estate and the Intune target side: every enrolled device, its platform/ownership, the apps and profiles assigned, and the users behind them.
2. **Assess** parity scope and per-platform complexity; rate each profile/app/device-cohort High/Med/Low.
3. **Plan** waves and per-platform sequencing; name every object that will be created.
4. **Configure** the Intune target: identity readiness, per-platform enrollment plumbing, and the rebuilt parity policy sets and apps.
5. **Pilot** every platform end-to-end against a small representative wave (the pilot-wave gate).
6. **Validate** the pilot against explicit parity and access gates.
7. **Expand** wave by wave: coexistence → per-device cutover (un-enroll source, enroll target) → validate.
8. **Decommission** Workspace ONE per wave only after its devices pass, then retire the platform.

## Per-platform approach at a glance

| Platform | Target enrollment model | App delivery (target) | Cutover mechanics | Notes |
|---|---|---|---|---|
| Windows | Entra join / hybrid join + Windows automatic enrollment | Win32 (`.intunewin`), Store (new), MSI line-of-business | Unenroll from source, auto-enroll to Intune; often no wipe | Hybrid join needs Entra Connect + GPO/SCP. |
| iOS/iPadOS | APNs; corporate via ABM/ADE; BYOD via user enrollment / device enrollment | VPP/managed store apps, managed app config | Corporate ADE devices typically wipe/reset; BYOD re-enrolls | ADE re-assignment is done in `business.apple.com`. |
| Android | managed Google Play (Android Enterprise): work profile / fully managed / dedicated | managed Google Play apps, managed config | Work profile re-enrolls; fully managed/dedicated reset | Mode chosen per ownership. |
| macOS | APNs; corporate via ABM/ADE | PKG/DMG line-of-business, managed store apps, shell scripts | Corporate ADE Macs typically wipe/reset; others re-enroll | Mirrors the Apple model. |

> **Vendor boundary:** the **Workspace ONE (VMware)** console actions in this program (export inventory, locate device/app/profile assignments, release an enrolled device, release the ADE/DEP token, retire the platform) are named by **action and control**, not by exact menu path — Workspace ONE console internals are deferred to current VMware documentation. The **Microsoft Intune / Entra / Apple Business Manager** side is given as exact navigation (`intune.microsoft.com`, `entra.microsoft.com`, `business.apple.com`).

## Benefits

- **A single Microsoft-native endpoint stack** — Intune + Entra + (optionally) Defender for Endpoint, with one console and one compliance/Conditional Access model.
- **Licensing consolidation** — Intune is typically already owned via Microsoft 365 E3/E5 / Business Premium, removing the separate Workspace ONE spend.
- **Controlled, low-surprise execution** — one program, one wave plan, pilots, parity validation, and a per-device rollback, instead of four ad-hoc platform moves.
- **Auditability** — every wave, parity policy set, enrollment profile, and group is named and recorded; every cutover is gated and evidenced.

## Honest limitations

- **This is not a same-day cutover.** A full multi-platform fleet program runs weeks to months; enrollment-plumbing lead times (APNs, ABM, managed Google Play) come first.
- **Policies and apps are rebuilt, not migrated.** There is no native Workspace ONE → Intune config import; parity is re-authored.
- **Corporate Apple/Android devices commonly require a wipe/reset** to move enrollment cleanly (especially ADE/DEP and fully managed Android) — plan user comms and data backup accordingly.
- **Coexistence is per device, not per policy.** Both platforms exist during transition, but a device is managed by exactly one at a time; "dual-managing" the same device is not a supported state.
- **Identity must lead.** Devices/users must resolve and authenticate in Entra ID before Intune can manage them; that work is foundational, not optional.

## The standard program model

This solution follows the standard deployment model — **Assess → Configure → Pilot → Validate → Expand** — applied as a phased program with named objects, an explicit **pilot-wave gate**, and per-device rollback at every cutover:

**Discover → Assess → Plan → Configure (identity + enrollment + parity rebuild) → Pilot → Validate (pilot-wave gate) → Expand (coexistence → cutover → validate, wave by wave) → Decommission.**

No production wave begins until the pilot wave passes its parity and access gates, and **no Workspace ONE device or assignment is decommissioned until its wave's devices have passed validation in Intune** and a defined grace period has elapsed.
