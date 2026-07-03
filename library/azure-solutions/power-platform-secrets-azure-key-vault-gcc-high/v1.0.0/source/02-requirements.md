# Requirements — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

These solution-specific requirements are layered on top of the **Global Requirements — Azure Solutions** (`global-requirements-azure-solutions.md`, items G1–G6). Read those first; this file adds what is specific to Power Platform + Azure Key Vault secrets on a **GCC High** tenant.

Each requirement is structured **Description / Why / Verify / Implement-if-missing**. Where a point is GCC-High-specific and not confirmed in public Microsoft US Gov docs, it is flagged **"verify for GCC High."**

> Naming convention (reused throughout): every created object is named `<Purpose> – <Scope> – <Stage>`.

---

## R1. A GCC High Power Platform tenant with a target environment

- **Description:** An active **Power Apps US Government — GCC High** deployment with at least one Power Platform environment (Dataverse enabled) to pilot in.
- **Why:** Environment-variable secrets are a Dataverse/solution capability; there must be a Dataverse-backed environment to hold the environment variable and the solution it lives in.
- **Verify:** Sign in to `https://high.admin.powerplatform.microsoft.us` (GCC High admin center) and confirm the environment exists with **Dataverse** provisioned. Confirm the environment region is a US Gov region (US Gov Virginia / US Gov Texas).
- **Implement-if-missing:** In the GCC High admin center, **Environments → New**, choose a US Gov region, and enable Dataverse. Provision through an authorized AOS-G channel if the tenant itself is not yet GCC High.

## R2. An Azure Government subscription in the same tenant

- **Description:** An **Azure Government** subscription bound to the same Microsoft Entra Government tenant as the Power Platform environment.
- **Why:** The Key Vault must be in the **same tenant** as the Power Platform subscription — cross-tenant references are not supported. Government Power Platform runs on Azure Government, so the vault must be an Azure Government vault.
- **Verify:** Sign in to `https://portal.azure.us` (Azure Government portal). Confirm the subscription's directory matches the Power Platform tenant. Confirm the subscription resolves under Azure Government (ARM endpoint `management.usgovcloudapi.net`).
- **Implement-if-missing:** Obtain/associate an Azure Government subscription in the correct tenant. Do **not** use a Commercial (`portal.azure.com`) subscription — it is a different cloud and will not be reachable from GCC High Power Platform.

## R3. `Microsoft.PowerPlatform` resource provider registered

- **Description:** The **`Microsoft.PowerPlatform`** resource provider registered on the Azure Government subscription that holds the vault.
- **Why:** Power Platform's ability to read the referenced Key Vault secret depends on this provider being registered in the subscription. (Microsoft Learn: *Use environment variables for Azure Key Vault secrets → Configure Azure Key Vault*.)
- **Verify:** `portal.azure.us` → **Subscriptions → Resource providers**, search `Microsoft.PowerPlatform`, confirm **Registered**. Or run `PPKVG-Discovery.ps1` / `PPKVG-Validation.ps1`.
- **Implement-if-missing:** Register it — portal (**Register**) or `Register-AzResourceProvider -ProviderNamespace Microsoft.PowerPlatform` (connected with `-Environment AzureUSGovernment`), or `PPKVG-Remediation.ps1 -Apply`.

## R4. Azure Key Vault(s) on the Azure RBAC permission model

- **Description:** One Azure Government Key Vault **per Power Platform environment** (recommended), configured with **Permission model = Azure role-based access control**.
- **Why:** Microsoft's service evaluates access using the Azure RBAC APIs even if the vault is still on the legacy vault-access-policy model; standardizing on RBAC avoids ambiguity and matches current guidance. A vault per environment limits blast radius if one is breached.
- **Verify:** `portal.azure.us` → the vault → **Settings → Access configuration** → confirm **Azure role-based access control**. Or `PPKVG-Validation.ps1` (reports `Permission model = RBAC`).
- **Implement-if-missing:** Create the vault (`PowerPlatform Secrets – <EnvName> – Prod`) and set the RBAC model, or switch an existing vault via **Access configuration** / `PPKVG-Remediation.ps1 -Apply`.

## R5. Key Vault Secrets User granted to the Dataverse principal and to makers

