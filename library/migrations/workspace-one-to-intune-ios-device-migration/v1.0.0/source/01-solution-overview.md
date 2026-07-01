# 1. Solution Overview — Workspace ONE to Intune iOS/iPadOS Device Migration

## What this migration is
This is the repeatable way to move supervised, ADE-enrolled iPhones and iPads off **VMware Workspace ONE UEM**
and onto **Microsoft Intune**, without losing supervision, app delivery, or device configuration. Apple devices
are the hardest part of any Workspace ONE exit because the path to a new MDM is gated by **Apple Business Manager
(ABM)**: a supervised, Automated Device Enrollment (ADE) device is bound to whatever **MDM server** ABM points it
at, and that binding only changes when an administrator **re-assigns the device in ABM** and the device
**re-enrolls** — which for an already-supervised device almost always means **wipe and re-enroll**.

## Why Apple is different (the why lives here)
On Windows you can often migrate management authority in place. On iOS/iPadOS you cannot: supervision and the ADE
enrollment profile are applied during Setup Assistant and are enforced by Apple, not by the MDM. A device that was
supervised under Workspace ONE will not silently become supervised under Intune. To change its managing MDM you
must (1) re-assign the device from the Workspace ONE MDM server to the Intune MDM server **in Apple Business
Manager**, and (2) put the device through Setup Assistant again so it picks up the Intune ADE enrollment profile.
Step 2 requires an erase. That single reality — re-assign in ABM, then wipe-and-re-enroll — shapes the entire
program: it must be ringed, communicated to users, and validated on a pilot before it touches the fleet, because
every migrated device is briefly unmanaged and its on-device data is reset.

## How it works
1. Connect **Apple Business Manager to Intune**: an **Apple MDM Push (APNs) certificate** and an **ADE token**
   (an MDM server in ABM whose public key comes from Intune) make Intune a valid MDM server for your Apple devices.
2. Build **Intune ADE enrollment profiles** that re-create the supervision and Setup Assistant experience the
   devices had under Workspace ONE.
3. Rebuild **app and configuration parity** in Intune — the store/VPP apps, Wi-Fi, VPN, email, restrictions, and
   compliance the devices had under Workspace ONE — so a re-enrolled device lands fully configured.
4. **Re-assign devices in Apple Business Manager** from the Workspace ONE MDM server to the Intune MDM server.
5. **Re-enroll** each device by ring — for supervised ADE devices this is a wipe-and-re-enroll through Setup
   Assistant — so it picks up the Intune ADE profile and the parity policies.
6. Cut over in **rings** (pilot first), with **user communications** and a **rollback** path, then expand.

## What you migrate
- **Enrollment and supervision** — supervised ADE re-enrollment under Intune (the Workspace ONE binding is replaced).
- **Apps** — store and Volume Purchase (VPP/ABM) apps re-published in Intune with the same assignments.
- **Configuration** — Wi-Fi, VPN, email, certificates, and device restrictions re-created as Intune profiles.
- **Compliance** — an iOS/iPadOS compliance policy matching (or improving on) the Workspace ONE baseline.

## Limitations (be honest with buyers)
- Supervised ADE devices generally require **wipe-and-re-enroll**; on-device data is erased, so back up or accept loss.
- **Workspace ONE internals** (its console layout, its API, its profile export) are the source vendor's domain —
  this solution defers those specifics to VMware documentation and focuses on the **Intune + Apple Business
  Manager** side, which it covers exactly.
- ABM device **re-assignment** and ADE **sync** are rate-limited by Apple; allow time between assignment and re-enroll.
- A device that is still **checked in to Workspace ONE** when you re-assign it will not move until it is erased and
  runs Setup Assistant again — coexistence is expected during the transition.

## The standard deployment model
> **Connect ABM to Intune → build enrollment profiles and parity policies → re-assign in ABM → re-enroll by ring →
> validate on the pilot → expand.** The repeatable model: **Assess → Configure → Pilot → Validate → Expand.**
