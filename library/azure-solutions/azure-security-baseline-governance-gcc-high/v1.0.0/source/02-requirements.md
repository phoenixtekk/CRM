# Requirements — Azure Security Baseline & Governance (Government / GCC High)

These are the solution-specific prerequisites for deploying the security baseline & governance guardrails on an **Azure Government / GCC High** tenant. They layer on top of the platform baseline in `global-requirements-azure-solutions.md` (tenant, admin roles, licensing, connectivity, change control, rollback).

Each requirement is structured **Description / Why / Verify / Implement-if-missing**. Every "Verify" step uses the **Azure Government** sovereign portal (`portal.azure.us`) or a US Gov PowerShell endpoint — never the Commercial equivalents.

> Reminder: sign in at **`https://portal.azure.us`** (Azure) and **`https://portal.office365.us`** (Microsoft 365 / Entra admin). If you land on `portal.azure.com`, you are in the wrong cloud and none of the steps below apply.

---

## R1. An Azure Government subscription in a GCC High / Azure Government tenant

- **Description:** An active subscription hosted in Azure Government (US Gov regions), in a tenant whose identity is homed in `login.microsoftonline.us`.
- **Why:** All governance objects (management groups, policy, RBAC, Defender for Cloud) are created inside this subscription/tenant. A Commercial subscription cannot be governed by Gov-cloud objects, and the two clouds do not share portals or data. Source: [Compare Azure Government — Azure Monitor FAQ](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-monitor).
- **Verify:** Sign in to **`https://portal.azure.us`** → **Subscriptions**. Confirm at least one subscription is **Active** and its region shows a US Gov region (`USGov Virginia`, `USGov Texas`, `USGov Arizona`, or DoD). In PowerShell: `Connect-AzAccount -Environment AzureUSGovernment` then `Get-AzSubscription`.
- **Implement-if-missing:** Provision an Azure Government subscription through an authorized government channel (AOS-G reseller or an existing Gov Enterprise Agreement). Azure Government access is limited to eligible US government entities and their partners.

## R2. US Government licensing (Microsoft 365 G3/G5 Government + Azure plan)