- **Description:** The **Key Vault Secrets User** role assigned at the vault scope to (a) the **Dataverse first-party service principal** and (b) the makers/operators who create or use the environment variables (via a named Entra group).
- **Why:** Dataverse retrieves the secret on the maker's behalf, so **both** the Dataverse principal and the user need read access to secrets; without it the environment variable fails to save/resolve.
- **Verify:** `portal.azure.us` → vault → **Access control (IAM) → Role assignments**, confirm **Key Vault Secrets User** for the makers group and the Dataverse app. Or `PPKVG-Validation.ps1`.
- **Implement-if-missing:** Assign the role (IAM → Add role assignment) or run `PPKVG-Remediation.ps1 -Apply`.
- **GCC High caveat — verify for GCC High:** The Commercial Dataverse app id is `00000007-0000-0000-c000-000000000000`. In GCC High the first-party principal may appear under a different display name/object id. **Confirm the actual principal** in **Entra ID → Enterprise applications** before assigning; do not assume the Commercial id resolves.

## R6. Network path from Power Platform (US Gov) to the vault

- **Description:** The vault reachable by Power Platform — either public network access with the **Power Platform US Government IP ranges** allowed through the Key Vault firewall, or a **Virtual Network / Private Link** path delegated to Power Platform.
- **Why:** If the Key Vault firewall is on, Power Platform is **not** covered by the "Trusted Services" allowance and must be explicitly allowed; otherwise secret retrieval is blocked.
- **Verify:** vault → **Networking**. If firewall enabled, confirm the current Power Platform US Gov IP ranges are allowed (see Power Platform URLs and IP address ranges for US Gov). Or confirm a Private Link path to a Power Platform-delegated VNet.
- **Implement-if-missing:** Allow the Power Platform US Gov IP ranges, or configure VNet support / Private Link per `03-implementation.md`. **Verify for GCC High:** use the US Gov IP range set, not the Commercial one.

## R7. Admin roles and tooling

- **Description:** **Owner** or **User Access Administrator** on the vault's subscription/resource group (to grant RBAC), plus **System Administrator** in the target Power Platform environment (to create solutions/environment variables). PowerShell 5.1+ or 7+ with **Az.Accounts, Az.KeyVault, Az.Resources**; for any Graph steps, **Microsoft.Graph**.
- **Why:** Role assignment requires an access-admin role; creating the environment variable requires Power Platform admin/maker rights; the scripts require the Az modules and US Gov connection.
- **Verify:** Confirm roles in `portal.azure.us` (IAM) and the GCC High admin center. Confirm modules: `Get-Module Az.KeyVault -ListAvailable`.
- **Implement-if-missing:** Assign the roles (prefer a scoped group over standing individual grants — **note: PIM/JIT is not available in Azure Government**, so use scoped standing access + Conditional Access). Install modules: `Install-Module Az -Scope CurrentUser`.

## R8. Secret hygiene baseline

- **Description:** A naming and rotation standard for secrets (e.g. `Secret – <SystemName> – <EnvName>`), an expiry policy, and, for Copilot Studio consumers, the **`AllowedBots`** / **`AllowedEnvironments`** tag plan.
- **Why:** Standardized names and expiry make rotation and audit repeatable; Copilot Studio will not consume a secret unless the correct scope tag is present.
- **Verify:** Run `PPKVG-Report.ps1` — it flags secrets with no expiry and shows current tags (names/metadata only).
- **Implement-if-missing:** Adopt the naming/expiry standard; set scope tags with `PPKVG-Set-ScopeTargeting.ps1` (WhatIf first).

---

## Requirements checklist

| # | Requirement | Verify with |
| --- | --- | --- |
| R1 | GCC High Power Platform tenant + Dataverse environment | `high.admin.powerplatform.microsoft.us` |
| R2 | Azure Government subscription, same tenant | `portal.azure.us` |
| R3 | `Microsoft.PowerPlatform` provider registered | `PPKVG-Validation.ps1` |
| R4 | Key Vault(s) on Azure RBAC model | `PPKVG-Validation.ps1` |
| R5 | Key Vault Secrets User → Dataverse + makers | `PPKVG-Validation.ps1` (verify Dataverse principal for GCC High) |
| R6 | Network path Power Platform → vault (US Gov IPs / Private Link) | vault → Networking |
| R7 | Admin roles + Az modules (no PIM in Gov) | IAM / `Get-Module` |
| R8 | Secret naming, expiry, Copilot scope tags | `PPKVG-Report.ps1` |
