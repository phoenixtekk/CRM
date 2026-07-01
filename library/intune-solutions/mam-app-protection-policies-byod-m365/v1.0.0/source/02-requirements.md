# 2. Requirements Guide — MAM App Protection Policies for BYOD

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

The objects this solution creates (name them exactly, reuse verbatim throughout):
- Group `MAM Users – BYOD – Pilot` — the pilot user group.
- Group `MAM Users – BYOD – Production` — the broad user group.
- Policy `BYOD – App Protection – iOS` — the iOS/iPadOS App Protection Policy.
- Policy `BYOD – App Protection – Android` — the Android App Protection Policy.
- Policy `BYOD – App Config – M365` — the App Configuration Policy for managed apps.
- Policy `CA – Require APP – M365` — the Conditional Access grant enforcing app protection.

## 2.1 Licensing (Intune + Entra ID P1)
Description: An Intune plan for App Protection Policies, plus Entra ID P1 for Conditional Access.
Why: Intune delivers the App Protection and App Configuration policies; Conditional Access (P1)
enforces "Require app protection policy".
Verify: M365 admin center → Billing → Licenses; confirm Intune and Entra ID P1 (both in M365 E3/E5 and Business Premium).
Implement: Assign M365 E3/E5 or Business Premium (Intune + Entra ID P1 included) to targeted users.

## 2.2 Target users licensed and in scope
Description: The BYOD users who will get the policies are licensed and known.
Why: App Protection Policies are assigned to user groups, not devices.
Verify: Run `MAMAPP-Discovery.ps1`; confirm users hold Intune + Entra ID P1.
Implement: Assign licensing; add users to the scope groups (see 2.6).

## 2.3 Microsoft 365 mobile apps available
Description: The Microsoft 365 apps (Outlook, Teams, SharePoint, OneDrive, Edge) are installable on iOS and Android.
Why: App Protection Policies protect data inside these managed apps; the user must install them from the store.
Verify: The apps are available in the Apple App Store / managed Google Play for your users.
Implement: Publish the apps as available assignments in Intune (Apps → iOS/Android), or let users install them from the store.

## 2.4 Apple / Android platform prerequisites
Description: iOS/iPadOS uses the app directly; Android uses the Company Portal app as a broker (no enrollment).
Why: On Android, MAM-without-enrollment requires the Intune Company Portal app to be installed as the policy broker — but the device is not enrolled.
Verify: On a test Android device, the Company Portal app is installed (users are not prompted to enroll).
Implement: Instruct Android users to install Intune Company Portal from Google Play; it brokers MAM only.

## 2.5 Conditional Access ready (Entra ID)
Description: Conditional Access is available and a break-glass account is excluded from CA policies.
Why: The "Require app protection policy" grant is a Conditional Access policy; break-glass accounts prevent lockout.
Verify: entra.microsoft.com → Protection → Conditional Access loads; two break-glass Global Administrator accounts exist.
Implement: Confirm Entra ID P1; create two cloud-only break-glass Global Administrators to exclude from every CA policy.

## 2.6 Scope groups (Pilot + Production)
Description: Entra security groups `MAM Users – BYOD – Pilot` and `MAM Users – BYOD – Production`.
Why: Every rollout is piloted before production; policies assign to these groups.
Verify: Entra → Groups; both groups exist. Run `MAMAPP-Set-ScopeTargeting.ps1 -WhatIf` to preview.
Implement: Create the two groups (or run `MAMAPP-Set-ScopeTargeting.ps1` to create/populate them).

## 2.7 Admin roles
Description: Intune Administrator (for APP/app config) and Conditional Access Administrator (for the CA grant).
Why: Creating these policies requires the appropriate elevated roles.
Verify: Entra → Roles and administrators; confirm the operator holds the roles.
Implement: Assign Intune Administrator and Conditional Access Administrator; reserve Global Administrator for tenant-wide changes.

---
## Checklist
- [ ] Intune + Entra ID P1 licensing assigned
- [ ] Target users licensed and in scope — `MAMAPP-Discovery.ps1`
- [ ] Microsoft 365 mobile apps available to users
- [ ] Android users have Company Portal installed (broker, no enrollment)
- [ ] Conditional Access available; break-glass accounts excluded
- [ ] `MAM Users – BYOD – Pilot` and `MAM Users – BYOD – Production` groups created
- [ ] Intune Administrator + Conditional Access Administrator roles assigned
