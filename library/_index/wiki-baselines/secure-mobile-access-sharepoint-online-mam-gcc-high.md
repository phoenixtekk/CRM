# Secure Mobile Access to SharePoint Online under MAM (App Protection + Conditional Access) — Government (GCC High)

> **Version 1.0.0** · Category: Intune · Solution code: SPMAMG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

**White-label · Intune Solutions · US Sovereign Cloud (GCC High)**

Government staff want to open SharePoint sites and files from their phones — often on **personal
(BYO) devices** you cannot fully manage. The risk is not the reading; it is the **leaving**: a
document copied into a personal note-taking app, saved to a consumer cloud, or forwarded from an
unmanaged mail client. This solution lets people work from mobile **without enrolling the whole
device**, by wrapping SharePoint access in **Intune App Protection Policies (MAM/APP)** and gating
sign-in with **Conditional Access** so that only the approved, protected Microsoft mobile apps can
reach SharePoint Online — and corporate data cannot escape them.

This is the **Government (GCC High) edition**. A GCC High tenant is a **separate US sovereign cloud**.
It uses different admin portals (`intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`,
`portal.office365.us`), a different sign-in endpoint (`login.microsoftonline.us`), a different
Microsoft Graph endpoint (`graph.microsoft.us`, reached in PowerShell with
`Connect-MgGraph -Environment USGov`), and SharePoint tenants on **`*.sharepoint.us`** rather than
`*.sharepoint.com`. Some capabilities also lag, are limited, or are **absent** versus Commercial.
Running Commercial steps on a GCC High tenant sends you to the wrong URLs and to features that
silently do not exist. This package delivers the solution for the sovereign cloud with the **correct
portals and endpoints** and the **Commercial-vs-GCC-High parity gaps called out** at the step where
they matter.

## What you get
- A plain-language **Solution Overview** of how MAM + Conditional Access protect mobile SharePoint
  access, including an explicit **Commercial vs GCC High — what's different** section.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, on the `*.us`
  endpoints.
- An **Implementation Guide** of precise, click-by-click steps in the required order — on the GCC
  High portals, piloted in Report-only first, with parity caveats inline.
- Five **PowerShell scripts** (discovery, validation, reporting, safe remediation, and scope
  targeting) — all connecting to **US Gov Graph** (`-Environment USGov`).
- A **GCC High Parity Notes** reference plus **Testing** and **Troubleshooting** guides for a
  confident, lockout-free rollout.

