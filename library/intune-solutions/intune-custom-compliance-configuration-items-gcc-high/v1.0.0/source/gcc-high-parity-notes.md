# GCC High Parity Notes — Intune Custom Compliance & Configuration Items (Scripted)

A cited reference of how **US Government GCC High (US Gov L4)** differs from the **Commercial** cloud for this solution. Use it to avoid applying commercial steps that silently fail on a sovereign tenant. Every row is either **cited to Microsoft Learn** or explicitly flagged **"verify for GCC High."** Nothing here is invented.

> **Retrieved:** July 2026 against current Microsoft documentation. Government-cloud behavior changes over time and can lag commercial — re-verify in your own tenant before production.

---

## 1. Admin portals and endpoints

| What | Commercial | GCC High (US Gov L4) | Status |
| --- | --- | --- | --- |
| Intune admin center | `https://intune.microsoft.com` | `https://intune.microsoft.us/` | **Cited** — [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Azure portal | `https://portal.azure.com` | `https://portal.azure.us/` | **Cited** — [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| Microsoft 365 admin | `https://admin.microsoft.com` | `https://portal.office365.us/` | **Cited** — [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Company Portal | `https://portal.manage.microsoft.com` | `https://portal.manage.microsoft.us/` | **Cited** — [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Entra admin center | `https://entra.microsoft.com` | `https://entra.microsoft.us` | **Verify for GCC High** — consistent with Microsoft GCC High portal references; confirm live |
| Defender portal | `https://security.microsoft.com` | `https://security.microsoft.us` | **Verify for GCC High** — Microsoft GCC High portal references |
| Purview/Compliance portal | `https://compliance.microsoft.com` | `https://compliance.microsoft.us` | **Verify for GCC High** — Microsoft GCC High portal references |
| Sign-in / auth (Evo STS) | `login.microsoftonline.com` | `login.microsoftonline.us` | **Cited** — [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments); [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |

## 2. Microsoft Graph and PowerShell

| What | Commercial | GCC High (US Gov L4) | Status |
| --- | --- | --- | --- |
| Graph service root | `https://graph.microsoft.com` | `https://graph.microsoft.us` | **Cited** — [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| Graph PowerShell connect | `Connect-MgGraph` (Global) | `Connect-MgGraph -Environment USGov` | **Cited** — [Connect-MgGraph](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph) |
| Graph Explorer (browser tester) | Supported | **Not supported** for `graph.microsoft.us` | **Cited** — [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| DoD (US Gov L5) Graph root, if applicable | n/a | `https://dod-graph.microsoft.us` / `Connect-MgGraph -Environment USGovDoD` | **Cited** — [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) — this solution targets **L4/GCC High**; note L5 differs |

**Practical consequence:** the five scripts in this solution connect with `-Environment USGov` and use `graph.microsoft.us`. Do all API recon via the Microsoft Graph PowerShell SDK, because Graph Explorer will not reach your government tenant.

## 3. Device network endpoints (proxy/firewall)

| What | Commercial | GCC High (US Gov L4) | Status |
| --- | --- | --- | --- |
| Device service endpoints | `*.manage.microsoft.com` | `*.manage.microsoft.us` | **Cited** — [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| Device registration (ADRS) | `enterpriseregistration.windows.net` | `enterpriseregistration.microsoftonline.us` | **Cited** — [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| EPM / Defender security mgmt | `*.dm.microsoft.com` | `*.dm.microsoft.us` | **Cited** — [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |
| SSL inspection on device endpoints | — | **Not supported** on `*.manage.microsoft.us` (and Defender/EPM endpoints) | **Cited** — [Intune US Gov endpoints](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints) |

**Practical consequence:** a TLS-breaking proxy on `*.manage.microsoft.us` is the leading cause of custom-compliance results never returning — a *silent* failure that looks like "not evaluated." Exempt these hosts.

## 4. Feature parity and availability

- **National clouds may lack some global-service features.** Microsoft states plainly that "certain services and features that are in specific regions of the global service might not be available in all national clouds," and points to Product Availability by Region. **Cited** — [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments).
  - *Practical consequence:* before you rely on any newer custom-compliance option, Conditional Access integration, or platform (e.g., Linux custom compliance) in GCC High, **verify it is live in your tenant.** Do not assume commercial documentation applies.
- **Custom compliance capability itself.** The Microsoft custom-compliance documentation (discovery script + JSON rules, `ConvertTo-Json -Compress`, 1 MB / 10-minute limits, one-script-per-policy, Default-scope-tag requirement) is written for Intune generally and does **not** call out a GCC High exception. This solution treats those mechanics as applicable to GCC High, **but** because Microsoft's page does not explicitly enumerate GCC High support, treat first-run behavior as **"verify for GCC High"** and confirm on your pilot. **Cited (mechanics)** — [Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script).
- **No third-party MDM/MAM integration in GCC High.** Government references consistently note Intune in GCC High operates as a standalone Azure Government service and cannot integrate third-party MDM/MAM connectors. **Verify for GCC High** — Microsoft government guidance / partner references; confirm against your Microsoft government account team.
- **Feature lag is a scheduling reality.** New Intune features commonly reach government clouds after commercial. Plan rollouts assuming a GCC High capability may arrive later than its commercial announcement. **Verify for GCC High** — general Microsoft government-cloud guidance.

## 5. What this means for the solution

1. Use **only** the `*.us` portals for every click-step.
2. Use **`-Environment USGov`** for every script and confirm `(Get-MgContext).Environment = USGov`.
3. **Pilot first** and confirm the custom-compliance mechanics actually grade in your GCC High tenant before scaling — because the mechanics are documented generally, not GCC-High-specifically.
4. **Protect the device endpoints** from SSL inspection, or expect silent "no result" failures.
5. Where a row above says **"verify for GCC High,"** confirm it live before you depend on it in production.
