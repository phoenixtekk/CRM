# 2. Requirements Guide — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

Confirm each requirement **before** you configure anything. The **Global Requirements (Intune
Solutions)** document covers the category-wide basics (tenant, Intune subscription, admin roles,
pilot group, network access) — this guide adds the requirements **specific to this solution on GCC
High**. Each entry: **Description · Why · Verify · Implement-if-missing**, on the `*.us` sovereign
endpoints.

> **Sovereign-cloud reminder:** every portal below is a **`*.us`** URL. If you land on a `.com`
> portal you are in the wrong cloud. Sign in with your **GCC High** admin account at
> `login.microsoftonline.us`.

## R1. GCC High tenant (not Commercial / not GCC Moderate)
**Description:** An active Microsoft 365 **GCC High** tenant with SharePoint Online provisioned.
**Why:** This edition's portals, endpoints, and app cloud instances only apply to GCC High.
**Verify:** Sign in to `https://portal.office365.us`; your SharePoint sites resolve at
`https://<tenant>.sharepoint.us`.
**Implement:** Provision through a Microsoft GCC High agreement; this is not a setting you toggle on a
Commercial tenant.

## R2. US Gov licensing that includes Intune App Protection + Entra P1
**Description:** Licensing that provides **Intune** (App Protection Policies) and **Entra ID P1**
(Conditional Access) for targeted users — e.g. **Microsoft 365 G3/G5 (Gov)** or **EMS G3/G5 (Gov)**.
**Why:** App Protection Policies require an Intune license; Conditional Access requires Entra ID P1.
**Verify:** `https://portal.office365.us` → **Billing → Licenses**; confirm an Intune-bearing and
Entra P1-bearing plan is assigned to pilot users.
**Implement:** Assign M365 G3/G5 Gov (or EMS G3/G5 Gov + a SharePoint plan) to the pilot group.
[Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)

## R3. Administrative roles (Intune + Conditional Access)
**Description:** Roles that permit creating App Protection Policies and Conditional Access policies.
**Why:** APP creation needs **Intune Administrator**; CA policy creation needs **Conditional Access
Administrator** (or Security Administrator).
**Verify:** `https://entra.microsoft.us` → **Roles and administrators**; confirm the operator holds
**Intune Administrator** and **Conditional Access Administrator**.
**Implement:** Assign those roles; reserve **Global Administrator** for tenant-wide changes only.

## R4. Break-glass (emergency access) accounts excluded from CA
**Description:** At least two cloud-only emergency-access accounts, **excluded from all Conditional
Access policies**.
**Why:** A misconfigured CA policy can lock everyone out; break-glass accounts are the recovery path.
**Verify:** `https://entra.microsoft.us` → **Protection → Conditional Access**; confirm your
break-glass group is in **Exclude** on every policy.
**Implement:** Create two cloud-only accounts, place them in a dedicated group, and exclude that
group from CA. (Script `SPMAMG-Validation.ps1` checks this.)

## R5. Pilot security group (users, not devices)
**Description:** An Entra **security group of pilot users** for MAM (App Protection targets **users**).
**Why:** Every rollout is piloted before fleet expansion; App Protection Policies and the CA policy
are assigned to this group first.
**Verify:** `https://entra.microsoft.us` → **Groups**; the pilot group exists and contains test users.
**Implement:** **Groups → New group → Security**, add pilot members. (Script
`SPMAMG-Set-ScopeTargeting.ps1` can build the include/exclude scope.)

## R6. Supported Microsoft mobile apps available for GCC High
**Description:** The **SharePoint**, **OneDrive**, **Microsoft 365 (Office)**, **Edge**, **Teams**,
and **Outlook** mobile apps, able to sign in to the **GCC High** cloud instance.
**Why:** These are the App-Protection-Policy-aware apps that form the supported mobile access path;
they must resolve the government cloud, not Commercial.
**Verify:** On a test iOS/Android device, install the **SharePoint** app, sign in with a GCC High
account, and confirm your `*.sharepoint.us` sites load. Only the government account can be added.
**Implement:** Distribute via Company Portal or the public app stores; confirm accounts resolve to
GCC High. Note: **Graph-dependent SharePoint mobile features are disabled in GCC High** (see parity
notes). [SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint)
· [Outlook for iOS/Android in the government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud)

## R7. Broker app for app-based Conditional Access
**Description:** **Microsoft Authenticator** on **iOS** and **Intune Company Portal** on **Android**
installed on pilot devices.
**Why:** App-based CA uses a broker app to register the app/device with Entra; without it, the
protected apps cannot satisfy the CA control.
**Verify:** On the test device, Authenticator (iOS) / Company Portal (Android) is installed and the
work account is added.
**Implement:** Install from the store; sign in with the GCC High account.
[App-based Conditional Access with Intune](https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/app-based-policies)

## R8. Network access to GCC High endpoints (allow-list)
**Description:** Mobile devices can reach the **GCC High** service endpoints through any filtering.
**Why:** Sign-in, policy sync, and SharePoint data all use `*.us` endpoints that differ from
Commercial.
**Verify:** From a test device, reach `https://login.microsoftonline.us` and your
`https://<tenant>.sharepoint.us`.
**Implement:** Allow the **Office 365 U.S. Government GCC High** published URL/IP ranges (SharePoint
Online & OneDrive, Entra/auth, Intune) through proxy/MDM/firewall.
[GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

---
**Requirements gate (Assess):** do not proceed to **Configure** until R1–R8 pass. Run
`SPMAMG-Discovery.ps1` (US Gov Graph) to capture the current App Protection Policy and CA inventory
before you change anything.
