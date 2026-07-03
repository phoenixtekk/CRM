# GCC High Parity Notes — Standardize Power Platform Secrets in Azure Key Vault

A cited reference for how the **US sovereign cloud (GCC High + Azure Government)** differs from Commercial for this solution. Every factual claim is either **cited** to Microsoft documentation or explicitly flagged **"verify for GCC High"** where public US Gov docs do not confirm it. Nothing here is invented.

> As-of date: July 2026. Endpoints and availability change — re-verify against the live Microsoft docs before an engagement.

---

## 1. Portals and service URLs

| Purpose | Commercial | GCC High | Source |
| --- | --- | --- | --- |
| Power Apps maker | `make.powerapps.com` | `make.high.powerapps.us` | [Power Apps US Government service URLs][ppusg] |
| Power Automate | `flow.microsoft.com/connectors` | `high.flow.microsoft.us/connectors` | [Power Apps US Government service URLs][ppusg] |
| Power Platform admin center | `admin.powerplatform.microsoft.com` | `high.admin.powerplatform.microsoft.us` | [Power Apps US Government service URLs][ppusg] |
| Power Apps play/runtime | `apps.powerapps.com` | `apps.high.powerapps.us` | [Power Apps US Government service URLs][ppusg] |
| Azure portal | `portal.azure.com` | `portal.azure.us` | [Compare Azure Government and global Azure][cmp] |
| Azure Resource Manager | `management.azure.com` | `management.usgovcloudapi.net` | [Compare Azure Government and global Azure][cmp] |
| Key Vault (data plane DNS) | `vault.azure.net` | `vault.usgovcloudapi.net` | [Compare Azure Government and global Azure][cmp] |
| Managed HSM | `managedhsm.azure.net` | `managedhsm.usgovcloudapi.net` | [Compare Azure Government and global Azure][cmp] |
| Entra sign-in | `login.microsoftonline.com` | `login.microsoftonline.us` | [Compare Azure Government and global Azure][cmp] |

> Note on GCC vs GCC High vs DoD: the maker portal is `make.gov.powerapps.us` (GCC), `make.high.powerapps.us` (**GCC High**), and `make.apps.appsplatform.us` (DoD). This solution targets **GCC High** — use the `.high.` / `.us` forms above. Source: [Power Apps US Government service URLs][ppusg].

## 2. Identity plane

- GCC High **requires Microsoft Entra Government** for customer identities, in contrast to GCC which uses public Microsoft Entra ID. Source: [Power Apps US Government][ppusg].
- Consequence: service principals, security groups, and RBAC assignments used by this solution live in the `.us` identity plane; sign-in and token acquisition go through `login.microsoftonline.us`. Source: [Compare Azure Government and global Azure — Identity][cmp].

## 3. Network allowlists (firewall)

- Power Platform US Government requires allowing a distinct domain/IP set. GCC High customers must allow domains including `*.microsoft.us`, `*.powerapps.us`, `*.azure.us`, `*.usgovcloudapi.net`, `*.microsoftonline.us`, `*.microsoftdynamics.us`, `*.high.powerplatformusercontent.microsoft.us`, and the US Gov IP ranges (focus on `AzureCloud.usgovtexas` / `AzureCloud.usgovvirginia`). Source: [Power Apps US Government — service URLs / required IP ranges][ppusg].
- **Key Vault firewall specific:** Power Platform is **not** covered by "Allow trusted Microsoft services" — its IPs must be allowed explicitly. Source: [Use environment variables for Azure Key Vault secrets — Configure Azure Key Vault, step on Key Vault Firewall][evsecret].

## 4. Azure Key Vault + environment-variable secret feature

