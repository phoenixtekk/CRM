# 2. Requirements Guide — Secure Mobile Access to SharePoint Online under MAM

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing (Intune + Entra ID P1 + SharePoint Online)
**Description:** Intune (Plan 1) for App Protection Policies, Microsoft Entra ID P1 for Conditional
Access, and a SharePoint Online / Microsoft 365 plan for the intranet.
**Why:** App Protection Policies come from Intune; the CA grant requires Entra ID P1; SharePoint
Online hosts the intranet users are trying to reach.
**Verify:** M365 admin center → **Billing → Licenses**; confirm Intune, Entra ID P1 (or M365
E3/E5 / Business Premium, which include both), and SharePoint Online.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune + Entra ID P1 + SharePoint Online
included) to the target users.

## 2.2 Target users and a pilot group
**Description:** Entra security groups for the users who need mobile intranet access, plus a small
pilot group.
**Why:** App Protection Policies and Conditional Access are assigned to user groups; the pilot group
proves the change before the fleet gets it.
**Verify:** Entra → **Groups**; the target group and a pilot group exist.
**Implement:** Create the groups (Entra → **Groups → New group → Security**), or use
`SPMAM-Set-ScopeTargeting.ps1` to build them.

## 2.3 The Microsoft mobile apps in scope
**Description:** The SharePoint mobile app and Microsoft Edge, from the official app stores, on the
users' iOS/iPadOS and Android devices.
**Why:** These are the two *supported* access paths to SharePoint Online under MAM; the App
Protection Policy applies to them.
**Verify:** On a pilot device, the SharePoint app (publisher **Microsoft Corporation**, bundle ID
`com.microsoft.sharepoint` on iOS / package `com.microsoft.sharepoint` on Android) and Microsoft
Edge (bundle ID `com.microsoft.msedge` on iOS / package `com.microsoft.emmx` on Android) are
installed and can sign in to the work account.
**Implement:** Install the SharePoint app and Microsoft Edge from the App Store / managed Google
Play (optionally deploy them as Intune apps to the target group).

## 2.4 App Protection Policies for SharePoint app + protected browser
**Description:** App Protection Policies (APP / MAM) targeting the SharePoint app and Edge for both
iOS/iPadOS and Android, assigned to the target users.
**Why:** MAM data protection is the control CA will require; without it the app-protection grant can
never be satisfied and mobile sign-ins are blocked.
**Verify:** Intune → **Apps → App protection policies**; run `SPMAM-Discovery.ps1`.
**Implement:** Create them per Implementation Steps 2–3.

## 2.5 Conditional Access policy for Office 365 / SharePoint Online
**Description:** A CA policy scoped to Office 365 (which includes SharePoint Online) with the
`Require app protection policy` grant (and/or `Require approved client app`), targeting iOS and
Android.
**Why:** This is the gate that forces mobile users onto a protected app and blocks unmanaged
browsers.
**Verify:** Entra → **Protection → Conditional Access**; run `SPMAM-Discovery.ps1`.
**Implement:** Create it per Implementation Step 5 (start in **Report-only**).

## 2.6 Break-glass (emergency-access) accounts excluded from CA
**Description:** Two cloud-only emergency-access Global Administrator accounts excluded from every CA
policy.
**Why:** A CA misconfiguration must never lock every administrator out of the tenant.
**Verify:** Entra → **Users**; the two break-glass accounts exist and are excluded from the CA
policy.
**Implement:** Create them and exclude them (Implementation Step 1).

## 2.7 Confirm the resource is SharePoint Online (routing decision)
**Description:** Confirm the intranet is SharePoint Online (`*.sharepoint.com`), not an
on-premises / private web app.
**Why:** SharePoint Online is cloud-reachable and needs no VPN; a private resource needs Microsoft
Tunnel for MAM (a different solution). This decision changes the whole fix.
**Verify:** Open the intranet URL; confirm it resolves to your `*.sharepoint.com` tenant and loads
over the public internet on an off-network connection.
**Implement:** If the resource is actually private/on-prem, stop here and use the Microsoft Tunnel
for MAM solution instead.

---
## Checklist
- [ ] Intune + Entra ID P1 + SharePoint Online licensing assigned
- [ ] Target user group + pilot group created
- [ ] SharePoint app + Microsoft Edge installed on pilot devices
- [ ] App Protection Policies for SharePoint app + Edge (iOS + Android) — `SPMAM-Discovery.ps1`
- [ ] Conditional Access policy for Office 365 with app-protection grant — `SPMAM-Discovery.ps1`
- [ ] Two break-glass accounts excluded from CA
- [ ] Confirmed the intranet is SharePoint Online (no Tunnel needed)
