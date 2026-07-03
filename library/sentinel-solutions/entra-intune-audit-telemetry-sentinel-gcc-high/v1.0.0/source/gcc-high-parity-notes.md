# GCC High Parity Notes — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

A cited reference for how the US sovereign cloud (GCC High / Azure Government) differs from Commercial **for this specific pipeline**. Feature availability changes; every entry below is dated to its source and anything not confirmed in your own tenant should be treated as **"verify for GCC High."** These notes reflect Microsoft documentation reviewed **2026-07-02**.

## 1. Portals and endpoints (what to use instead of Commercial)

| Purpose | Commercial | GCC High / US Gov |
|---|---|---|
| Azure / Sentinel portal | `portal.azure.com` | `portal.azure.us` |
| Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Microsoft Defender portal (unified SecOps) | `security.microsoft.com` | `security.microsoft.us` |
| M365 admin center | `admin.microsoft.com` | `portal.office365.us` |
| Sign-in / auth endpoint | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft Graph service root | `graph.microsoft.com` | `graph.microsoft.us` (L4/GCC High); `dod-graph.microsoft.us` (L5/DoD) |
| Graph PowerShell environment | `-Environment Global` | `-Environment USGov` (GCC High) / `USGovDoD` (DoD) |
| Az PowerShell environment | `AzureCloud` | `AzureUSGovernment` |

Sources:
- Microsoft Graph national cloud deployments — endpoints table for US Government L4 (GCC High) `graph.microsoft.us` and L5 (DoD) `dod-graph.microsoft.us`; portal `portal.azure.us`; Entra ID endpoint `login.microsoftonline.us`. https://learn.microsoft.com/en-us/graph/deployments (reviewed 2026-07-02)
- Microsoft Defender portal service support for US Government customers — GCC High Defender portal `security.microsoft.us`; login `login.microsoftonline.us`; XDR API `api-gov.security.microsoft.us`. https://learn.microsoft.com/en-us/unified-secops/gov-support (page dated 2026-04-14)
- `Connect-MgGraph` reference — use `-Environment USGov` for GCC High. https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph

> Note: `endpoint.microsoft.us` and `intune.microsoft.us` both reach the Intune admin center for Gov; `intune.microsoft.us` is used throughout this solution. Verify the working URL in your tenant.

## 2. Sentinel feature parity for this pipeline

All entries below are from Microsoft's **"Microsoft Sentinel feature support for Azure commercial/other clouds"** (https://learn.microsoft.com/en-us/azure/sentinel/feature-availability), page **dated 2026-05-14**, "Azure Government" column. (The doc's third column is "Azure operated by 21Vianet" — a *different* national cloud, out of scope for GCC High.)

### Supported in Azure Government (this pipeline relies on these)

| Feature | Stage | Azure Government |
|---|---|---|
| Microsoft Entra ID connector | GA | **Yes** |
| Microsoft Entra ID Protection connector | GA | Yes |
| Office 365 connector | GA | Yes |
| Microsoft Defender XDR connector | GA | Yes |
| Microsoft Defender XDR incident integration | GA | Yes |
| Content hub and solutions | GA | Yes |
| Workbooks | GA | Yes |
| Scheduled / Microsoft rules | GA | Yes |
| NRT rules | GA | Yes |
| Fusion (multistage attack detection) | GA | Yes |
| Notebooks | GA | Yes |
| Watchlists | GA | Yes |
| Restore historical data / Search large datasets | GA | Yes |
| Automation rules / playbooks | GA | Yes |

### NOT available in Azure Government (do not design the pipeline around these)

| Feature | Commercial stage | Azure Government |
|---|---|---|
| Repositories (CI/CD content deployment) | Public preview | **No** |
| Codeless Connectors Platform | Public preview | **No** |
| SIEM migration experience | GA | **No** |
| Summary rules | GA | **No** |
| SOC optimizations | Supported for production | **No** |
| Hunts (newer hunting experience) | Public preview | **No** |
| GeoLocation and WhoIs TI enrichment | Public preview | **No** |
| URL detonation | Public preview | **No** |
| Microsoft Defender Threat Intelligence matching analytics | Public preview | **No** |
| Peer/Blast radius UEBA enrichments | Public preview | **No** |

**Implication for this solution:** deploy analytics from **Content hub** and **Analytics rule templates** directly (Repositories/CI-CD and SIEM migration are unavailable). Baseline analytics, NRT, and Fusion all work. Do not rely on Summary rules or SOC optimizations to manage the pipeline. Threat-intel enrichment beyond TAXII / flat-file import is limited.

## 3. Connector data-type caveat (verify for GCC High)

- Microsoft's cross-cloud connector data-type support matrix (https://learn.microsoft.com/en-us/azure/sentinel/data-type-cloud-support) governs which specific *data types* within a connector flow in each cloud. The Entra ID connector is GA in Gov; confirm the exact sign-in categories you intend to route (non-interactive, service-principal, managed-identity, provisioning) are supported for Azure Government in that matrix and are exposed by your Gov Entra SKU before promising them. **Verify for GCC High.**
- Intune audit-log routing to Log Analytics via **Reports → Diagnostics settings** follows the same mechanism documented for Commercial (https://learn.microsoft.com/en-us/intune/governance/integrate-azure-monitor, updated 2026-07-01); the Gov admin center is `intune.microsoft.us`. The doc notes the export pipeline may duplicate up to 100% of data in a 24-hour window and that `DeviceComplianceOrg`/`IntuneDevices` can lag up to 48h — behavior to expect in Gov as well.

## 4. Cross-cloud posture

- A GCC High tenant's Microsoft Entra ID lives in **Azure Government**. Entra ID and Intune audit logs therefore stay within the Azure Government boundary when routed to an Azure Government Log Analytics workspace — **no cross-cloud egress to Commercial Azure is required or desirable.** Keep the workspace and Sentinel in an Azure Government subscription so all telemetry remains on US soil.

## 5. How to keep this current

Re-check the two feature-availability pages (Sentinel feature-availability; Defender portal gov-support) and the connector data-type matrix at each engagement. Note the page's own "date"/"updated_at" and record it. Where a capability is not explicitly listed as available for Azure Government, **do not assume parity — flag it "verify for GCC High" and confirm live in the tenant.**
