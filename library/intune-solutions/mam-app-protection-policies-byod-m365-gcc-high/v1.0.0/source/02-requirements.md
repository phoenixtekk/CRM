# 2. Requirements Guide — MAM App Protection Policies for BYOD (Government / GCC High)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> **Government note:** all portal/verify URLs below are the **US sovereign cloud** (`*.us`)
> endpoints. If a step sends you to a `*.com` portal, you are on the wrong cloud for a GCC High
> tenant.

## 2.1 GCC High tenant (separate US sovereign cloud)
**Description:** An active Microsoft 365 / Entra **GCC High** tenant (`*.onmicrosoft.us`).
**Why:** GCC High is a distinct sovereign cloud; it is not your Commercial or GCC tenant with a
different sign-in. Portals, endpoints, and some mobile-app features differ.
**Verify:** Sign in to **`https://intune.microsoft.us`** and **`https://entra.microsoft.us`** as an
administrator; the tenant domain ends in `.onmicrosoft.us`.
**Implement:** Provision a GCC High tenant through an authorized government/agreement path (a
separate tenant from any Commercial/GCC tenant you hold). [Microsoft — Intune Government service
overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service)

## 2.2 Government Intune + Entra ID P1 licensing
**Description:** An Intune-bearing plan **plus Microsoft Entra ID P1**, typically via **Microsoft
365 G3 / G5 (Government)**.
**Why:** Intune delivers App Protection / App Configuration policies; the Conditional Access "require
app protection policy" grant is an Entra ID P1 feature.
**Verify:** M365 admin center **`https://portal.office365.us`** → **Billing → Licenses** — confirm a
Government plan carrying Intune and Entra ID P1; each targeted user is licensed.
**Implement:** Assign M365 G3/G5 (Government) (or standalone Intune + Entra ID P1 Gov) to targeted BYOD users.

## 2.3 Administrative roles (sovereign portal access)
**Description:** **Intune Administrator** (for App Protection/Configuration policies) and, for the
enforcement grant, **Conditional Access Administrator**, plus the ability to open the `*.us` portals.
**Why:** Creating MAM policies and the CA grant requires the right roles; the operator must also
reach the sovereign portals through any filtering.
**Verify:** `https://entra.microsoft.us` → **Roles and administrators** — confirm **Intune
Administrator** (and **Conditional Access Administrator** for the grant).
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for break-glass and
tenant-wide changes.

## 2.4 Supported Microsoft 365 mobile apps (GCC High availability)
**Description:** The Microsoft 365 mobile apps to protect — Outlook, Teams, Word, Excel, PowerPoint,
OneDrive, SharePoint, Edge — installed from the platform app store on the BYOD device.
**Why:** App Protection Policies only apply to apps that support APP. Outlook for iOS/Android is
available for GCC High and DoD, but some Outlook "extras" (location services, Play My Emails, To Do)
are **not** FedRAMP-approved for US Gov.
**Verify:** Install Outlook/Teams on a test phone, sign in with a GCC High work account, and confirm
it connects. **Verify for GCC High** that each specific app/feature you rely on is available.
**Implement:** Direct users to the app store; unblock the apps in the tenant if blocked. [Outlook
for iOS/Android in the Government
cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud)

## 2.5 MAM broker app on the device
**Description:** The MAM broker each platform requires: **Company Portal** on Android, **Microsoft
Authenticator** on iOS.
**Why:** MAM-without-enrollment brokers policy through these apps. On Android the policy will not
apply until Company Portal is present (no enrollment — broker only).
**Verify:** On a test device, Company Portal (Android) / Authenticator (iOS) is installed and the
targeted app applied the policy (prompted for an app PIN).
**Implement:** Have users install the broker from the app store; in GCC High the Company Portal
service endpoint is **`portal.manage.microsoft.us`**. [MAM for unenrolled
devices](https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment)

## 2.6 Scope groups (Entra security groups)
**Description:** Two Entra security groups — a pilot and a production group for BYOD users.
**Why:** Policies are piloted, then expanded; assigning to groups (not users) lets new users inherit
protection.
**Verify:** `https://entra.microsoft.us` → **Groups** — the groups exist; or run
**`MAMAPPG-Set-ScopeTargeting.ps1`** (defaults to preview).
**Implement:** Create **`MAM Users - BYOD - Pilot`** and **`MAM Users - BYOD - Production`** (the
script can create them).

## 2.7 Break-glass exclusion (for the CA grant)
**Description:** Two cloud-only Global Administrator accounts excluded from the "require app
protection policy" CA policy.
**Why:** A misconfigured CA grant can lock users (or admins) out; break-glass accounts guarantee a
way back in.
**Verify:** `https://entra.microsoft.us` → **Users** — two dedicated emergency `.onmicrosoft.us`
accounts exist and are excluded from the CA policy.
**Implement:** Create two cloud-only Global Admins with long random passwords stored offline; exclude
them from the CA grant. (Delivered by the **Conditional Access Integration (GCC High)** solution.)

## 2.8 Conditional Access enforcement (companion)
**Description:** A Conditional Access "require app protection policy" grant in the GCC High tenant.
**Why:** App Protection Policies protect data, but only the CA grant makes a protected app **required**.
**Verify:** `https://entra.microsoft.us` → **Protection → Conditional Access** — a policy grants
"Require app protection policy"; or run **`MAMAPPG-Discovery.ps1`**.
**Implement:** Build it (Implementation Step 5) or deploy the **Conditional Access Integration (GCC
High)** solution. The CA grant is available in GCC High.

## 2.9 Network access to US Gov endpoints
**Description:** Outbound HTTPS to the GCC High service/admin endpoints through any proxy/firewall.
**Why:** Blocking `.us` domains breaks authentication, Graph, Company Portal brokering, and the admin
portals for a GCC High tenant.
**Verify:** From an admin workstation reach **`login.microsoftonline.us`**, **`graph.microsoft.us`**,
`intune.microsoft.us`, `entra.microsoft.us`, and `portal.manage.microsoft.us`.
**Implement:** Allow the published **GCC High URL & IP ranges** through filtering. [Microsoft — GCC
High
endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 2.10 Microsoft Graph PowerShell (US Gov) for the scripts
**Description:** Microsoft Graph PowerShell SDK, connected with **`-Environment USGov`**.
**Why:** The discovery/validation/report scripts must target `graph.microsoft.us`, not the
Commercial endpoint. A missing `-Environment USGov` connects to the wrong cloud and returns nothing
(or errors).
**Verify:** `Get-MgEnvironment` lists **USGov** (Graph `https://graph.microsoft.us`); run
**`MAMAPPG-Discovery.ps1`** and confirm it reports the USGov environment.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`, then always
`Connect-MgGraph -Environment USGov -Scopes 'DeviceManagementApps.Read.All'`. [Microsoft — Graph national cloud
deployments](https://learn.microsoft.com/en-us/graph/deployments)

---
## Checklist
- [ ] **GCC High tenant** (`.onmicrosoft.us`) — `intune.microsoft.us` loads
- [ ] Government Intune + Entra ID P1 licensing (M365 G3/G5) assigned to BYOD users
- [ ] Intune Administrator (+ Conditional Access Administrator) roles; sovereign portals reachable
- [ ] Supported M365 mobile apps available on the device (Outlook/Teams verified for GCC High)
- [ ] MAM broker present — Company Portal (Android) / Authenticator (iOS)
- [ ] Scope groups created (`MAM Users - BYOD - Pilot` / `- Production`) — `MAMAPPG-Set-ScopeTargeting.ps1`
- [ ] Two break-glass admins excluded from the CA grant
- [ ] CA "require app protection policy" grant in place (GCC High)
- [ ] `.us` endpoints allowed through filtering
- [ ] Graph PowerShell connects with **`-Environment USGov`** — `MAMAPPG-Discovery.ps1`
