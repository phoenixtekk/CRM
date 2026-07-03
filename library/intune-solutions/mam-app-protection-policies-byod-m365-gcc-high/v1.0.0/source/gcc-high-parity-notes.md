# GCC High Parity Notes — MAM App Protection Policies (cited)

This reference lists where **MAM / App Protection Policies and related mobile-app features differ
between Commercial and the US Government (GCC High) sovereign cloud**. Use it so you don't build on a
capability that isn't there. Every row is either **cited** to a Microsoft US Gov page or explicitly
flagged **"verify for GCC High"** where Microsoft does not publish a definitive Gov statement.
**Nothing here is invented.**

> **Cloud identity:** GCC High is a **separate tenant** in a separate sovereign cloud — not your
> Commercial or GCC tenant. Its domains end in `.onmicrosoft.us`. Intune's Government cloud (GCC High
> = IL4, DoD = IL5) is a physically separate instance from Commercial; there is no built-in
> Commercial→Gov migration.
> [Microsoft — Intune Government service
> overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service)

## 1. Portals and endpoints (these always differ)
| Purpose | Commercial | GCC High |
|---|---|---|
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Entra admin center (CA grant) | `entra.microsoft.com` | `entra.microsoft.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Company Portal service endpoint | `portal.manage.microsoft.com` | `portal.manage.microsoft.us` |
| Sign-in / auth endpoint | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph endpoint | `graph.microsoft.com` | `graph.microsoft.us` |
| Graph PowerShell | `Connect-MgGraph` | `Connect-MgGraph -Environment USGov` |

The Graph `USGov` environment resolves to `https://graph.microsoft.us`. [Microsoft — Graph national
cloud deployments](https://learn.microsoft.com/en-us/graph/deployments) · [GCC High
endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 2. MAM / App Protection — what's available in GCC High
| Feature | GCC High availability | Source |
|---|---|---|
| App policies (App Protection + App Configuration) | **✅ Available** — listed under "Standard MDM features … app policies" | [Intune Government service overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service) |
| MAM-without-enrollment (MAM-WE) | **✅ Available** — Android/iOS/Windows; standard MAM model | [MAM for unenrolled devices](https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment) |
| CA "Require app protection policy" grant | **✅ Available** (via the CA solution) | Deploy **Conditional Access Integration (GCC High)** to enforce it |
| Microsoft Tunnel for Mobile Application Management | **✅ Available in GCC High/DoD** | [Intune Government service overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service) |
| Mobile Threat Defense (MTD) connectors | **✅ Available** — only for MTD vendors that also support GCC High; GCC High tenants see the available connectors | [Intune Government service overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service) |
| Platform support (Android, AOSP, iOS/iPadOS, Windows) | **✅ Available** — AOSP has some device restrictions | [Intune Government service overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service) |

## 3. MAM broker requirement (same as Commercial, but the endpoint differs)
MAM-WE brokers policy through a per-platform app. On **Android**, users must install **Company
Portal**; on **iOS**, a broker app such as **Microsoft Authenticator** is required. Without the
broker the App Protection Policy silently never applies. In GCC High the Company Portal service
endpoint is **`portal.manage.microsoft.us`**. [MAM for unenrolled
devices](https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment)

## 4. Mobile-app features that are absent, limited, or lag in GCC High
| Item | Status in GCC High | Source / note |
|---|---|---|
| **Outlook mobile: location services, Play My Emails, To Do** | **❌ Not available** — not FedRAMP-approved for US Gov | [Outlook for iOS/Android in the Government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud) |
| **Quiet time (notification) policies** | **❌ Not supported in sovereign clouds** (GCC/GCC High/DoD) | [Create quiet time policies](https://learn.microsoft.com/en-us/intune/app-management/protection/configure-quiet-time) |
| **New MAM feature rollout timing** | **Typically weeks–months after Commercial** | New features reach GCC High later after required security reviews — **verify for GCC High** that a demoed capability is live in your tenant before designing around it. [Intune Government service overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service) |
| **App availability (specific M365 apps/features)** | **Verify per app** | Outlook for iOS/Android is available for GCC High/DoD, but confirm each app/feature you depend on. [Outlook in the Government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud) |

## 5. How to verify anything not listed here
For any MAM/APP control not explicitly on a Microsoft US Gov page:
1. Open it in **`intune.microsoft.us`** (the sovereign portal) — if the blade/option is absent, the
   feature isn't there yet.
2. Cross-check the [Intune Government service
   overview](https://learn.microsoft.com/en-us/intune/fundamentals/government-service) and the [GCC
   High
   endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)
   pages.
3. If still ambiguous, treat it as **"verify for GCC High"** and pilot before depending on it. Never
   assume Commercial parity.

---
### Sources
- Microsoft Intune Government service overview (feature differences vs Commercial) —
  https://learn.microsoft.com/en-us/intune/fundamentals/government-service
- MAM for unenrolled devices (MAM-WE; broker requirements) —
  https://learn.microsoft.com/en-us/intune/app-management/protection/mam-without-enrollment
- Outlook for iOS/Android in the Government cloud (feature limits) —
  https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud
- Create quiet time policies (not supported in sovereign clouds) —
  https://learn.microsoft.com/en-us/intune/app-management/protection/configure-quiet-time
- Microsoft 365 U.S. Government GCC High endpoints —
  https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints
- Microsoft Graph national cloud deployments — https://learn.microsoft.com/en-us/graph/deployments
