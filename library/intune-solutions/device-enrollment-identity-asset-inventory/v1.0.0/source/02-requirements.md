# 2. Requirements Guide — Device Enrollment, Identity Association & Asset Inventory

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1 or via M365 E3/E5 / Business Premium) for every enrolled user/device.
**Why:** Enrollment, primary-user association, and inventory all require an Intune license.
**Verify:** M365 admin center → **Billing → Licenses**; users who will enroll have Intune assigned.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 MDM authority and automatic enrollment
**Description:** Intune set as the MDM authority, with automatic enrollment configured for Windows.
**Why:** Automatic enrollment is what enrolls an Entra-joined Windows device into Intune in one step.
**Verify:** Intune → **Devices → Enrollment → Automatic Enrollment**; **MDM user scope** is **All**
(or your pilot group).
**Implement:** Set **MDM user scope** to your enrollment group; leave MAM scope as your policy.

## 2.3 Enrollment restrictions reviewed
**Description:** Device-platform and device-limit enrollment restrictions that match what you support.
**Why:** Restrictions keep the inventory clean — only allowed platforms/ownership types enroll.
**Verify:** Intune → **Devices → Enrollment → Enrollment restrictions**; review the **Default**
device-platform restriction; run `ENROLLID-Discovery.ps1`.
**Implement:** Create a platform restriction allowing only the platforms/ownership you support
(see Implementation Step 3).

## 2.4 Identity model for primary user
**Description:** A clear rule for who the primary user should be (the day-to-day user of the device).
**Why:** Service-desk lookup, app targeting, and licensing all key off the primary user.
**Verify:** Intune → **Devices → All devices →** open a device → **Properties → Primary user**;
run `ENROLLID-Validation.ps1` against a pilot device.
**Implement:** Adopt the rule "primary user = the enrolling/daily user; shared & DEM devices have
none," then correct exceptions with `ENROLLID-Remediation.ps1`.

## 2.5 Enrollment status page (Autopilot/Windows)
**Description:** An enrollment status page (ESP) profile controlling first sign-in setup.
**Why:** The ESP gates the desktop until apps/policies install, so the device is ready before use.
**Verify:** Intune → **Devices → Enrollment → Enrollment Status Page**; the **Default** profile (or
your named profile) is configured.
**Implement:** Configure the ESP profile (see Implementation Step 5).

## 2.6 (Autopilot) Hardware hash / device import path
**Description:** A way to register corporate devices (OEM/partner registration or imported hardware hashes).
**Why:** Autopilot provisioning needs the device's hardware identity registered to your tenant.
**Verify:** Intune → **Devices → Enrollment → Windows → Devices**; corporate devices are listed.
**Implement:** Have the OEM/CSP register devices, or import hardware hashes (CSV) for existing
hardware.

## 2.7 Inventory reconciliation source (optional but recommended)
**Description:** An external list of devices that *should* exist (procurement/CMDB/HR export, CSV).
**Why:** Reconciliation compares Intune against an authoritative "should exist" list to find gaps.
**Verify:** You have a CSV of expected devices (serial number and/or device name).
**Implement:** Export a device list from procurement/CMDB; `ENROLLID-Report.ps1` reconciles it
against Intune.

## 2.8 Microsoft Graph access for the scripts
**Description:** Permission to read managed devices and Entra devices via Microsoft Graph.
**Why:** Discovery, validation, and reporting scripts query Graph for device + primary-user data.
**Verify:** An admin can consent to `DeviceManagementManagedDevices.Read.All` and
`Device.Read.All`.
**Implement:** Sign in with an Intune Administrator when the script prompts for consent.

---
## Checklist
- [ ] Intune licensing assigned to enrolling users
- [ ] MDM authority = Intune; automatic enrollment scope set
- [ ] Enrollment restrictions reviewed — `ENROLLID-Discovery.ps1`
- [ ] Primary-user identity rule decided — `ENROLLID-Validation.ps1`
- [ ] Enrollment status page configured
- [ ] (Autopilot) corporate devices registered / hashes imported
- [ ] (Optional) external "should exist" list for reconciliation
- [ ] Graph read access for the scripts
- [ ] Pilot Entra group(s) created
