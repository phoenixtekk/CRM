# 2. Requirements Guide — Privileged Access Workstation (PAW) for Cloud Administration

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites (tenant, base licensing, admin roles, break-glass
accounts, network) are in `global-requirements-entra-id-solutions.md` — do not repeat them here;
confirm them first.

## 2.1 Microsoft Intune (device management)
Description: An active Microsoft Intune service with Windows device management enabled.
Why: Intune builds and enforces the hardened PAW — baseline, ASR, application control, restrictions, and the compliance policy that defines a PAW.
Verify: `https://intune.microsoft.com` -> `Devices`; confirm Windows enrolment is configured; run `ENTPAW-Discovery.ps1`.
Implement: License Intune (bundled in M365 E3/E5, EMS) and configure Windows enrolment (Automatic enrolment / Autopilot). *Verify current licensing in your tenant.*

## 2.2 Entra ID P2 (PIM and device-filter enforcement)
Description: Microsoft Entra ID P2 for the administrators who will use the PAW.
Why: PIM (just-in-time activation) requires P2; risk-aware and advanced Conditional Access require P2. Device filters themselves are a Conditional Access feature and require Conditional Access (P1+).
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P2 for the admin accounts; in Entra confirm `Identity governance -> PIM` is available. *Verify current licensing availability in your tenant.*
Implement: Assign Entra ID P2 to the privileged operators, then run `ENTPAW-Discovery.ps1`.

## 2.3 Dedicated PAW hardware (or clean, dedicated devices)
Description: A physically or logically dedicated Windows device per privileged operator, used only for administration.
Why: The clean-source principle requires the admin credential to be used only from a high-trust device; a shared or general-purpose device defeats the control.
Verify: Confirm each pilot admin has a dedicated device that is not their daily productivity machine.
Implement: Provision dedicated hardware (preferred) or a well-isolated dedicated device/VDI for each admin; do not dual-purpose it for email/web.

## 2.4 Admin accounts separated from user accounts
Description: Administration performed with separate cloud admin accounts, distinct from the person's everyday user account.
Why: A PAW protects the device; separating accounts protects the credential, so a compromised user account cannot administer the tenant.
Verify: Entra -> `Users`; confirm privileged roles are held by dedicated admin accounts, not day-to-day user accounts; run `ENTPAW-Report.ps1`.
Implement: Create dedicated admin accounts for privileged operators; assign roles (via PIM eligibility) to those accounts, not to their user accounts.

## 2.5 PIM eligibility for the operated roles
Description: The privileged roles used from the PAW are onboarded to PIM as eligible (not standing), with an activation policy.
Why: The PAW is the clean device; PIM makes the privilege itself just-in-time so it is time-bound and only activated from that device.
Verify: Entra -> `Identity governance -> PIM -> Microsoft Entra roles -> Assignments`; confirm eligible assignments; run `ENTPAW-Validate.ps1`.
Implement: Onboard the roles to PIM as eligible (see the Privileged Identity Management solution) before enforcing the PAW device filter.

## 2.6 Break-glass exclusion group
Description: A security group containing your two cloud-only break-glass accounts, excluded from the PAW device-filter enforcement policy.
Why: If the device marking or compliance is misconfigured, break-glass accounts must still sign in and prevent a full lockout.
Verify: Entra -> `Groups`; confirm a group (for example `CA Break-Glass Exclusion`) contains both break-glass accounts; run `ENTPAW-Validate.ps1`.
Implement: Create/confirm `CA Break-Glass Exclusion` and add it to the Exclude tab of the device-filter policy.

## 2.7 A device-marking method for the CA device filter
Description: A chosen way to mark PAW devices so a Conditional Access device filter can recognise them — a device extension attribute (`extensionAttribute1`–`15`), a device category, or membership of a device group.
Why: The device-filter rule matches on a device property; that property must be set on PAWs and only on PAWs.
Verify: Entra -> `Devices`; confirm the chosen attribute/category is available and not already used for another purpose; run `ENTPAW-Discovery.ps1`.
Implement: Choose one marker (this guide uses `extensionAttribute1 = PAW`), reserve it for PAWs, and set it with `ENTPAW-DeviceTag.ps1` (preview-first).

## 2.8 Pilot scope (admins and devices)
Description: A small set of pilot admins and their pilot PAWs to validate hardening, compliance, device-filter enforcement, and PIM before tenant-wide rollout.
Why: The identity plane is high risk; a report-only pilot proves the control and the admin experience before it blocks anyone.
Verify: Entra -> `Groups`; confirm the pilot user and device groups exist; run `ENTPAW-Validate.ps1`.
Implement: Create `PAW Admins – Cloud Admin – Pilot` (users) and `PAW Devices – Admin Devices – Pilot` (devices) and populate them with the pilot admins and their PAWs.

---
## Checklist
- [ ] Microsoft Intune with Windows enrolment — `ENTPAW-Discovery.ps1` *(verify licensing)*
- [ ] Entra ID P2 for privileged operators — *(verify licensing)*
- [ ] Dedicated PAW device per pilot admin
- [ ] Separate cloud admin accounts in use — `ENTPAW-Report.ps1`
- [ ] Operated roles onboarded to PIM (eligible) — `ENTPAW-Validate.ps1`
- [ ] `CA Break-Glass Exclusion` group contains both break-glass accounts
- [ ] Device marker chosen and reserved (e.g. `extensionAttribute1 = PAW`) — `ENTPAW-DeviceTag.ps1`
- [ ] `PAW Admins – Cloud Admin – Pilot` and `PAW Devices – Admin Devices – Pilot` created — `ENTPAW-Validate.ps1`
