# Mobile Application Management (MAM) App Protection Policies for BYOD (Microsoft 365 Apps) — Government (GCC High)

> **Version 1.0.0** · Category: Intune · Solution code: MAMAPPG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — MAM App Protection Policies for BYOD (Microsoft 365 Apps) — Government / GCC High

**White-label · Intune Solutions · US Sovereign Cloud (GCC High)**

Government employees want Outlook, Teams, Word, and OneDrive on their own phones — and the mission
needs that corporate data protected. Enrolling personal devices into full mobile device management
(MDM) is intrusive, slows adoption, and raises privacy concerns. Mobile Application Management (MAM)
with App Protection Policies solves this: it protects corporate data inside the Microsoft 365 apps —
encryption, cut/copy/paste and save-as limits, an app PIN, jailbreak/root blocking, and selective
wipe of corporate data only — on unenrolled, personal devices, without touching the rest of the phone.

This is the **Government (GCC High) edition**. A GCC High tenant is a **separate US sovereign cloud**
— it uses different admin portals (`intune.microsoft.us`, `entra.microsoft.us`, `portal.office365.us`),
a different sign-in endpoint (`login.microsoftonline.us`), a different Company Portal service endpoint
(`portal.manage.microsoft.us`), and a different Microsoft Graph endpoint (`graph.microsoft.us`,
reached in PowerShell with `Connect-MgGraph -Environment USGov`). Some capabilities also lag, are
limited, or are **absent** versus Commercial. Running Commercial steps on a GCC High tenant sends you
to the wrong URLs and to features that silently do not exist. This package delivers App Protection
Policies for BYOD on the sovereign cloud with the **correct portals and endpoints** and the
**Commercial-vs-GCC-High parity gaps called out** at the step where they matter.

## What you get
- A plain-language **Solution Overview** of MAM-without-enrollment, the data-protection controls, app
  configuration, and how Conditional Access enforces "require app protection policy" — including an
  explicit **Commercial vs GCC High — what's different** section.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, on the `*.us`
  endpoints.
- An **Implementation Guide** of precise, click-by-click Intune and Entra steps in the required order
  — on the GCC High portals, with parity caveats inline.
- Five **PowerShell scripts** (discovery, per-user validation, coverage/enforcement report, safe
  remediation, and a scope-group builder) — all connecting to **US Gov Graph** (`-Environment USGov`).
- A **GCC High Parity Notes** reference plus **Testing** and **Troubleshooting** guides for a
  confident rollout.

## What this delivers
App Protection Policies for iOS and Android that encrypt corporate data in the Microsoft 365 apps,
restrict data movement (copy/paste, save-as, "open in"), require an app PIN, block compromised
devices, and allow a selective wipe that removes corporate data while leaving personal data intact —
all enforced by a Conditional Access grant that requires an app protection policy, and all without
enrolling the device, on a GCC High tenant.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Corporate data protected inside the Microsoft 365 apps on personal phones — encryption, data-movement
limits, PIN, and selective wipe, enforced by Conditional Access — deployed **correctly on GCC High**:
right portals, right endpoints, parity gaps handled, proven on a pilot before you scale.


---


# 1. Solution Overview — MAM App Protection Policies for BYOD (Microsoft 365 Apps) — Government / GCC High

## What MAM App Protection Policies are
Mobile Application Management (MAM) protects corporate data **inside individual mobile apps**
without managing the whole device. **App Protection Policies (APP)** are the Intune feature that
carries those protections. Because they work on unenrolled devices — a model called
**MAM-without-enrollment (MAM-WE)** — you protect the data in Outlook, Teams, Word, Excel,
PowerPoint, OneDrive, SharePoint, and Edge on an employee's personal phone without ever enrolling
that phone into mobile device management (MDM). MAM-WE is supported on Android and iOS/iPadOS
(and Windows). [Microsoft — MAM for unenrolled
devices](https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment)

