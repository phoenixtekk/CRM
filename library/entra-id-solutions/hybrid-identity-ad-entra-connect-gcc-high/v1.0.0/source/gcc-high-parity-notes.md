# GCC High Parity Notes — Hybrid Identity (cited)

A cited, Commercial-vs-GCC-High reference for the features this solution touches. **Availability is
as published by Microsoft** at the sources shown; where Microsoft has not published a definitive
statement it is marked **"verify for GCC High."** Never assume Commercial behavior — GCC High feature
rollout can lag, and endpoints always differ.

> Primary sources:
> - [Microsoft Entra feature availability in Azure for US Government](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability)
> - [Microsoft Entra Connect: Sync service instances (Microsoft Azure Government)](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)
> - [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments)
> - [Microsoft 365 U.S. Government GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## Portals & endpoints

| Surface | Commercial | GCC High | Source |
| --- | --- | --- | --- |
| Sign-in / token authority | `login.microsoftonline.com` | `login.microsoftonline.us` | Graph deployments |
| Azure portal | `portal.azure.com` | `portal.azure.us` | Graph deployments |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` | Graph deployments |
| Microsoft Graph (DoD/L5) | `graph.microsoft.com` | `dod-graph.microsoft.us` | Graph deployments |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` | GCC High endpoints (auth surface) |
| M365 admin | `admin.microsoft.com` | `portal.office365.us` | GCC High endpoints |
| Security | `security.microsoft.com` | `security.microsoft.us` | GCC High endpoints |
| Compliance / Purview | `compliance.microsoft.com` | `compliance.microsoft.us` / `purview.microsoft.us` | GCC High endpoints |
| Graph PowerShell `-Environment` | `Global` | `USGov` (DoD: `USGovDoD`) | Graph deployments |

## Entra Connect sync service instance (Azure Government)

URLs to open on the proxy for the **US Gov** sync instance
([Sync service instances](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-instances#microsoft-azure-government)):

- `*.microsoftonline.com`
- `*.microsoftonline.us`
- `*.windows.net` — **required for automatic Azure Government tenant detection**
- `*.gov.us.microsoftonline.com` — US Gov sync service (`syncservice.gov.us.microsoftonline.com`)
- Certificate Revocation Lists

**Cloud selection during install:** As of Entra Connect **1.1.647.0**, setting the registry
`AzureInstance` value is no longer required **provided `*.windows.net` is open** (auto-detection).
For hosts without Internet egress, pause the wizard at the EULA, set
`HKLM\SOFTWARE\Microsoft\Azure AD Connect\AzureInstance` = **`4`** (Azure US Government), then use the
**Custom** installation path. Same source.

## Sign-in / hybrid identity feature parity

| Feature | Azure for US Government | Notes | Source |
| --- | --- | --- | --- |
| Password Hash Synchronization (PHS) | ✅ Available | Recommended default | Feature availability |
| Pass-through Authentication (PTA) | ✅ Available | Agents must register to Gov endpoints | Feature availability |
| Federation (AD FS / other IdP) | ✅ Available | For hard STS requirements | Feature availability |
| Single sign-on (SSO) unlimited | ✅ Available | Includes Seamless SSO | Feature availability |
| MFA | ✅ Available | | Feature availability |
| Passwordless (WHfB, Authenticator, FIDO2) | ✅ Available | | Feature availability |
| Certificate-based authentication | ✅ Available | Relevant for PIV/CAC | Feature availability |
| Directory sync — Entra Connect (sync **and** cloud sync) | ✅ Available | Both engines supported | Feature availability |
| Entra Connect Health reporting | ✅ Available | | Feature availability |
| Conditional Access | ✅ Available | | Feature availability |
| SSPR with on-premises write-back | ✅ Available | Includes password writeback | Feature availability |
| Privileged Identity Management (PIM) | ✅ Available | | Feature availability |
| Global/custom banned-password protection (synced users) | ✅ Available | | Feature availability |

## Known gaps to plan around

| Feature | Azure for US Government | Source |
| --- | --- | --- |
| **My Staff** (delegated user-management portal) | ❌ Not available | Feature availability |
| **Microsoft Entra threat intelligence** (ID Protection risk detection) | ❌ Not available | Feature availability |
| **HR-driven provisioning** | ⚠️ Partial (see HR-provisioning apps) | Feature availability |
| **Enterprise State Roaming** (Win10 shared-device sign-out) | ❌ Not available | Feature availability |

> Other ID Protection risk detections (leaked credentials, atypical/impossible travel, password
> spray, malicious/anonymous IP, unfamiliar sign-in properties, new country, etc.) **are** available
> in Azure for US Government per the same table.

## "Verify for GCC High" — validate in a lab before production

- **Exact Gov license SKU entitlements.** Confirm your specific Government bundle (e.g. M365 G3/G5
  Gov) carries Entra ID P1 (P2 for risk-based/PIM). Gov SKU names differ from Commercial.
- **PTA / Seamless SSO agent registration to the Gov cloud** for your specific agent version.
- **DoD (L5) specifics** if you are DoD, not GCC High — Graph root is `dod-graph.microsoft.us` and
  some services differ further; treat L5 as its own validation pass.
- **Current endpoint list.** Always reconcile against the live monthly
  [GCC High endpoints web service](https://endpoints.office.com/endpoints/USGOVGCCHigh) before
  finalizing firewall rules.

---
The deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
