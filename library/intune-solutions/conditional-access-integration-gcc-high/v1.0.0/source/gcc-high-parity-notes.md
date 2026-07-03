# GCC High Parity Notes — Conditional Access (cited)

This reference lists where **Conditional Access and related identity features differ between
Commercial and the US Government (GCC High) sovereign cloud**. Use it when designing policies so you
don't build on a capability that isn't there. Every row is either **cited** to a Microsoft US Gov
availability page or explicitly flagged **"verify for GCC High"** where Microsoft does not publish a
definitive Gov statement. **Nothing here is invented.**

> **Cloud identity:** GCC High is a **separate tenant** in a separate sovereign cloud — it is not
> your Commercial or GCC tenant. Its domains end in `.onmicrosoft.us`.
> [Microsoft — GCC High
> endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 1. Portals and endpoints (these always differ)
| Purpose | Commercial | GCC High |
|---|---|---|
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal (app registrations) | `portal.azure.com` | `portal.azure.us` |
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Defender portal | `security.microsoft.com` | `security.microsoft.us` |
| Purview / compliance | `compliance.microsoft.com` | `compliance.microsoft.us` / `purview.microsoft.us` |
| Sign-in / auth endpoint | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph endpoint | `graph.microsoft.com` | `graph.microsoft.us` |
| Graph PowerShell | `Connect-MgGraph` | `Connect-MgGraph -Environment USGov` |

`login.microsoftonline.us`, `graph.microsoft.us`, `*.auth.microsoft.us`, `security.microsoft.us`,
`compliance.microsoft.us`, and `outlook.office365.us` are all confirmed GCC High endpoints in the
Microsoft endpoint list. [Microsoft — GCC High
endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)
· Graph `USGov` environment = `https://graph.microsoft.us`. [Microsoft — Graph national cloud
deployments](https://learn.microsoft.com/en-us/graph/deployments)

## 2. Conditional Access & MFA — what's available in US Gov
| Feature | GCC High availability | Source |
|---|---|---|
| Conditional Access (policy engine) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| Multifactor authentication (MFA) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| Passwordless (WHfB, Authenticator, FIDO2) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| Certificate-based authentication (CBA) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| Session lifetime management (sign-in frequency, persistent browser) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| Terms of use (usable as a CA grant) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| Report-only mode | **✅ Available** — recommended for piloting | [CA network signals](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network) |
| Named locations (IP-based) | **✅ Available** — use instead of legacy MFA Trusted IPs | [CA network signals](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network) |
| RBAC / delegated admin (built-in roles) | **✅ Available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |

## 3. Identity Protection (risk-based CA) — mostly available, one gap
Microsoft Entra ID Protection risk detections are **available in US Gov**, with a documented
exception:
- **Available:** leaked credentials, anonymous IP, atypical/impossible travel, anomalous token,
  token issuer anomaly, malware-linked IP, suspicious browser, unfamiliar sign-in properties,
  malicious IP, password spray, new country, and more. Risk-events investigation and SIEM
  connectivity are available.
- **❌ NOT available:** **Microsoft Entra threat intelligence** risk detection is marked ❌ for US
  Gov. Do not build a risk-based CA policy that depends on that specific detection.

Source: [Entra feature availability — US Gov (ID Protection
table)](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability).
Risk-based Conditional Access requires **Entra ID P2** (M365 G5 Gov).

## 4. Features that are absent, limited, or lag in GCC High
| Item | Status in GCC High | Source / note |
|---|---|---|
| **Global Secure Access (GSA)** / network-based CA | **❌ Not available** in GCC High (or DoD) | [GSA known limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations) — design network trust with IP-based named locations instead |
| **Microsoft Entra threat intelligence** risk detection | **❌ Not available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| **CA policy PowerPoint export** | **❌ Commercial-only** (GCC High planned) | Microsoft has stated this export is Commercial cloud only; use sign-in logs / What If / `CAIG-Report.ps1` for evidence — **verify for GCC High** before relying on it |
| **Delegated user management portal (My Staff)** | **❌ Not available** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| **Enterprise state roaming (shared device sign-out, Win10)** | **Limited** — not available | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| **HR-driven provisioning** | **Partial** | [Entra feature availability — US Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) |
| **New feature rollout timing** | **Typically 2–6 weeks after Commercial** | GCC High receives features later than Commercial — **verify for GCC High** that a demoed capability is live in your tenant before designing around it |

## 5. GPS-based named locations / authenticator-driven location
Location can be determined by public IP or by **GPS coordinates from the Microsoft Authenticator
app**. Microsoft's location-condition documentation applies to both the global and Azure Government
documentation sets, but Microsoft does not publish a definitive GCC-High-specific statement for the
**GPS-based named locations** capability. Treat **IP-based named locations** as the reliable, cited
option in GCC High, and **verify for GCC High** in your own tenant before depending on GPS/Authenticator-based
location. [Microsoft — CA network
signals](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network)

## 6. How to verify anything not listed here
For any control not explicitly on a Microsoft US Gov availability page:
1. Open it in **`entra.microsoft.us`** (the sovereign portal) — if the blade/option is absent, the
   feature isn't there yet.
2. Cross-check the [Entra feature availability — US
   Gov](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) and
   [GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)
   pages.
3. If still ambiguous, treat it as **"verify for GCC High"** and pilot in Report-only before
   depending on it. Never assume Commercial parity.

---
### Sources
- Microsoft Entra feature availability in Azure for US Government —
  https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability
- Microsoft 365 U.S. Government GCC High endpoints —
  https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints
- Global Secure Access known limitations —
  https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations
- Microsoft Graph national cloud deployments — https://learn.microsoft.com/en-us/graph/deployments
- Conditional Access policy: using network signals —
  https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network
- Use Conditional Access with Intune compliance policies —
  https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/overview