This is deliberately different from device enrollment (COD / BYOD MDM). Enrollment manages the whole
device (settings, apps, compliance). MAM manages only the corporate data inside supported apps. On a
personal (BYOD) phone, MAM is the lighter, privacy-respecting choice: IT never sees personal photos,
messages, or apps, and can only wipe the corporate data it placed there.

## This is the Government (GCC High) edition
A GCC High tenant is a **separate US sovereign cloud** — its own admin portals, sign-in endpoint,
and Microsoft Graph endpoint, and a handful of capabilities that lag, are limited, or are **absent**
versus Commercial. The App Protection Policy *concepts* are identical to Commercial, but following
Commercial steps on a GCC High tenant sends you to the wrong URLs and to features that silently do
not exist. In GCC High, App Protection and App Configuration policies are built in the Intune admin
center at **`https://intune.microsoft.us`**, the Conditional Access grant in Microsoft Entra at
**`https://entra.microsoft.us`**, and the scripts connect to US Gov Graph
(`Connect-MgGraph -Environment USGov`, i.e. `graph.microsoft.us`). Intune's Government service is
built on Azure Government (GCC High = IL4, DoD = IL5) and is a physically separate instance from
Commercial. [Microsoft — Intune Government service
overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service)

## How it works
1. An **App Protection Policy** is created for a platform (one for iOS/iPadOS, one for Android) and
   scoped to the Microsoft 365 apps the policy protects.
2. The policy is assigned to a user group. When a user signs in to a targeted app with their work
   account — authentication goes to **`login.microsoftonline.us`** in GCC High — the app enforces
   the policy on the **corporate identity only**.
3. Data-protection settings encrypt org data and restrict how it moves: cut/copy/paste to
   unmanaged apps, save-as to personal locations, and "open in / share" are limited to managed apps.
4. Access settings require an app PIN (or biometric), block jailbroken/rooted devices, set an
   offline grace period, and can require a minimum OS/app version.
5. An **App Configuration Policy (managed apps)** pushes app settings — for example, requiring data
   to be saved only to OneDrive/SharePoint, or configuring the Edge managed browser.
6. A Conditional Access grant of **"Require app protection policy"** ensures corporate resources are
   reachable only from an app that has a protection policy applied — so protection cannot be bypassed
   by using an unmanaged app. (This CA grant is available in GCC High; deploy the **Conditional
   Access Integration (GCC High)** solution to enforce it.)
7. When someone leaves or a phone is lost, a **selective (app) wipe** removes only the corporate data
   from the apps, leaving the user's personal data untouched.

## What you can control
- Encryption of org data at rest inside the app.
- Cut/copy/paste, save-as, and "open in / share" restrictions between managed and unmanaged apps.
- App-level PIN or biometric, PIN complexity, and PIN retry/reset behavior.
- Block on jailbroken (iOS) / rooted (Android) devices; minimum OS and app versions.
- Offline grace period before access is blocked or corporate data is wiped.
- Managed browser (Edge) and "save copies of org data" location controls (via app configuration).
- Selective wipe of corporate data only, on demand.

## Commercial vs GCC High — what's different
This is the section a Commercial-trained admin must read first. The **App Protection Policy building
blocks are identical**; what changes are the **URLs, endpoints, some mobile-app features, and rollout
timing**.

| Area | Commercial | Government (GCC High) |
|---|---|---|
| Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Entra admin center (CA grant) | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Microsoft 365 admin | `admin.microsoft.com` | **`portal.office365.us`** |
| Sign-in / auth endpoint | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph endpoint | `graph.microsoft.com` | **`graph.microsoft.us`** |
| Graph PowerShell connect | `Connect-MgGraph` | **`Connect-MgGraph -Environment USGov`** |
| Company Portal service endpoint | `portal.manage.microsoft.com` | **`portal.manage.microsoft.us`** (US Gov) |
| App Protection Policies (APP / MAM) | ✅ | **✅ available** — "standard MDM features … app policies" are supported |
| App Configuration Policies (managed apps) | ✅ | **✅ available** |
| MAM-without-enrollment | ✅ | **✅ available** (Android needs Company Portal broker; iOS needs Authenticator broker) |
| CA "Require app protection policy" grant | ✅ | **✅ available** (via the CA solution) |
| Microsoft Tunnel for MAM (per-app VPN for MAM) | ✅ | **✅ available in GCC High/DoD** |
| Outlook mobile "extras" (location services, Play My Emails, To Do) | ✅ | **❌ not FedRAMP-approved for US Gov** — not available |
| Quiet time (notification) policies | ✅ | **❌ not supported in sovereign clouds** (GCC/GCC High/DoD) |
| New-feature rollout timing | first | **typically weeks–months later** than Commercial |

