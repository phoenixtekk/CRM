# GCC High Parity Notes — Secure Mobile Access to SharePoint Online under MAM (cited)

This reference lists where **mobile access to SharePoint Online under MAM differs between Commercial
and the US Government (GCC High) sovereign cloud**. Use it so you don't build on a capability that
isn't there. Every row is either **cited** to a Microsoft US Gov page or explicitly flagged **"verify
for GCC High"** where Microsoft does not publish a definitive Gov statement. **Nothing here is
invented.**

> **Cloud identity:** GCC High is a **separate tenant** in a separate sovereign cloud — not your
> Commercial or GCC Moderate tenant. SharePoint tenants resolve at **`*.sharepoint.us`**, and sign-in
> is at **`login.microsoftonline.us`**.
> [GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 1. Portals and endpoints (these always differ)
| Purpose | Commercial | GCC High |
|---|---|---|
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| SharePoint admin / tenant | `*.sharepoint.com` | `*.sharepoint.us` |
| Sign-in / auth endpoint | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph endpoint | `graph.microsoft.com` | `graph.microsoft.us` |
| Graph PowerShell | `Connect-MgGraph` | `Connect-MgGraph -Environment USGov` |

Graph `USGov` environment = `https://graph.microsoft.us`.
[Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments)

## 2. Core building blocks — available in GCC High
| Capability | GCC High availability | Source |
|---|---|---|
| Intune **App Protection Policies (MAM/APP)** | **✅ Available** | [App Protection Policies overview](https://learn.microsoft.com/en-us/intune/app-management/protection/overview) |
| **Conditional Access** (policy engine) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| **Multifactor authentication (MFA)** | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| **Report-only** CA mode (piloting) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| **SharePoint mobile apps** (iOS/Android) | **✅ Supported** in GCC/GCC High/DoD | [SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint) |

The core of this solution — App Protection Policies + a Conditional Access policy that **requires app
protection policy** for mobile access to Office 365/SharePoint Online — is fully available in GCC
High.

## 3. Mobile app behavior that differs in GCC High
| Item | Status in GCC High | Source / note |
|---|---|---|
| **Graph-dependent SharePoint mobile features** | **❌ Disabled** — "Graph functionality within SharePoint Online for GCC High is currently disabled. Any service that relies on Microsoft Graph might not currently be available" | [SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint) |
| **Activity notifications** (file/site) | **❌ Not available** | [SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint) |
| **News rollups / hub news from other sites** | **❌ Current-site only** for GCC High/DoD | [SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint) |
| **Internet-service web parts / stock images tab** | **❌ Won't work as expected** | [SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint) |
| **Personal accounts alongside the gov account** | **❌ Blocked** — only the government account can be added to the mobile apps; several in-app cloud features are FedRAMP-restricted by default | [Outlook for iOS/Android in the government cloud](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud) |

> These limitations affect **user workflows on mobile**, not the security posture — App Protection
> Policies and CA still enforce correctly. Design SharePoint sites so they don't depend on the
> disabled features when accessed from mobile.

## 4. Conditional Access control that is retiring (applies to both clouds)
| Item | Status | Source |
|---|---|---|
| **"Require approved client app"** CA grant | **Retiring early March 2026** — use **"Require app protection policy"** for new policies | [Migrate approved client app to app protection policy](https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app) |

This solution uses **"Require app protection policy"** throughout so it remains valid past the
retirement.

## 5. Timing / general parity caveats
| Item | Status in GCC High | Source / note |
|---|---|---|
| **New feature rollout timing** | **Typically later than Commercial** | GCC High receives features after Commercial — **verify for GCC High** that a demoed capability is live in your tenant before designing around it |
| **Any control not on a US Gov page** | **Verify for GCC High** | Open it in `intune.microsoft.us` / `entra.microsoft.us`; if the option is absent, the feature isn't there yet — pilot in Report-only first |

## 6. How to verify anything not listed here
1. Open the setting in the **sovereign portal** (`intune.microsoft.us` / `entra.microsoft.us`) — if
   the blade/option is absent, the feature isn't there yet.
2. Cross-check the [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability),
   [SharePoint for US government environments](https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint),
   and [GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)
   pages.
3. If still ambiguous, treat it as **"verify for GCC High"** and pilot in **Report-only** before
   depending on it. Never assume Commercial parity.

---
### Sources
- Intune App Protection Policies overview — https://learn.microsoft.com/en-us/intune/app-management/protection/overview
- Data protection framework using App Protection Policies — https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework
- App-based Conditional Access with Intune — https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/app-based-policies
- Conditional Access — Require approved app or app protection policy — https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-approved-app-or-app-protection
- Migrate approved client app to app protection policy — https://learn.microsoft.com/en-us/entra/identity/conditional-access/migrate-approved-client-app
- SharePoint for US government environments — https://learn.microsoft.com/en-us/office365/servicedescriptions/office-365-platform-service-description/office-365-us-government/sharepoint
- Outlook for iOS and Android in the government cloud — https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/outlook-for-ios-and-android/outlook-for-ios-and-android-in-the-government-cloud
- Microsoft 365 U.S. Government GCC High endpoints — https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints
- Microsoft Entra feature availability in Azure for US Government — https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability
- Microsoft Graph national cloud deployments — https://learn.microsoft.com/en-us/graph/deployments
