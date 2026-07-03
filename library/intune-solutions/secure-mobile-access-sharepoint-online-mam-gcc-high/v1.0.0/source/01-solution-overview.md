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