Sources: [Intune Government service
overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service) ·
[MAM for unenrolled
devices](https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment) ·
[Outlook for iOS/Android in the Government
cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud)
· [Quiet time policies (not supported in sovereign
clouds)](https://learn.microsoft.com/en-us/intune/app-management/protection/configure-quiet-time).
Where a specific control is not listed on a Microsoft US Gov availability page, **verify for GCC
High** in your own tenant before designing around it. See `gcc-high-parity-notes.md`.

## Benefits
- **Data protection without device management** — the corporate data is protected; the personal phone is not managed.
- **Privacy for the employee** — IT cannot see or wipe personal data, which speeds BYOD adoption.
- **Enforced, not optional** — a Conditional Access grant blocks access from apps without the policy.
- **Selective wipe** — offboarding or a lost phone removes only corporate data.
- **Sovereign-correct** — the right `*.us` portals and endpoints, so nothing silently mis-targets.
- **Repeatable** — assign the policies once to a group; new BYOD users inherit protection automatically.

## Limitations (be honest with buyers)
- MAM protects data inside supported apps (the Microsoft 365 apps and other MAM-enabled apps). It
  does not protect data in apps that do not support App Protection Policies.
- A user can still take a photo of the screen; MAM reduces data leakage, it does not make it impossible.
- Enforcing "Require app protection policy" through Conditional Access requires **Entra ID P1**
  (in GCC High, typically via **Microsoft 365 G3/G5 Government**).
- Some deep controls (for example, requiring device-level compliance) need enrollment; MAM alone
  does not manage the device.
- **GCC-High-specific:** some Outlook mobile features (location services, Play My Emails, To Do) are
  not FedRAMP-approved and are unavailable; quiet time policies are not supported in sovereign
  clouds; and new features generally arrive later than Commercial — **verify for GCC High** before
  depending on any recently announced capability.

## The standard deployment model
> Create iOS + Android App Protection Policies, add an App Configuration Policy, enforce with a
> Conditional Access "Require app protection policy" grant, validate on an unenrolled BYOD device,
> then pilot and expand. Pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


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


# 3. Implementation Guide — MAM App Protection Policies for BYOD (Government / GCC High)

Follow these steps **in order**. In GCC High, App Protection and App Configuration policies are in
the Intune admin center (**`https://intune.microsoft.us`** → **Apps**). The Conditional Access grant
is in Microsoft Entra (**`https://entra.microsoft.us`** → **Protection → Conditional Access**).

> **Government caveat (read first):** every portal below is a **`*.us`** sovereign-cloud URL. If a
> link opens `intune.microsoft.com`, `entra.microsoft.com`, or `login.microsoftonline.com`, stop —
> you are on the Commercial cloud, and changes there do **not** affect your GCC High tenant.

> **Model:** iOS + Android App Protection Policies → App Configuration Policy → CA "require app
> protection policy" grant (Report-only) → validate on an unenrolled BYOD device → pilot → expand.

Reuse these object names exactly: **`MAM Users - BYOD - Pilot`**, **`MAM Users - BYOD - Production`**,
**`BYOD - App Protection - iOS (Gov)`**, **`BYOD - App Protection - Android (Gov)`**,
**`BYOD - App Config - M365 (Gov)`**, **`CA - Require APP - M365 (Gov)`**.

## Step 1 — Create the scope groups
1. `https://entra.microsoft.us` → **Groups → New group → Security** → **`MAM Users - BYOD - Pilot`**
   (a few representative BYOD users). **Create**.
2. Create **`MAM Users - BYOD - Production`** (the rest of the BYOD population). **Create**.
   *(Or run `MAMAPPG-Set-ScopeTargeting.ps1` — defaults to preview — to create both.)*

## Step 2 — Create the iOS App Protection Policy
1. `https://intune.microsoft.us` → **Apps → App protection policies → Create policy → iOS/iPadOS**.
2. **Name:** `BYOD - App Protection - iOS (Gov)`. **Next**.
3. **Apps:** target **Selected apps** (or **All Microsoft apps**) and add Outlook, Teams, Word,
   Excel, PowerPoint, OneDrive, SharePoint, and Edge. **Next**.
4. **Data protection:**
   - Backup org data to iTunes and iCloud backups: **Block**.
   - Send org data to other apps: **Policy managed apps** (limits "open in / share").
   - Receive data from other apps: **Policy managed apps**.
   - Restrict cut, copy, and paste between other apps: **Policy managed apps with paste in**.
   - Save copies of org data: **Block**, then allow only **OneDrive for Business** and **SharePoint**.
   - Encrypt org data: **Require**.
5. **Access requirements:** PIN for access: **Require** (allow biometric); Recheck after (inactivity):
   **30** min; Offline grace period: **720** minutes to block / **90** days to wipe. **Next**.
6. **Conditional launch:** Jailbroken/rooted devices → **Block access**; min OS / min app version
   per your standard (action **Warn** or **Block**); Max PIN attempts **5** → **Reset PIN** (or
   **Wipe data**). **Next**.
7. **Assignments → Included groups → `MAM Users - BYOD - Pilot`**. **Next → Create**.

## Step 3 — Create the Android App Protection Policy
1. `https://intune.microsoft.us` → **Apps → App protection policies → Create policy → Android**.
2. **Name:** `BYOD - App Protection - Android (Gov)`. **Next**.
3. **Apps:** add the same set — Outlook, Teams, Word, Excel, PowerPoint, OneDrive, SharePoint, Edge. **Next**.
4. **Data protection:** match Step 2 (block backup, policy-managed transfer, block save-as except
   OneDrive/SharePoint, require encryption). Set **Screen capture and Google Assistant** to **Block**
   if required. **Next**.
5. **Access requirements:** require an app PIN (allow biometric), recheck after **30** min, offline
   grace **720** minutes to block / **90** days to wipe. **Next**.
6. **Conditional launch:** rooted devices → **Block access**; set min OS / min app version / min
   patch level; max PIN attempts **5** → **Reset PIN**. Set **Device attestation** (Play Integrity)
   to **Require** if your standard needs it. **Next**.
7. **Assignments → Included groups → `MAM Users - BYOD - Pilot`**. **Next → Create**.

> **GCC High caveat:** on **Android**, the policy will not apply until **Company Portal** (the MAM
> broker, service endpoint `portal.manage.microsoft.us`) is installed — no enrollment, broker only.
> On **iOS**, the **Microsoft Authenticator** broker is required. [MAM for unenrolled
> devices](https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment)

## Step 4 — Create the App Configuration Policy (managed apps)
1. `https://intune.microsoft.us` → **Apps → App configuration policies → Add → Managed apps**.
2. **Name:** `BYOD - App Config - M365 (Gov)`. **Next**.
3. **Public apps:** select the same Microsoft 365 apps (iOS and Android). **Next**.
4. **Settings:** add managed-app configuration keys per your standard — for example, default save
   location OneDrive/SharePoint, and Edge managed-browser settings (require org sign-in). **Next**.
   > **GCC High caveat:** do not configure Outlook features that are **not FedRAMP-approved for US
   > Gov** (location services, Play My Emails, To Do). **Verify for GCC High** that a given
   > configuration key is honored before relying on it. [Outlook in the Government
   > cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud)
5. **Assignments → Included groups → `MAM Users - BYOD - Pilot`**. **Next → Create**.

## Step 5 — Enforce with Conditional Access (require app protection policy)
1. `https://entra.microsoft.us` → **Protection → Conditional Access → Create new policy**.
2. **Name:** `CA - Require APP - M365 (Gov)`.
3. **Users:** Include `MAM Users - BYOD - Pilot`; **Exclude** the two break-glass accounts.
4. **Target resources:** Cloud apps → **Office 365**.
5. **Conditions → Device platforms →** Include **iOS** and **Android**.
6. **Grant:** Grant access → **Require app protection policy** and **Require approved client app**;
   choose **Require one of the selected controls**.
7. **Enable policy: Report-only**. **Create**.
   > **GCC High caveat:** the CA "require app protection policy" grant **is available** in GCC High.
   > Always pilot in **Report-only** first; see the **Conditional Access Integration (GCC High)**
   > solution for the full lockout-safe rollout.

## Step 6 — Validate on an unenrolled BYOD device
1. On a personal (unenrolled) iPhone or Android, install the Microsoft 365 apps and the MAM broker
   (**Authenticator** on iOS / **Company Portal** on Android — brokering only; do not enroll).
2. Sign in to Outlook with the pilot work account (sign-in goes to `login.microsoftonline.us`). The
   app should apply the policy: prompt for an app PIN and show "managed by your organization" behavior.
3. Copy org text into a personal app — paste should be blocked; save an attachment to a personal
   location — save-as should be blocked (OneDrive/SharePoint allowed).
4. Run **`MAMAPPG-Validation.ps1 -UserPrincipalName pilot-user@your-tenant.onmicrosoft.us`** (US Gov Graph) to confirm the
   user's apps report a protection policy applied.

## Step 7 — Validate the pilot and enable enforcement
1. Run **`MAMAPPG-Report.ps1`** to confirm coverage (which pilot users/apps have the policy) and the
   CA grant status.
2. `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs** → open a pilot sign-in →
   **Report-only** tab; confirm `CA - Require APP - M365 (Gov)` would apply and grant only from a
   protected app.
3. Complete the Testing Guide. When clean, edit `CA - Require APP - M365 (Gov)` → **Enable policy → On**.

## Step 8 — Expand to production
1. Add **`MAM Users - BYOD - Production`** to the **Included groups** of the iOS and Android App
   Protection Policies, the App Configuration Policy, and the CA grant. Use
   **`MAMAPPG-Set-ScopeTargeting.ps1`** (defaults to preview) to build/populate the production group.
2. Roll out in waves; monitor sign-in logs and run **`MAMAPPG-Report.ps1`** each wave.
3. Re-validate with **`MAMAPPG-Validation.ps1`**; remediate gaps with **`MAMAPPG-Remediation.ps1`**
   (defaults to `-WhatIf`).

---
### Order of operations
`Scope groups → iOS APP → Android APP → App config → CA grant (Report-only) → Validate on BYOD → Enable → Expand`


---


# 5. Testing Guide — MAM App Protection Policies for BYOD (Government / GCC High)

Run after the pilot policies apply (Implementation Step 6) and after each expansion wave. Use a
real, unenrolled personal device where possible. All admin checks are on the **`*.us`** sovereign
portals; all scripts connect to **US Gov Graph** (`-Environment USGov`).

## Test 1 — Policy assigned and applied
**Do:** `https://intune.microsoft.us` → **Apps → App protection policies →**
`BYOD - App Protection - iOS (Gov)` (and Android) → **Monitor** / check-in status; or run
**`MAMAPPG-Report.ps1`**.
**Expected:** Pilot users show the policy applied (checked-in) for the targeted apps.

## Test 2 — App PIN enforced
**Do:** On an unenrolled device (with the correct broker — Authenticator on iOS / Company Portal on
Android), open Outlook with the work account.
**Expected:** The app prompts to set an app PIN (or biometric) before showing org data.

## Test 3 — Copy/paste restricted
**Do:** Copy text from Outlook/Teams and try to paste into a personal app (for example, personal Notes).
**Expected:** The paste is blocked (or empty), per the "policy managed apps" cut/copy/paste setting.

## Test 4 — Save-as restricted
**Do:** Open an attachment and try Save / Share to a personal location (camera roll, personal cloud).
**Expected:** Save-as to personal locations is blocked; only OneDrive/SharePoint are allowed.

## Test 5 — Jailbreak/root block
**Do:** (If available) sign in from a jailbroken iOS or rooted Android device, or review the
conditional-launch setting.
**Expected:** Access is blocked on a compromised device per the conditional-launch rule.

## Test 6 — Conditional Access enforces protected app
**Do:** After Step 7 enable, try to reach Office 365 from an unmanaged app (one without the policy)
on the pilot account. Sign-in goes to `login.microsoftonline.us`.
**Expected:** `CA - Require APP - M365 (Gov)` blocks the sign-in; access is granted only from a
protected app.

## Test 7 — Selective wipe (corporate data only)
**Do:** `https://intune.microsoft.us` → **Apps → App selective wipe → Create wipe request** for a
pilot user/device; then reopen the app.
**Expected:** Corporate data is removed from the apps; the user's personal data is untouched.

## Test 8 — US Gov Graph targeting confirmed
**Do:** Run **`MAMAPPG-Discovery.ps1`**.
**Expected:** The script reports **Graph environment = USGov** (`graph.microsoft.us`) and inventories
the iOS/Android App Protection Policies, App Configuration policies, and the CA app-protection grant.
A `graph.microsoft.com` result is a **wrong-cloud FAIL** — reconnect with `-Environment USGov`.

## Test 9 — Coverage and enforcement report
**Do:** Run **`MAMAPPG-Report.ps1`**.
**Expected:** A per-policy coverage table with assigned-group counts plus confirmation the CA grant
is enabled and scoped.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Cloud gate | **Test 8 passes** — all admin work and scripts target the **GCC High / USGov** cloud |
| Pilot pass | Tests 1-5 and 7 pass on an unenrolled device; Test 6 passes once the CA grant is enabled |
| Production pass | Tests 1-4, 6, 9 pass for the production group before declaring rollout complete |


---


# 6. Troubleshooting Guide — MAM App Protection Policies for BYOD (Government / GCC High)

Use **`MAMAPPG-Validation.ps1`** for a user's protection status, **`MAMAPPG-Discovery.ps1`** to
inventory policies and confirm the cloud, **`MAMAPPG-Report.ps1`** for coverage, and
**`MAMAPPG-Remediation.ps1`** for safe fixes. All scripts connect to **US Gov Graph**
(`-Environment USGov`).

## A. Wrong cloud (the #1 GCC High issue)
| Symptom | Cause | Remediation |
|---|---|---|
| Scripts return nothing / errors, or show `graph.microsoft.com` | Connected to the Commercial cloud, not US Gov | Reconnect with **`Connect-MgGraph -Environment USGov`**; re-run `MAMAPPG-Discovery.ps1` and confirm environment = **USGov** |
| Portal changes have no effect | You edited `intune.microsoft.com` / `entra.microsoft.com` (Commercial) | Use the **`*.us`** portals: `intune.microsoft.us`, `entra.microsoft.us` |
| Sign-in behaves oddly | App pointed at `login.microsoftonline.com` | GCC High auth is **`login.microsoftonline.us`** — verify the account/tenant is `.onmicrosoft.us` |

## B. Policy not applying to the app
| Symptom | Cause | Remediation |
|---|---|---|
| App never prompts for a PIN | User not in the assigned group, or app not targeted | Confirm the user is in `MAM Users - BYOD - Pilot`; confirm the app is in the policy's app list; run `MAMAPPG-Remediation.ps1` |
| **Android** app not protected | **Company Portal** (the MAM broker) not installed | Install Intune Company Portal from Google Play (broker only, no enrollment — GCC High endpoint `portal.manage.microsoft.us`); reopen the app |
| **iOS** app not protected | **Microsoft Authenticator** broker not installed | Install Authenticator; reopen the app and sign in with the work account |
| Policy shows unlicensed | User missing Intune / Entra ID P1 (Gov) | Assign Government licensing (Requirement 2.2); run `MAMAPPG-Discovery.ps1` |

## C. Conditional Access blocks or does not enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Access granted from an unmanaged app | `CA - Require APP - M365 (Gov)` still in Report-only | Set the policy **Enable → On** in `entra.microsoft.us`; re-test from an unmanaged app |
| Legitimate user blocked | User not covered by an App Protection Policy, or wrong platform condition | Confirm the APP is assigned and applied; check the CA **Device platforms** include iOS/Android; review the sign-in log Report-only tab |
| Admin locked out | Break-glass account not excluded | Exclude the two break-glass `.onmicrosoft.us` accounts from `CA - Require APP - M365 (Gov)` |

## D. Data-movement controls not working as expected
- Copy/paste still works to a personal app: confirm **Restrict cut, copy, and paste** is
  **Policy managed apps** (not **Any app**) and the target is not another managed app.
- Save-as to a personal location succeeds: confirm **Save copies of org data** is **Block** with only
  OneDrive/SharePoint allowed, and that the app has re-checked in after the policy change.

## E. PIN and access issues
- User forgot the app PIN: max attempts triggers a PIN reset (or wipe) per conditional launch; the
  user re-creates the PIN on next launch.
- Access blocked after travel: the offline grace period elapsed — reconnect to network and sign in
  (via `login.microsoftonline.us`) to re-evaluate the policy.

## F. Selective wipe did not complete
- Wipe pending: the wipe runs the next time the app connects with the work identity. Have the user
  open the app online; check `intune.microsoft.us` → **Apps → App selective wipe** for status.
- Personal data appears removed: on BYOD, only corporate data should be wiped — confirm you issued an
  **app selective wipe**, not a device wipe.

## G. GCC-High-specific gotchas
- **A feature works in Commercial but is missing here.** New MAM features generally reach GCC High
  weeks–months later; some (quiet time policies) are not supported in sovereign clouds at all, and
  some Outlook mobile extras (location services, Play My Emails, To Do) are not FedRAMP-approved for
  US Gov. **Verify for GCC High** before relying on it. See `gcc-high-parity-notes.md`.
- **An MTD connector is absent.** Only MTD vendors that also support GCC High appear; a Commercial
  connector may not exist in your Gov tenant.

## H. Diagnostics quick reference
Run **`MAMAPPG-Discovery.ps1`** (confirms USGov, inventories iOS/Android App Protection policies, App
Configuration policies, and the CA app-protection grant) and **`MAMAPPG-Report.ps1`** (per-policy
coverage plus CA grant state). On the device, the app's in-app "About / managed by your organization"
screen shows whether a protection policy is applied. In `entra.microsoft.us`, the sign-in log
Report-only / Applied tab shows which CA policies evaluated for a given sign-in.

## I. When to escalate
If the App Protection Policy is assigned and applied, the user is licensed, the broker is present
(Company Portal on Android / Authenticator on iOS), the scripts confirm the **USGov** cloud, the CA
grant is enabled with break-glass excluded, and access still behaves incorrectly after the app checks
in, capture the Intune app-protection status, the CA sign-in log entry, and the app/OS versions, and
open a Microsoft support case against the **GCC High** tenant.


---


# 7. Best Practices — MAM App Protection Policies for BYOD (Government / GCC High)

- **Confirm the cloud first.** Before any change, run `MAMAPPG-Discovery.ps1` and confirm the Graph
  environment is **USGov** (`graph.microsoft.us`) and you are in the `*.us` portals. A single
  Commercial-cloud action does nothing for a GCC High tenant — the #1 GCC High mistake.
- **Pilot first, always.** Assign to `MAM Users - BYOD - Pilot` and validate on a real unenrolled
  device before touching production.
- **Enforce with Conditional Access.** App Protection Policies protect data, but only
  `CA - Require APP - M365 (Gov)` guarantees corporate resources are reachable only from a protected
  app. The CA grant is available in GCC High — deploy both, and start the grant in **Report-only**
  with break-glass accounts excluded.
- **Install the right broker.** Android needs **Company Portal** (`portal.manage.microsoft.us`); iOS
  needs **Microsoft Authenticator**. Without the broker the policy silently never applies — bake this
  into user onboarding.
- **Keep iOS and Android policies in sync.** Mirror the same data-protection and access settings
  across `BYOD - App Protection - iOS (Gov)` and `BYOD - App Protection - Android (Gov)` so behavior
  is consistent.
- **Limit save-as to org locations.** Block save-as except OneDrive/SharePoint so corporate data
  does not land in personal cloud or the camera roll.
- **Require an app PIN and encryption.** These are the baseline that makes a lost phone a non-event
  for corporate data.
- **Set a sensible offline grace period.** Too short frustrates travelers; too long weakens the wipe
  guarantee.
- **Prefer selective (app) wipe over device wipe on BYOD.** Remove corporate data only; never wipe an
  employee's personal phone. Communicate this clearly to build trust and adoption.
- **Do not depend on non-FedRAMP Outlook extras.** Location services, Play My Emails, and To Do are
  not available for US Gov — don't build a configuration or user expectation around them.
- **Assume features lag.** New MAM capabilities generally arrive in GCC High weeks–months after
  Commercial (and quiet time policies are not supported in sovereign clouds). **Verify for GCC High**
  in your own tenant before designing around a recently announced feature.
- **Assign to groups, not users.** Add new BYOD users to the scope groups; they inherit protection
  automatically.
- **Watch coverage.** Track which users/apps report a policy with `MAMAPPG-Report.ps1` and chase the
  gaps with `MAMAPPG-Remediation.ps1` (default `-WhatIf`).
- **Document the settings.** Record the data-protection and access values, the app list, and the CA
  grant for audits and repeatability.


---


# 8. Deliverables Summary — MAM App Protection Policies for BYOD (Government / GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (GCC High edition) |
| 1. Solution Overview | What MAM/APP is, MAM-without-enrollment, data-protection controls, app config, CA enforcement, plus **Commercial vs GCC High — what's different** |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, on the `*.us` endpoints |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune + Entra steps on the **GCC High** portals, with parity caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates (including a cloud-targeting gate) |
| 6. Troubleshooting Guide | Field issues and remediation, GCC-High-specific |
| 7. Best Practices | Field-proven recommendations for the sovereign cloud |
| GCC High Parity Notes | Cited Commercial-vs-GCC-High feature gaps for MAM/APP |

## PowerShell scripts (all connect to US Gov Graph — `-Environment USGov`)
| Script | What it does |
|---|---|
| `MAMAPPG-Discovery.ps1` | Confirms the USGov cloud, then inventories iOS/Android App Protection & App Configuration policies and the CA app-protection grant (read-only) |
| `MAMAPPG-Validation.ps1` | Confirms a user's targeted apps report an App Protection Policy applied (read-only) |
| `MAMAPPG-Report.ps1` | Coverage and enforcement report — per-policy assigned-group counts plus the CA grant state (read-only, optional CSV) |
| `MAMAPPG-Remediation.ps1` | Safe remediation — assigns a missing App Protection Policy to the scope group (**default `-WhatIf`**) |
| `MAMAPPG-Set-ScopeTargeting.ps1` | Creates/populates `MAM Users - BYOD - Pilot` / `- Production` groups and previews membership (**default `-WhatIf`**) |

## What the buyer receives
- This implementation guide as a Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Corporate data protected inside the Microsoft 365 apps on personal phones — encryption, data-movement
limits, PIN, and selective wipe, enforced by Conditional Access — deployed **correctly on GCC High**:
right `*.us` portals, US Gov Graph endpoints, and parity gaps handled, with no full-device enrollment.
