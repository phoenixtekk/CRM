# 3. Implementation Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
The default path is Windows Autopilot cloud provisioning; Step 3 covers the Configuration Manager
task-sequence imaging alternative for sites that require it.

> Model: choose one provisioning method, register/import devices and establish inventory, build the
> lifecycle-stage groups, then pilot the procure → deploy → refresh → retire flow before expanding.

## Step 1 — Create the lifecycle-stage groups
Create these four Entra ID security groups (Entra → Groups → New group → Security), using the exact
names so the rest of the solution can reuse them verbatim:
1. `Device Lifecycle – Procurement – Procured`
2. `Device Lifecycle – Fleet – Deployed`
3. `Device Lifecycle – Aging – Refresh-Due`
4. `Device Lifecycle – End-of-Life – Retire`

Also create the pilot provisioning group `Autopilot Provisioning – Standard Users – Pilot` (a few
representative users/devices) and `Autopilot Provisioning – Standard Users – Broad` (the rest).
Tip: `IMGLIFE-Set-LifecycleStageTargeting.ps1` creates these idempotently.

## Step 2 — Register devices and create the Autopilot deployment profile (default path)
1. Register hardware identities: Devices → Enrollment → Windows Autopilot → Devices. Devices
   registered by your OEM/reseller appear here; otherwise import the hardware hash (CSV) with Import.
2. Create the profile: Devices → Enrollment → Windows Autopilot → Deployment profiles →
   Create profile → Windows PC.
3. Name: `Autopilot Provisioning – Standard Users – Pilot`. Next.
4. Out-of-box experience (OOBE): set deployment mode (User-driven), join type (Microsoft Entra
   joined), and the OOBE options (hide EULA, hide privacy settings, etc.) to your policy. Next.
5. Assignments → Add groups → `Autopilot Provisioning – Standard Users – Pilot`. Next → Create.
6. Repeat for `Autopilot Provisioning – Standard Users – Broad` assigned to the broad group (do this
   after the pilot validates).

## Step 3 — Alternative: Configuration Manager task-sequence imaging (only if required)
Use this instead of Step 2 only for sites/device types that need a custom on-disk image or offline
deployment. In the Configuration Manager console:
1. Software Library → Operating Systems → confirm an OS image package and a deployment task sequence
   exist on a distribution point.
2. Deploy the task sequence to the imaging collection and boot the device from PXE or boot media.
3. After imaging, ensure the device enrolls into Intune (Entra join + automatic enrollment) so it
   reports hardware inventory like any other device.

## Step 4 — Establish hardware inventory as the source of truth
1. Confirm enrolled devices report hardware: Devices → All devices → (a device) → Hardware (model,
   serial number, storage, memory).
2. Pull the fleet inventory with `IMGLIFE-Report.ps1` (Microsoft Graph), which lists managed devices
   plus the Autopilot registered-devices list.
3. Reconcile your procurement list (serials purchased) against the report to find gaps: bought but
   not enrolled, or enrolled but not on the books.

## Step 5 — Move devices into the Deployed stage
1. As devices finish provisioning and report inventory, add them to
   `Device Lifecycle – Fleet – Deployed`.
2. Keep `Device Lifecycle – Procurement – Procured` for devices received but not yet provisioned, so
   the reconciliation report can flag procured-but-not-deployed machines.

## Step 6 — Define refresh criteria and flag refresh-due devices
1. Decide the refresh trigger (for example, age over N years, warranty expired, or below a spec
   threshold).
2. Run `IMGLIFE-Report.ps1` to identify devices meeting the criteria (enrollment/age and hardware
   fields).
3. Add those devices to `Device Lifecycle – Aging – Refresh-Due` and procure their replacements.

## Step 7 — Implement secure retirement and wipe
1. For a device at end of life, add it to `Device Lifecycle – End-of-Life – Retire`.
2. Preview the action first: run `IMGLIFE-Remediation.ps1` (WhatIf by default) to confirm the target
   device and the chosen action.
3. In Intune, Devices → All devices → (the device) → choose Retire (remove company
   data/management) or Wipe (full factory reset) per your documented policy. Wipe is the secure full
   reset; Retire keeps the OS but removes company data and management.
4. After confirming the wipe completed, remove the device record and de-register it from Autopilot
   (Devices → Enrollment → Windows Autopilot → Devices → Delete) so inventory stays clean.

## Step 8 — Pilot the full flow
1. Run the whole procure → deploy → refresh → retire flow on the
   `Autopilot Provisioning – Standard Users – Pilot` group.
2. Validate with `IMGLIFE-Validation.ps1` (provisioning/enrollment) and `IMGLIFE-Report.ps1`
   (inventory and reconciliation). Complete the Testing Guide.

## Step 9 — Expand to production
1. After the pilot passes, assign the broad Autopilot profile and onboard the rest of the fleet.
2. Run the lifecycle on the broad population; re-reconcile inventory each cycle with
   `IMGLIFE-Report.ps1`.

---
### Order of operations
`Lifecycle groups → register devices + Autopilot profile (or ConfigMgr imaging) → establish
inventory → Deployed stage → refresh criteria → secure retire/wipe → pilot → expand`
