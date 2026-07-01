# 2. Requirements Guide — Endpoint Imaging, Inventory & Hardware Lifecycle Management

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-infrastructure.md`.

## 2.1 Intune (provisioning, inventory, and retire/wipe)
Description: Microsoft Intune (Plan 1), the control plane for Autopilot, enrollment, hardware
inventory, and the retire/wipe actions.
Why: Autopilot profiles, device inventory, and the secure-wipe lifecycle actions all live in Intune.
Verify: `intune.microsoft.com` loads; Devices is visible.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## 2.2 Provisioning method chosen (Autopilot or imaging)
Description: A deliberate decision: Windows Autopilot cloud provisioning (default) or Configuration
Manager task-sequence imaging (where required).
Why: This decides where the golden state lives and how devices are onboarded; the implementation
steps differ.
Verify: Confirm which method this fleet (or this site) will use; run `IMGLIFE-Discovery.ps1` to see
current state (Autopilot registration, enrollment, any ConfigMgr client).
Implement: Default to Autopilot. Use Configuration Manager imaging only for sites/device types that
require a custom on-disk image or offline deployment, and confirm a working ConfigMgr site exists.

## 2.3 Windows Autopilot prerequisites (if using Autopilot)
Description: Devices' hardware identities registered to Autopilot (vendor registration or imported
hardware hash) and an Autopilot deployment profile.
Why: Autopilot can only provision devices it recognizes by hardware identity.
Verify: Intune → Devices → Enrollment → Windows Autopilot → Devices shows the registered devices;
run `IMGLIFE-Validation.ps1`.
Implement: Have the OEM/reseller register devices, or import the hardware hash; create an Autopilot
deployment profile (Step 2 of the Implementation Guide).

## 2.4 Configuration Manager environment (if using imaging)
Description: A working ConfigMgr site with a distribution point, boot media, an OS image package, and
a task sequence.
Why: Task-sequence imaging deploys the OS and apps from on-premises distribution points.
Verify: ConfigMgr console → Software Library → Operating Systems → Task Sequences shows a usable
deployment task sequence.
Implement: Stand up (or reuse) a ConfigMgr site and build an OS-deployment task sequence; this is
out of scope here but noted as the imaging path.

## 2.5 Device enrollment in Intune
Description: Provisioned devices are enrolled and manageable in Intune.
Why: Inventory, lifecycle groups, and retire/wipe only reach enrolled devices.
Verify: Intune → Devices → All devices shows the device; run `IMGLIFE-Validation.ps1`.
Implement: Enable automatic enrollment and join devices to Entra ID (Autopilot enrolls
automatically; imaged devices enroll via the join/enrollment step).

## 2.6 Hardware inventory source of truth
Description: Intune device hardware inventory is treated as the authoritative inventory, with a
procurement record to reconcile against.
Why: An accurate, single source of truth is what makes audits, refresh planning, and reconciliation
possible.
Verify: Intune → Devices → All devices → (a device) → Hardware shows model, serial, storage; run
`IMGLIFE-Report.ps1` for the fleet inventory.
Implement: Ensure devices are enrolled (so they report hardware); keep a procurement list (serials)
to reconcile against the enrolled inventory.

## 2.7 Retirement and secure-wipe process
Description: A defined end-of-life action — Retire (remove company data/management) or Wipe (full
factory reset) — and who is authorized to run it.
Why: A device must leave the fleet clean; an undocumented retirement is how data walks out the door.
Verify: Confirm the operator holds Intune Administrator and that the action is documented; preview
with `IMGLIFE-Remediation.ps1` (runs in WhatIf mode by default).
Implement: Document the retire-vs-wipe decision and authorization; use `IMGLIFE-Remediation.ps1` as
the safe helper.

## 2.8 Lifecycle-stage groups
Description: Entra ID security groups for each lifecycle stage, named by the solution convention.
Why: Stages let policy and reporting target the right population as a device moves through its life.
Verify: Entra → Groups shows the four lifecycle groups; or run
`IMGLIFE-Set-LifecycleStageTargeting.ps1` (idempotent — reports/creates).
Implement: Run `IMGLIFE-Set-LifecycleStageTargeting.ps1` to create them, or create them by hand with
the exact names below.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Provisioning method chosen (Autopilot default, or ConfigMgr imaging) — `IMGLIFE-Discovery.ps1`
- [ ] Autopilot devices registered + deployment profile (if Autopilot) — `IMGLIFE-Validation.ps1`
- [ ] ConfigMgr site + task sequence (if imaging)
- [ ] Devices enrolled in Intune
- [ ] Hardware inventory established as source of truth — `IMGLIFE-Report.ps1`
- [ ] Retire/wipe action documented and authorized
- [ ] Lifecycle-stage groups created — `IMGLIFE-Set-LifecycleStageTargeting.ps1`
