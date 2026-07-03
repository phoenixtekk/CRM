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
