# GCC High / Azure Government Parity Notes

A concise Commercial-vs-Azure-Government reference for this solution. Each row states the Commercial behavior, the Azure Government behavior, and either a **Microsoft doc URL** (doc-confirmed) or a **"verify for Azure Government"** flag where the Microsoft docs do not confirm the Gov specific and the Commercial path is given as the fallback.

> Rule followed throughout this solution: never invent a GCC High specific. If it is not in a cited Microsoft doc, it is flagged **verify**.

---

## Portals & endpoints (doc-confirmed)

| Item | Commercial | Azure Government | Source |
| --- | --- | --- | --- |
| Azure portal | `portal.azure.com` | `portal.azure.us` | [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |
| Resource Manager (ARM) | `management.azure.com` | `management.usgovcloudapi.net` | [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |
| Entra sign-in authority | `login.microsoftonline.com` | `login.microsoftonline.us` | [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |
| Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` (DoD: `dod-graph.microsoft.us`) | [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| M365 / Entra admin | `admin.microsoft.com` | `portal.office365.us` | [feature availability — M365 integration](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-365-integration) |
| Key Vault | `vault.azure.net` | `vault.usgovcloudapi.net` | [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |
| Storage (blob) | `blob.core.windows.net` | `blob.core.usgovcloudapi.net` | [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |
| Log Analytics data | `*.opinsights.azure.com` | `*.opinsights.azure.us` / `oms.microsoft.us` | [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |
| Intune enrollment | `manage.microsoft.com` | `manage.microsoft.us` | [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |

## PowerShell / CLI environment switches (doc-confirmed)

| Tool | Commercial | Azure Government | Source |
| --- | --- | --- | --- |
| Az PowerShell | `Connect-AzAccount` | `Connect-AzAccount -Environment AzureUSGovernment` | [Connect with PowerShell](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps) |
| Enumerate endpoints | `Get-AzEnvironment` | `Get-AzEnvironment -Name AzureUSGovernment` | [Compare Azure Gov](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers) |
| Microsoft Graph PS | `Connect-MgGraph` | `Connect-MgGraph -Environment USGov` (DoD: `USGovDoD`) | [Graph national clouds](https://learn.microsoft.com/en-us/graph/deployments) |
| Azure CLI | (default) | `az cloud set --name AzureUSGovernment` | [Connect with CLI](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-cli) |

## Regions (doc-confirmed)

- Gov regions: `usgovvirginia`, `usgovtexas`, `usgovarizona`; DoD: `usdodeast`, `usdodcentral`. Display names have **no space** between `US`/`Gov` and `US`/`DoD` (e.g. `USGov Virginia`). Commercial regions (`eastus`, etc.) do not exist in Gov. Source: [Connect with PowerShell — regions](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).

---

## Microsoft Defender for Cloud parity (doc-confirmed)

Source for all rows: [Cloud feature availability for commercial and US Government customers](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud) (Microsoft Learn, updated 2026).

| Feature / plan | Commercial | Azure Government | Impact on this baseline |
| --- | --- | --- | --- |
| Defender for Servers | GA | GA | Enable |
| Defender for Storage | GA | GA | Enable |
| Defender for Key Vault | GA | GA | Enable |
| Defender for Resource Manager | GA | GA | Enable |
| Defender for Containers | GA | GA | Enable |
| Defender for DNS | GA | GA | Enable |
| Defender for Azure SQL / SQL on machines / OSS DBs | GA | GA | Enable |
| **Defender for App Service** | GA | **Not Available** | Do not enable |
| **Defender for Azure Cosmos DB** | GA | **Not Available** | Do not enable |
| **Defender for Foundry / AI tools** | GA | **Not Available** | Do not enable |
| **Recommendation exemption rules** | Public Preview | **Not Available** | Use Azure Policy exemptions instead |
| **Adaptive network hardening** | GA | **Not Available** | Not part of baseline in Gov |
| **Integrated VA for machines (legacy)** | GA | **Not Available** | Use Defender for Servers MDVM integration (verify plan coverage) |
| **Connect AWS / GCP account** | GA | **Not Available** | Azure-Gov-only baseline; no multicloud |
| File integrity monitoring | GA | GA (GCCM: not supported) | Available; GCC Moderate exception noted |
| Regulatory compliance dashboard | GA | GA | Available; standards offered may differ |

---

## Identity & governance parity (doc-confirmed)

| Item | Commercial | Azure Government | Source |
| --- | --- | --- | --- |
| Azure Lighthouse PIM (eligible/JIT) authorization | Available | **Not enabled** | [Compare — Azure Lighthouse](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-lighthouse) |
| Azure Lighthouse cross-cloud delegation | Available | **Not supported** | [Compare — Azure Lighthouse](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-lighthouse) |
| Entra MFA **Trusted IPs** | Available | **Not supported** (use Conditional Access named locations) | [Compare — Entra ID](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#microsoft-entra-id-p1-and-p2) |
| Azure AD B2C | Available | **Not available** | [Compare — Azure AD B2C](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-active-directory-b2c) |
| Entra B2B collaboration | GA | Limited in Gov | [Compare — Entra ID](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#microsoft-entra-id-p1-and-p2) |
| Management groups | GA | GA | [Compare — Management and governance](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#management-and-governance) |
| Azure Policy | GA | GA (Allowed Locations must be Gov regions) | [Compare — Management and governance](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#management-and-governance) |
| Azure Advisor | GA | Sovereign-cloud variations | [Compare — Azure Advisor](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-advisor) |
| Log Analytics data migration Commercial↔Gov | N/A | **Not possible** | [Compare — Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-monitor) |

---

## Items to verify per-tenant (flagged — not asserted)

These depend on tenant licensing, region, or Microsoft's rolling parity updates. The Commercial path is the fallback; **verify for Azure Government** in your specific tenant before relying on them:

- **Exact set of regulatory-compliance standards** offered in your Gov subscription (Microsoft notes "differences in the standards offered per cloud type"). Confirm which standards render in **Defender for Cloud → Regulatory compliance**. *(verify for Azure Government)*
- **Microsoft Defender Vulnerability Management** feature depth under Defender for Servers in your Gov region (the legacy integrated VA is gone; MDVM coverage should be confirmed). *(verify for Azure Government)*
- **Specific built-in policy initiative** availability (e.g. a given compliance initiative version) — built-in policy definitions can lag in Gov. Confirm the initiative you intend to assign exists in `portal.azure.us`. *(verify for Azure Government)*
- **Secure Score control coverage** parity for niche controls tied to Not-Available plans (App Service/Cosmos DB controls will not apply). *(verify for Azure Government)*
- **Newer Defender for Cloud preview features** — Public Preview items frequently show **Not Available** in Gov first. Check the feature-availability page at the time of deployment. *(verify for Azure Government)*

> When in doubt, run `Get-AzEnvironment -Name AzureUSGovernment`, check the [feature availability page](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability), and confirm in `portal.azure.us`. Never assume Commercial parity.