- **Description:** Government SKUs for any identity/security features used — e.g. **Microsoft 365 G3/G5 Government** (GCC High) for Entra ID P1/P2 and Defender workloads, plus the Azure plan for Defender for Cloud paid plans.
- **Why:** Conditional Access, PIM-adjacent controls, and Defender features are gated by Government license SKUs; Commercial SKUs do not apply to a GCC High tenant. Microsoft Entra ID P1/P2 feature availability in Gov has known limitations. Source: [Compare Azure Government — Microsoft Entra ID P1 and P2](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#microsoft-entra-id-p1-and-p2).
- **Verify:** In **`https://portal.office365.us`** → **Billing → Licenses**, confirm the Government SKUs are present and assigned. For Defender for Cloud, no separate license is needed — the paid plans bill per resource once enabled on the subscription.
- **Implement-if-missing:** Procure the correct **Government** SKUs (not Commercial) through your Gov licensing channel. Confirm subscription quota for Log Analytics ingestion and any VMs to be protected.

## R3. Administrative roles (least privilege) in the Gov tenant

- **Description:** The roles needed to build the baseline: **Global Administrator** (or Privileged Role Administrator) for tenant-level Entra changes, **Owner** at the management-group root (or the target subscription) to create MGs, custom roles, and policy assignments, and **Security Admin** for Defender for Cloud.
- **Why:** Creating management groups and assigning policy at the root requires elevated scope; Defender plan changes require Security Admin. Least-privilege scoping limits blast radius and satisfies FedRAMP High audit expectations.
- **Verify:** In **`portal.azure.us`** → **Microsoft Entra ID → Roles and administrators**, confirm your operating account holds the directory roles. In **Management groups → (root) → Access control (IAM)**, confirm the `Owner`/`User Access Administrator` assignment. Note: in Azure Government, **Azure Lighthouse PIM (eligible/JIT) is not enabled**, so "eligible" activation is unavailable — roles here are standing assignments. Source: [Compare Azure Government — Azure Lighthouse](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-lighthouse).
- **Implement-if-missing:** Assign the minimum roles needed at the highest scope you actually need (prefer management-group scope over per-subscription). Document standing assignments as a compensating control where PIM-eligible access would normally be used.

## R4. Management-group access enabled and root scope reachable

- **Description:** The ability to manage the tenant's **management group** hierarchy (the `Tenant Root Group` and children).
- **Why:** This baseline applies policy and RBAC by inheritance from management groups. Management groups are available in Azure Government. Source: [Compare Azure Government — Management and governance](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#management-and-governance).
- **Verify:** In **`portal.azure.us`** → search **Management groups**. If prompted, click **Start using management groups**. Confirm you can see the `Tenant Root Group`. In PowerShell: `Get-AzManagementGroup`.
- **Implement-if-missing:** A Global Administrator must **elevate access** (Entra ID → Properties → *Access management for Azure resources* → Yes) once to gain `User Access Administrator` at root, create the hierarchy, then remove the elevation. This behaves as in Commercial but is performed in `portal.azure.us`.

## R5. Microsoft Defender for Cloud available and plan scope confirmed for Azure Government

- **Description:** Defender for Cloud reachable on the subscription, with awareness of **which paid plans are available in Azure Government**.
- **Why:** Several Defender for Cloud plans and features are **Not Available** in Azure Government. Enabling an unavailable plan is impossible and wastes time; the baseline must enable only Gov-available plans. Source: [Cloud feature availability — Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud).
- **Verify:** In **`portal.azure.us`** → **Microsoft Defender for Cloud → Environment settings → (subscription) → Defender plans**. Confirm the available plans render. **Available in Azure Government:** Defender for Servers, Storage, Key Vault, Resource Manager, Containers, DNS, Azure SQL, SQL on machines, open-source relational DBs. **Not Available in Azure Government (do not attempt):** Defender for App Service, Defender for Azure Cosmos DB, Defender for Foundry/AI tools; feature-level: Adaptive network hardening, Integrated VA for machines (legacy), AWS/GCP connectors, recommendation exemption rules.
- **Implement-if-missing:** If Defender for Cloud does not render, confirm the subscription is registered for the `Microsoft.Security` resource provider (**Subscriptions → Resource providers → Microsoft.Security → Register**). Then enable only the Gov-available plans.

## R6. Log Analytics workspace capacity in a US Gov region

- **Description:** A Log Analytics workspace (this baseline creates `Governance Logs Workspace – Platform – Pilot`) in a US Gov region to receive activity and diagnostic logs.
- **Why:** Centralized audit logging is the evidence layer for governance and is required by FedRAMP High controls. Azure Monitor / Log Analytics is available in Azure Government but uses the `oms.microsoft.us` / `*.opinsights.azure.us` endpoints, and **workspaces/data cannot be migrated between Commercial and Gov**. Source: [Compare Azure Government — Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-monitor).
- **Verify:** In **`portal.azure.us`** → **Log Analytics workspaces**, confirm you can create a workspace in a US Gov region. Confirm ingestion quota under **Subscriptions → Usage + quotas**.
- **Implement-if-missing:** Create the workspace in the target Gov region (the Implementation Guide does this by the exact name). Ensure firewall/proxy allows `*.oms.microsoft.us`, `*.ods.opinsights.azure.us`, and `*.ods.opinsights.azure.us`.

## R7. Network egress to Azure Government (`*.us` / `usgovcloudapi.net`) endpoints

- **Description:** Firewall/proxy allowances for the **Azure Government** endpoint set, not the Commercial set.
- **Why:** Every portal action and script call targets `*.us` / `*.usgovcloudapi.net` hosts. If only Commercial endpoints are allowed, sign-in and management calls fail silently or with TLS/redirect errors. Source: [Compare Azure Government — endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers).
- **Verify:** From an admin workstation, confirm reachability to `login.microsoftonline.us`, `management.usgovcloudapi.net`, `graph.microsoft.us`, `portal.azure.us`, and `*.opinsights.azure.us` (HTTPS/443).
- **Implement-if-missing:** Add the Azure Government endpoint set to the allow-list. Use `Get-AzEnvironment -Name AzureUSGovernment` to enumerate the exact endpoints your tooling will call.

## R8. PowerShell modules pinned for US Gov connectivity

- **Description:** Current **Az** PowerShell module and **Microsoft.Graph** PowerShell module installed, capable of the `AzureUSGovernment` / `USGov` environment switches.
- **Why:** The five solution scripts connect exclusively to US Gov endpoints via `-Environment AzureUSGovernment` (Az) and `-Environment USGov` (Graph). Older or missing modules will not resolve the Gov environment. Source: [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments).
- **Verify:** `Get-Module Az.Accounts,Az.Resources,Az.Security -ListAvailable` and `Get-Module Microsoft.Graph.Authentication -ListAvailable`. Confirm `Get-AzEnvironment -Name AzureUSGovernment` returns endpoints and `(Get-MgEnvironment).Name` includes `USGov`.
- **Implement-if-missing:** `Install-Module Az -Scope CurrentUser` and `Install-Module Microsoft.Graph -Scope CurrentUser`. Re-open PowerShell and re-verify the environment switches resolve.