## What this delivers
A working, enforced posture on GCC High: staff open SharePoint Online **only** in the approved
Microsoft mobile apps (**SharePoint**, **OneDrive**, **Office/Microsoft 365**, **Edge**, **Teams**,
**Outlook**), those apps carry an **App Protection Policy** (PIN, encryption, block copy/paste and
"Save As" to unmanaged locations, selective wipe), and **Conditional Access requires the app
protection policy** before SharePoint will serve data on iOS or Android — piloted in Report-only
mode before enforcement, with break-glass accounts excluded, and GCC-High-specific gaps (e.g.
SharePoint's **Graph-dependent mobile features are disabled in GCC High**) handled up front.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Secure mobile access to SharePoint Online under MAM deployed **correctly on GCC High** — right
portals, right endpoints, parity gaps handled — so staff stay productive on their phones while
corporate data cannot leak out of the managed apps, proven on a pilot before you scale.


---


# 1. Solution Overview — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

## The problem
Users expect to reach SharePoint Online sites and documents from their phones and tablets. In
government, many of those devices are **personal / BYO** — you cannot (and often should not) fully
enroll them into device management. The exposure is data **leaving** the sanctioned apps: content
copied into a personal note app, "Save As" to a consumer cloud, screenshots, or an unmanaged mail
client attaching a work file. You need mobile access **without** managing the whole device, and you
need corporate data to stay inside apps you control.

## The solution
This solution uses two Microsoft technologies together:

1. **Intune App Protection Policies (App Protection Policy / APP — commonly "MAM")** — a policy that
   is applied to the **app**, not the device. It requires a PIN, encrypts app data, blocks
   copy/paste and "Save As" out of managed apps, and lets you **selectively wipe** just the
   corporate data. It works on unenrolled (BYO) devices.
2. **Conditional Access (CA)** — the sign-in gate. A CA policy scoped to **Office 365 / SharePoint
   Online** and to **iOS/Android** requires **app protection policy** before the service will return
   data. The result: SharePoint Online can only be opened in the **approved Microsoft mobile apps**
   that support App Protection Policies — the mobile browser and unmanaged apps are blocked or
   limited.

The **supported mobile access path** is the Microsoft mobile apps that honor App Protection Policies
— **SharePoint**, **OneDrive**, **Microsoft 365 (Office)**, **Microsoft Edge**, **Teams**, and
**Outlook**. Browsing SharePoint from a mobile browser is constrained by the CA policy; where browser
access is needed, it is routed through **managed Microsoft Edge** so protection still applies.
([Intune — App Protection Policies overview](https://learn.microsoft.com/en-us/intune/app-management/protection/overview),
[Entra — Require app protection policy](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-approved-app-or-app-protection))

## How it works (the flow)
1. User installs the **SharePoint** (or OneDrive / Office / Edge / Teams) mobile app and signs in
   with their **GCC High work account** (`login.microsoftonline.us`).
2. Sign-in hits a **Conditional Access** policy that, for iOS/Android against Office 365, **requires
   app protection policy**.
3. Intune delivers the **App Protection Policy** to the app; the app enforces PIN, encryption, and
   data-transfer restrictions.
4. SharePoint Online serves data **only inside** the protected app. Attempts to move data to
   unmanaged apps are blocked per policy. If the user leaves or the device is lost, a **selective
   wipe** removes only corporate data.

## Commercial vs GCC High — what's different
This edition is authored for a **GCC High** tenant. The differences are not cosmetic — using
Commercial steps points you at URLs and features that do not exist in the sovereign cloud.

| Area | Commercial | GCC High |
|---|---|---|
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Sign-in / auth endpoint | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` (`Connect-MgGraph -Environment USGov`) |
| SharePoint tenant URLs | `*.sharepoint.com` | `*.sharepoint.us` |

Feature parity gaps that matter for this solution (all cited in **GCC High Parity Notes**):

- **SharePoint mobile apps are supported** in GCC High/DoD, **but Graph-dependent SharePoint Online
  features are currently disabled in GCC High** — anything that relies on Microsoft Graph inside
  SharePoint (some rollups, activity notifications, stock images, Internet-service web parts) will
  not behave as in Commercial.
  ([SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint))
- **Mobile apps must resolve the GCC High cloud instance** — only the user's government account can
  be added; personal accounts are blocked, and some in-app cloud features are FedRAMP-restricted.
  ([Outlook for iOS/Android in the government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud))
- **"Require approved client app"** is **retiring (early March 2026)** — new CA policies must use
  **"Require app protection policy."** This solution uses the app-protection-policy control
  throughout. ([Entra — migrate approved client app](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app))
- **App Protection Policies, Conditional Access, and MFA are available in GCC High** — the core
  building blocks of this solution are present in the sovereign cloud.
  ([Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability))

> Where Microsoft does not publish a definitive GCC-High statement, the guide flags it **"verify for
> GCC High"** and tells you to pilot in Report-only before depending on it. Nothing here is invented.

## Benefits
- **Data stays in managed apps** — copy/paste, "Save As", and backup out of SharePoint content are
  blocked on unmanaged targets.
- **No device enrollment required** — protection is applied at the app layer, ideal for BYO.
- **Selective wipe** — remove corporate data without touching the user's personal device.
- **Sovereign-correct** — every portal, endpoint, and app instance is the GCC High one.

## Limitations / scope
- This solution secures **mobile** (iOS/Android) access to **SharePoint Online**; desktop and
  fully-managed device scenarios are covered by companion solutions.
- App Protection Policies protect data **inside** supported Microsoft apps; they do not stop a user
  from photographing the screen with a second device.
- GCC High **feature lag** applies — a capability demoed on Commercial may not yet be live in your
  tenant. Verify in `intune.microsoft.us` / `entra.microsoft.us` before designing around it.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.** Every step below is built on this model, with a
gate between each phase.


---


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


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

This guide gives **exact, ordered, click-by-click steps** on the **GCC High** portals. It follows the
standard model — **Assess → Configure → Pilot → Validate → Expand** — with a **gate** between phases.
Do not skip the gates.

> **Before you start — you are in the sovereign cloud.** Sign in with your **GCC High** admin account
> at `login.microsoftonline.us`. The Intune portal is **`https://intune.microsoft.us`** and the Entra
> portal is **`https://entra.microsoft.us`**. If a URL ends in `.com`, stop — you are in Commercial.

**Named objects created in this guide (reuse these exact names):**
- App Protection Policy (iOS): **`APP-SPO-iOS-Enterprise`**
- App Protection Policy (Android): **`APP-SPO-Android-Enterprise`**
- Conditional Access policy: **`CA-SPO-Mobile-Require-App-Protection`**
- Pilot group (from R5): **`SG-SPMAMG-Pilot`**
- Break-glass exclusion group (from R4): **`SG-BreakGlass-Exclude`**

---

## Phase 1 — Assess (gate: R1–R8 pass)
1. Confirm requirements R1–R8 in **Requirements Guide** are all green.
2. Run **`SPMAMG-Discovery.ps1`** (connects to **`graph.microsoft.us`** via `-Environment USGov`).
   Save the output — it lists existing App Protection Policies and Conditional Access policies so you
   don't collide with an existing configuration.
3. On a test iOS and a test Android device, install the **SharePoint** app, sign in with a GCC High
   account, and confirm your `*.sharepoint.us` site loads. This proves the mobile app resolves the
   **government cloud** (R6) before you add policy.

**Gate:** all requirements pass and a baseline SharePoint mobile sign-in works. Proceed.

---

## Phase 2 — Configure

### Step 2.1 — Create the iOS App Protection Policy (`APP-SPO-iOS-Enterprise`)
1. Go to **`https://intune.microsoft.us`** → **Apps** → **App protection policies**.
2. Click **+ Create policy** → **iOS/iPadOS**.
3. **Basics** — Name: **`APP-SPO-iOS-Enterprise`**. Description: "Protects SharePoint/OneDrive/Office
   data on iOS (BYO) — GCC High." Click **Next**.
4. **Apps** — **Target policy to**: **Selected apps**. Add the supported public apps:
   **Microsoft SharePoint**, **Microsoft OneDrive**, **Microsoft 365 (Office)**, **Microsoft Edge**,
   **Microsoft Teams**, **Microsoft Outlook**. Click **Next**.
5. **Data protection** — set an **Enterprise (Level 2)** baseline
   ([Data protection framework](https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework)):
   - **Backup org data to iTunes and iCloud backups:** **Block**
   - **Send org data to other apps:** **Policy managed apps** (blocks copy/"Save As" to unmanaged
     apps)
   - **Save copies of org data:** **Block** — under **Allow user to save copies to selected
     services**, leave only **OneDrive for Business** / **SharePoint** if your policy permits.
   - **Receive data from other apps:** **Policy managed apps**
   - **Restrict cut, copy, and paste between other apps:** **Policy managed apps with paste in**
   - **Screen capture and Google Assistant** (Android equivalent) / **Third-party keyboards:** set
     per your risk posture.
   - **Encrypt org data:** **Require**
   - Click **Next**.
6. **Access requirements** — **PIN for access: Require**; **Work or school account credentials for
   access: Require**; **Recheck the access requirements after (minutes of inactivity): 30**. Click
   **Next**.
7. **Conditional launch** — keep the defaults (e.g. **Max PIN attempts → Reset PIN**, **Jailbroken/
   rooted devices → Block access**, **Offline grace period → Wipe data**). Click **Next**.
8. **Assignments** — **Included groups**: **`SG-SPMAMG-Pilot`**. **Excluded groups**:
   **`SG-BreakGlass-Exclude`**. Click **Next** → **Create**.

### Step 2.2 — Create the Android App Protection Policy (`APP-SPO-Android-Enterprise`)
Repeat Step 2.1 choosing **Android** at **+ Create policy**. Name it **`APP-SPO-Android-Enterprise`**,
target the same apps, apply the same Level 2 data-protection settings, and assign to
**`SG-SPMAMG-Pilot`** (exclude **`SG-BreakGlass-Exclude`**).

> **GCC High caveat:** target the **government-cloud** versions of the apps that resolve
> `*.sharepoint.us`. Personal accounts cannot be added to these apps in GCC High, and
> **Graph-dependent SharePoint mobile features are disabled** — see **GCC High Parity Notes**.

### Step 2.3 — Create the Conditional Access policy (`CA-SPO-Mobile-Require-App-Protection`)
1. Go to **`https://entra.microsoft.us`** → **Protection** → **Conditional Access** → **Policies**.
2. Click **+ New policy**. **Name:** **`CA-SPO-Mobile-Require-App-Protection`**.
3. **Users** — **Include**: **`SG-SPMAMG-Pilot`**. **Exclude**: **`SG-BreakGlass-Exclude`** (always).
4. **Target resources** — **Cloud apps → Include → Select apps → Office 365** (this covers SharePoint
   Online). *(If you prefer, select **SharePoint Online** specifically.)*
5. **Conditions → Device platforms** — **Include** → **Select device platforms** → **iOS** and
   **Android** only.
6. **Conditions → Client apps** — **Configure: Yes** → select **Mobile apps and desktop clients**
   (and, if you want to steer browsers, **Browser** — combined with the Edge routing note below).
7. **Grant** — **Grant access** → check **Require app protection policy**. If you also selected
   Browser, add **Require approved client app OR app protection policy** only as a temporary bridge —
   **note:** *"Require approved client app" is retiring in early March 2026; use "Require app
   protection policy" going forward.*
   ([Entra — migrate approved client app](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app))
   For **multiple controls**, choose **Require one of the selected controls** only if you intentionally
   allow either; otherwise **Require all**.
8. **Enable policy** — set to **Report-only** (not On). Click **Create**.

**Gate:** iOS + Android App Protection Policies created and assigned to the pilot; the CA policy
exists in **Report-only**. Proceed to Pilot.

---

## Phase 3 — Pilot
1. On the pilot devices (already carrying Authenticator on iOS / Company Portal on Android per R7),
   open the **SharePoint** app and sign in with a **`SG-SPMAMG-Pilot`** account.
2. The app should prompt to **set an app PIN** (App Protection Policy applied). Open a `*.sharepoint.us`
   site and a document.
3. Test data-leak prevention: try to **copy** text from a SharePoint doc into a personal note app
   (should be blocked), and try **"Save a copy"** to a consumer cloud (should be blocked/limited).
4. Watch enforcement without risk: in **`entra.microsoft.us`** → **Conditional Access** →
   **`CA-SPO-Mobile-Require-App-Protection`** → **Report-only**, review that the pilot sign-ins would
   be **satisfied** by the app-protection control (use the **What If** tool and **Sign-in logs →
   Report-only** tab).

**Gate:** pilot users can work in the protected apps, data-leak controls fire, and Report-only shows
the CA control being **satisfied** (not blocking legitimate sign-ins). Proceed to Validate.

---

## Phase 4 — Validate
1. Run **`SPMAMG-Validation.ps1`** (US Gov Graph). It confirms: the two App Protection Policies exist
   and target the supported apps, the CA policy scopes iOS/Android + Office 365 with **Require app
   protection policy**, and **break-glass accounts are excluded** from the CA policy.
2. Run **`SPMAMG-Report.ps1`** to produce a summary of policies + recent mobile sign-in results
   (Report-only outcomes) for your change record.
3. Confirm the **negative test**: on a device **without** the app protection policy (or in a mobile
   browser outside managed Edge), SharePoint access is blocked/limited as designed once the policy is
   enforced.

**Gate:** validation script is clean and negative test behaves as designed. Proceed to Expand.

---

## Phase 5 — Expand
1. Flip **`CA-SPO-Mobile-Require-App-Protection`** from **Report-only** to **On** (start with the
   pilot group still, then widen).
2. Widen scope with **`SPMAMG-Set-ScopeTargeting.ps1`** (defaults to **`-WhatIf`** — review the plan,
   then re-run with `-Confirm` to apply). Add production groups to the **Include** of both App
   Protection Policies **and** the CA policy; keep **`SG-BreakGlass-Exclude`** excluded.
3. Communicate to users that SharePoint on mobile now requires the approved Microsoft apps + an app
   PIN.
4. Re-run **`SPMAMG-Report.ps1`** after each wave to confirm healthy enforcement and no unexpected
   blocks.

> **If anything locks out or misbehaves:** set the CA policy back to **Report-only** (or **Off**),
> use a **break-glass** account to sign in, and see **Troubleshooting**. `SPMAMG-Remediation.ps1`
> (defaults to **`-WhatIf`**) can re-assert break-glass exclusion and revert the CA policy to
> Report-only.

---
### Cited references
- App Protection Policies overview — https://learn.microsoft.com/en-us/intune/app-management/protection/overview
- Data protection framework — https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework
- App-based Conditional Access with Intune — https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/app-based-policies
- Require app protection policy (CA) — https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-approved-app-or-app-protection
- Migrate approved client app → app protection policy — https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app
- SharePoint for US government environments — https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint
- GCC High endpoints — https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints


---


# 5. Testing Guide — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

Every test has an explicit **pass/fail gate**. Run these on the **GCC High** portals
(`intune.microsoft.us`, `entra.microsoft.us`) and on real iOS/Android test devices signed in with
`login.microsoftonline.us`. Where a script is named, it connects to **US Gov Graph**
(`-Environment USGov`).

## T0. Sovereign-cloud check (do this first)
**Steps:** Confirm you are administering the correct cloud.
**Pass:** Portals are `*.us`; the SharePoint test site is `https://<tenant>.sharepoint.us`;
`SPMAMG-Discovery.ps1` reports it connected to **`graph.microsoft.us`**.
**Fail:** Any `.com` portal or `graph.microsoft.com` — you are in Commercial; stop and switch.

## T1. App Protection Policies exist and target the right apps
**Steps:** `intune.microsoft.us` → **Apps → App protection policies**. Confirm
**`APP-SPO-iOS-Enterprise`** and **`APP-SPO-Android-Enterprise`** exist and target SharePoint,
OneDrive, Office/M365, Edge, Teams, Outlook.
**Pass:** Both policies present, correct apps, assigned to **`SG-SPMAMG-Pilot`**, excluding
**`SG-BreakGlass-Exclude`**. `SPMAMG-Validation.ps1` confirms.
**Fail:** Missing policy, wrong app list, or missing exclusion.

## T2. App PIN is enforced on the device
**Steps:** On a pilot iOS and Android device, open the **SharePoint** app signed in as a pilot user.
**Pass:** The app prompts to **set/enter an app PIN** and encrypts data.
**Fail:** No PIN prompt — policy not applied (check assignment, license, and that the app is the
government-cloud instance).

## T3. Data-leak prevention fires
**Steps:** Open a document in the SharePoint app. Attempt to (a) copy text into a personal note app,
(b) "Save a copy" to a consumer cloud, (c) open in an unmanaged app.
**Pass:** All three are **blocked or restricted** to policy-managed apps.
**Fail:** Data moves freely to unmanaged apps — re-check **Data protection** settings in the APP.

## T4. Conditional Access requires app protection (Report-only)
**Steps:** `entra.microsoft.us` → **Conditional Access** → **`CA-SPO-Mobile-Require-App-Protection`**.
Use **What If** for a pilot user on iOS against Office 365; review **Sign-in logs → Report-only**.
**Pass:** The policy **applies** and the **Require app protection policy** control is **satisfied**
for the protected app.
**Fail:** Policy not applied to mobile/Office 365, or control not evaluated — re-check Users, Target
resources, Device platforms, Client apps.

## T5. Negative test — unprotected access is blocked
**Steps:** After enforcing the CA policy (**On**), try SharePoint from a mobile **browser** outside
managed Edge, or from an app without the app protection policy.
**Pass:** Access is **blocked or limited** as designed.
**Fail:** Unprotected access still returns data — CA policy scope/grant is wrong.

## T6. Break-glass exclusion verified
**Steps:** Run `SPMAMG-Validation.ps1`; also confirm in the CA policy's **Exclude** list.
**Pass:** **`SG-BreakGlass-Exclude`** is excluded from **`CA-SPO-Mobile-Require-App-Protection`**.
**Fail:** Break-glass not excluded — fix immediately (a bad policy could otherwise lock everyone out).

## T7. Selective wipe works
**Steps:** In `intune.microsoft.us` → **Apps → App selective wipe**, issue a wipe for a pilot user's
device.
**Pass:** Corporate data is removed from the managed apps; the user's personal data is untouched.
**Fail:** Wipe not delivered — check the user has checked in recently and the device is reachable.

## T8. GCC High parity behavior confirmed
**Steps:** In the SharePoint mobile app, confirm the **known GCC High limitations** (Graph-dependent
features such as certain rollups/notifications) behave as documented, not as Commercial.
**Pass:** Behavior matches **GCC High Parity Notes**; no reliance on a feature that is disabled in GCC
High.
**Fail:** A workflow depends on a Graph-dependent SharePoint feature that is disabled in GCC High —
redesign per parity notes.

---
**Overall gate:** T0–T8 all **pass** before declaring the rollout validated. Capture
`SPMAMG-Report.ps1` output as evidence for your change record.


---


# 6. Troubleshooting Guide — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

Field issues, lockout recovery, and **GCC-High-specific gotchas**. Work top-down. All portals are
`*.us`; all scripts connect to **US Gov Graph** (`-Environment USGov`).

## First, rule out the wrong-cloud mistake
**Symptom:** Portal blades look different, a policy "disappears," or PowerShell shows no policies.
**Cause:** You're in the Commercial cloud (`.com`) instead of GCC High.
**Fix:** Confirm you signed in at `login.microsoftonline.us`; use `intune.microsoft.us` /
`entra.microsoft.us`; ensure scripts print **`graph.microsoft.us`**. Re-run `SPMAMG-Discovery.ps1`
and check the endpoint line.

## Lockout / access-blocked recovery (do this before anything drastic)
**Symptom:** Users (or admins) can't sign in to SharePoint on mobile after enforcing CA.
**Fix:**
1. Sign in with a **break-glass** account (excluded from all CA — R4).
2. `entra.microsoft.us` → **Conditional Access** → **`CA-SPO-Mobile-Require-App-Protection`** → set
   to **Report-only** (or **Off**).
3. Run `SPMAMG-Remediation.ps1` (defaults to **`-WhatIf`**) to re-assert break-glass exclusion and
   revert the policy to Report-only; re-run with `-Confirm` to apply.
4. Diagnose with **Sign-in logs** before re-enforcing.

## App PIN never prompts / App Protection Policy not applied
**Symptom:** SharePoint app opens with no PIN, no encryption.
**Checks:**
- User is in **`SG-SPMAMG-Pilot`** and has an **Intune** license (R2).
- The app is the **government-cloud** instance signed in with the GCC High account (personal accounts
  are blocked in GCC High).
- `intune.microsoft.us` → **Apps → Monitor → App protection status** shows the user as targeted.
- Allow time / force an app check-in; App Protection Policy applies on next app launch after sign-in.

## Conditional Access not applying to mobile
**Symptom:** Report-only shows the policy **not applied** for mobile SharePoint sign-ins.
**Checks:**
- **Target resources** includes **Office 365** (or SharePoint Online specifically).
- **Conditions → Device platforms** includes **iOS** and **Android**.
- **Conditions → Client apps** includes **Mobile apps and desktop clients** (and **Browser** if you
  intend to gate the browser).
- **Grant** has **Require app protection policy** checked.
- The user is in **Include** and not accidentally in **Exclude**.

## "Require approved client app" behaving oddly / deprecation
**Symptom:** A legacy policy using **Require approved client app** blocks or is flagged as deprecated.
**Cause:** That grant is **retiring early March 2026**.
**Fix:** Rebuild on **Require app protection policy** (this solution's default).
[Migrate approved client app](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app)

## Data still leaks to unmanaged apps
**Symptom:** Copy/paste or "Save As" out of SharePoint content succeeds.
**Checks (App Protection Policy → Data protection):**
- **Send org data to other apps:** **Policy managed apps**.
- **Save copies of org data:** **Block** (allow only OneDrive/SharePoint if intended).
- **Restrict cut/copy/paste:** **Policy managed apps with paste in**.
- Confirm the target app is **not** itself a policy-managed app you inadvertently allowed.

## Broker app / registration failures
**Symptom:** The app can't satisfy the CA control; sign-in loops.
**Checks:** **Microsoft Authenticator** (iOS) or **Intune Company Portal** (Android) is installed and
signed in with the GCC High account (R7). Reinstall the broker app and retry.
[App-based Conditional Access with Intune](https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/app-based-policies)

## GCC-High-specific gotchas
- **SharePoint mobile feature missing entirely.** If a rollup, activity notification, stock-images
  tab, or Internet-service web part doesn't work, that is **expected** — Graph-dependent SharePoint
  features are **disabled in GCC High**. Don't chase it as a policy bug; redesign the site per
  **GCC High Parity Notes**.
  ([SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint))
- **User tries to add a personal account.** Blocked by design in GCC High — communicate this; it is
  not a fault.
  ([Outlook for iOS/Android in the government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud))
- **Site or sign-in unreachable from mobile.** Confirm the **GCC High endpoint ranges** (`*.us`
  SharePoint/Entra/Intune) are allowed through your MDM/proxy/firewall — Commercial ranges won't
  cover them.
  ([GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints))
- **A capability from a Commercial article is absent.** GCC High lags Commercial. **Verify for GCC
  High** in `intune.microsoft.us` / `entra.microsoft.us`; if the option isn't there, it isn't
  released yet.

## When to escalate
- Break-glass access itself fails → this is a tenant-level identity incident; engage Microsoft
  support for GCC High immediately.
- App Protection status shows the user targeted but the app never enforces after repeated check-ins →
  collect app logs (Settings → Help → Share Diagnostic Logs) and open a support case.

---
**Golden rule:** if enforcement misbehaves, **fall back to Report-only, sign in with break-glass,
diagnose with sign-in logs, then re-enforce.** Never leave a broken enforcing policy live.


---


# 7. Best Practices — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

Field-proven recommendations for running this solution on the **US sovereign cloud**.

## Sovereign-cloud discipline
- **Bookmark the `*.us` portals** (`intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`,
  `portal.office365.us`) and remove Commercial bookmarks from admin machines to avoid cross-cloud
  mistakes.
- **Always connect PowerShell with `-Environment USGov`** so Graph targets `graph.microsoft.us`.
  Every script in this package does this and prints the endpoint it reached — verify it before
  trusting output.
- **Never assume Commercial parity.** GCC High receives features later and some are absent. If a
  capability isn't on a Microsoft US Gov page, treat it as **"verify for GCC High"** and pilot in
  Report-only.

## Policy design
- **Use "Require app protection policy," not "Require approved client app."** The approved-client-app
  control is retiring (early March 2026); build new policies on app protection policy.
  ([Migrate approved client app](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app))
- **Target users, not devices, for MAM.** App Protection Policies apply to users and work on BYO /
  unenrolled devices — that is the whole point of the mobile scenario.
- **Standardize on the Enterprise (Level 2) data-protection baseline** and only deviate with a
  documented reason. ([Data protection framework](https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework))
- **Route mobile browser access through managed Edge** so protection still applies where a browser is
  genuinely needed; otherwise keep users in the SharePoint/OneDrive/Office apps.
- **Keep the app list consistent across iOS and Android** so the user experience and the security
  posture match on both platforms.

## Safety and rollout
- **Report-only first, always.** Never publish an enforcing CA policy without observing it in
  Report-only against the pilot.
- **Two break-glass accounts, excluded from every CA policy**, checked on every change. The
  validation script verifies this — run it after each edit.
- **Assess → Configure → Pilot → Validate → Expand**, with the gate at each step. Widen scope in
  waves using `SPMAMG-Set-ScopeTargeting.ps1` (defaults to `-WhatIf` — review before applying).
- **Change on `-WhatIf` by default.** Remediation and scope-targeting scripts preview their actions;
  apply only after you've read the plan.

## GCC High specifics to plan around
- **Graph-dependent SharePoint mobile features are disabled in GCC High.** Do not design user
  workflows around notifications, activity rollups, stock images, or Internet-service web parts on
  mobile. ([SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint))
- **Only the government account can be added** to the mobile apps; some in-app cloud features are
  FedRAMP-restricted by default. Communicate this to users so they don't try to add personal
  accounts. ([Outlook for iOS/Android in the government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud))
- **Allow the GCC High endpoint ranges** through your MDM/proxy/firewall — the `*.us` SharePoint,
  Entra, and Intune URLs, which differ from Commercial. ([GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints))

## Operations
- **Re-run `SPMAMG-Report.ps1` after every expansion wave** and keep the output as change evidence.
- **Review App Protection Policy status** monthly (`intune.microsoft.us` → **Apps → Monitor → App
  protection status**) to catch users who never received policy.
- **Practice selective wipe** on a test account so the help desk can execute it confidently when a
  device is lost or a user offboards.


---


# 8. Deliverables Summary — Secure Mobile Access to SharePoint Online under MAM (Government / GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (Government edition) |
| 1. Solution Overview | What MAM + Conditional Access do for mobile SharePoint access, **Commercial vs GCC High — what's different**, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, on the `*.us` sovereign endpoints |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps on the GCC High portals — Report-only first, break-glass safety, parity caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a sovereign-cloud check |
| 6. Troubleshooting Guide | Field issues, lockout recovery, and GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for the sovereign cloud |
| GCC High Parity Notes | Cited reference of Commercial-vs-GCC-High capability gaps |

## PowerShell scripts (all connect to US Gov Graph — `-Environment USGov`)
| Script | What it does |
|---|---|
| `SPMAMG-Discovery.ps1` | Confirms the US Gov Graph environment and inventories current App Protection Policies + Conditional Access policies before you change anything (read-only) |
| `SPMAMG-Validation.ps1` | Confirms the iOS/Android App Protection Policies target the supported apps, the CA policy requires app protection for mobile Office 365, and break-glass accounts are excluded (read-only) |
| `SPMAMG-Report.ps1` | Summarizes App Protection Policies, the CA policy, and recent mobile sign-in results for the change record (read-only, US Gov Graph) |
| `SPMAMG-Remediation.ps1` | Safe fixes — re-asserts break-glass exclusion and reverts a runaway CA policy to Report-only; **defaults to `-WhatIf`** |
| `SPMAMG-Set-ScopeTargeting.ps1` | Builds pilot→production scope (include/exclude groups) on the App Protection Policies and CA policy; **defaults to `-WhatIf`** |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP, all targeting **`graph.microsoft.us`**.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Secure mobile access to SharePoint Online under MAM deployed **correctly on GCC High** — right
portals, right endpoints, parity gaps handled — so staff work from their phones in the approved,
protected Microsoft apps while corporate data cannot leak to unmanaged apps, proven on a pilot before
scale, with break-glass accounts and Report-only piloting preventing lockouts.
