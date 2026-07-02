# 2. Requirements Guide — Dynamic Device Targeting in Intune

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Entra ID P1 licensing (dynamic groups)
Description: Microsoft Entra ID P1 (included in M365 E3/E5 and Business Premium).
Why: Dynamic membership rules on security groups require Entra ID P1; without it groups can only be
static.
Verify: Entra admin center -> `Overview` shows the licence, or `Billing -> Licenses` lists Entra ID
P1 / an E3/E5 / Business Premium plan.
Implement: Assign an Entra ID P1-bearing plan to the tenant/administrator.

## 2.2 Devices enrolled in Intune
Description: Targeted devices are enrolled and appear as managed devices.
Why: Assignment filters evaluate managed-device properties; membership rules read Entra device
attributes populated at enrollment.
Verify: Intune -> `Devices -> All devices`; run `DYNTGT-Discovery.ps1`.
Implement: Enable automatic enrollment and enroll the devices.

## 2.3 A device attribute / naming convention
Description: A consistent set of device attributes to target on — ownership, category, model, and a
device-naming or enrollment-profile convention.
Why: Membership and filter rules are only as accurate as the attributes they read; inconsistent data
produces mis-scoped targeting.
Verify: Intune -> `Devices -> All devices`; confirm ownership, category, and model are populated;
run `DYNTGT-Discovery.ps1` (reports attribute coverage).
Implement: Set device categories and ownership; standardize device naming and enrollment profiles so
attributes are populated at enrollment.

## 2.4 Enrollment profile names
Description: Named enrollment profiles (for example Autopilot / ADE / enrollment configuration
profiles) whose `enrollmentProfileName` can be targeted.
Why: `enrollmentProfileName` is one of the most reliable attributes for dynamic targeting of
corporate devices.
Verify: Intune -> `Devices -> Enrollment`; confirm the profiles exist and are named; run
`DYNTGT-Discovery.ps1`.
Implement: Create and name the enrollment profiles before building rules that reference them.

## 2.5 Assignment-filter management access
Description: The operator can create and manage assignment filters.
Why: Filters are created under Intune tenant administration and reused across assignments.
Verify: Intune -> `Tenant administration -> Filters` loads and allows `Create`.
Implement: Assign the Intune Administrator role (see global requirements G3).

## 2.6 A pilot group
Description: A small pilot audience to validate effective targeting before broad use.
Why: Every solution is piloted before fleet rollout; targeting must be validated on a
few devices first.
Verify: Entra -> `Groups`; the pilot group exists.
Implement: Create dynamic group `Corp Devices – Windows – Pilot` (see Implementation Step 2).

---
## Checklist
- [ ] Entra ID P1 licensing for dynamic groups
- [ ] Devices enrolled in Intune — `DYNTGT-Discovery.ps1`
- [ ] Device attributes / naming convention populated (ownership, category, model)
- [ ] Enrollment profiles created and named
- [ ] Assignment-filter management access (Intune Administrator)
- [ ] Pilot dynamic group created