The feature mechanics themselves are the same Microsoft-documented flow (no Commercial-vs-Gov divergence is called out in the feature doc — but the doc's examples use Commercial URLs; apply the `.us` equivalents from §1):

- **Prerequisite:** register the **`Microsoft.PowerPlatform`** resource provider in the subscription holding the vault. Source: [Use environment variables for Azure Key Vault secrets][evsecret].
- **Permission model:** Microsoft recommends the **Azure RBAC** permission model; the service evaluates access via the Azure RBAC APIs even if the vault still uses vault access policies. Source: [Use environment variables for Azure Key Vault secrets][evsecret].
- **Role:** **Key Vault Secrets User** must be granted to both the **user/maker** and the **Dataverse service principal** (Application ID `00000007-0000-0000-c000-000000000000` in Commercial). Source: [Use environment variables for Azure Key Vault secrets][evsecret].
- **Same-tenant requirement:** the Key Vault must be in the same tenant as the Power Platform subscription; Azure Key Vault is currently the only supported secret store. Source: [Use environment variables for Azure Key Vault secrets][evsecret].
- **Supported consumers:** Power Automate flows, custom connectors, and Copilot Studio agents only (not general customizations or the API). Source: [Use environment variables for Azure Key Vault secrets — Limitation][evsecret].
- **Copilot Studio scoping:** grant Key Vault Secrets User to **Microsoft Copilot Studio Service**, then tag the secret `AllowedBots = {envId}/{schemaName}` or `AllowedEnvironments = {environmentId}`. Source: [Use environment variables for Azure Key Vault secrets — Copilot Studio][evsecret].
- **Private Link:** environment-variable secrets can connect over Azure Key Vault Private Link via Power Platform VNet support. Source: [Use environment variables for Azure Key Vault secrets — Private link][evsecret].

### Verify for GCC High
- **Dataverse first-party principal object.** Community reporting indicates the first-party principal in a GCC(H) tenant can surface as a differently-named app (for example a "PowerApps Service" first-party app with a different Application ID) rather than the Commercial `00000007-…` id, and Microsoft does not document the Gov id centrally. **Verify for GCC High**: confirm the exact principal in Entra ID → Enterprise applications before granting Key Vault Secrets User. (Uncited by Microsoft; do not assume the Commercial id.)
- **Copilot Studio Service principal** resolving under that name in a GCC High tenant — **verify for GCC High** before relying on it.
- **Feature/preview availability.** Microsoft targets parity but documents exceptions in the [Business Applications US Government — Availability Summary](https://aka.ms/BAPFunctionalParity). Treat any newer/preview capability as **verify for GCC High** until confirmed there.

## 5. Azure Government management differences that affect this solution

- **PowerShell must target the sovereign cloud:** `Connect-AzAccount -Environment AzureUSGovernment` (Az) and `Connect-MgGraph -Environment USGov` (Graph). Source: [Compare Azure Government and global Azure — Guidance for developers / Get-AzEnvironment][cmp].
- **Privileged Identity Management (PIM) / eligible (JIT) authorization is not available in Azure Government** (listed under Azure Lighthouse limitations). This changes least-privilege design: use scoped standing RBAC + Conditional Access, not JIT. Source: [Compare Azure Government and global Azure — Azure Lighthouse][cmp].
- **MFA "Trusted IPs" is not supported** in Azure Government; use Conditional Access named locations instead. Source: [Compare Azure Government and global Azure — Identity][cmp].
- **Azure Key Vault service itself** is available in Azure Government with the endpoint change noted in §1; no Key-Vault-specific feature exclusion is listed in the comparison's Security section. Source: [Compare Azure Government and global Azure — Security][cmp].

---

## Sources

- [Power Apps US Government — service description, URLs, IP ranges, Entra Government requirement][ppusg] — `learn.microsoft.com/power-platform/admin/powerapps-us-government`
- [Use environment variables for Azure Key Vault secrets (feature mechanics, provider, RBAC, Copilot tags, Private Link)][evsecret] — `learn.microsoft.com/power-apps/maker/data-platform/environmentvariables-azure-key-vault-secrets`
- [Compare Azure Government and global Azure (endpoints, PIM, MFA, Key Vault DNS)][cmp] — `learn.microsoft.com/azure/azure-government/compare-azure-government-global-azure`
- Business Applications US Government — Availability Summary — `https://aka.ms/BAPFunctionalParity`

[ppusg]: https://learn.microsoft.com/en-us/power-platform/admin/powerapps-us-government
[evsecret]: https://learn.microsoft.com/en-us/power-apps/maker/data-platform/environmentvariables-azure-key-vault-secrets
[cmp]: https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure
