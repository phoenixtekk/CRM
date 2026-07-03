# Solution Overview — Azure Security Baseline & Governance (Government / GCC High)

This is the **Government (GCC High / Azure Government) edition** of the Azure Security Baseline & Governance solution. It deploys a least-privilege, secure-configuration, guardrail-based governance baseline on a **US sovereign cloud** tenant — using the correct `*.us` sovereign portals and US Gov service endpoints, with every Commercial-vs-Azure-Government difference called out at the point where it matters.

> This edition is **not** the Commercial portal reached through a different sign-in. Azure Government is a physically isolated cloud with its own portal (`portal.azure.us`), its own Resource Manager endpoint (`management.usgovcloudapi.net`), its own identity authority (`login.microsoftonline.us`), and a set of feature-parity gaps versus Commercial. Following Commercial steps on a GCC High tenant leads to wrong URLs, features that appear missing, and silent failures. Source: [Compare Azure Government and global Azure](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure).

---

## What this solution delivers

A repeatable, pilot-first deployment of the core Azure governance guardrails on an Azure Government subscription:

1. **Management-group structure** — a governance hierarchy (`Governance Root MG` → `Platform MG`, `Landing Zones MG`) so policy and RBAC apply by inheritance rather than per-subscription.
2. **Least-privilege RBAC** — custom and built-in role assignments scoped at the management-group / subscription level, replacing broad standing `Owner`/`Contributor` grants.
3. **Azure Policy guardrails** — a assigned policy initiative (`Security Baseline Initiative – Governance Root – Pilot`) enforcing secure configuration (deny public storage, require encryption, allowed locations = US Gov regions, audit missing diagnostic settings).
4. **Microsoft Defender for Cloud** — enabled on the subscription with the Foundational CSPM (free) tier and the paid Defender plans **that are available in Azure Government**, plus Secure Score tracking.
5. **Diagnostic + audit logging** — a Log Analytics workspace (`Governance Logs Workspace – Platform – Pilot`) receiving activity and resource logs for audit evidence.

Every object is named `<Purpose> – <Scope> – <Stage>` (e.g. `Security Baseline Initiative – Governance Root – Pilot`) and reused verbatim across the guide, scripts, and validation.

## Deployment model

The solution follows the standard **Assess → Configure → Pilot → Validate → Expand** model with an explicit pass/fail gate at each stage:

| Stage | Goal | Pass/fail gate |
| --- | --- | --- |
| **Assess** | Inventory current subscriptions, roles, policy state, Defender coverage in the Gov tenant. | Discovery script returns a clean baseline report; no blocking prerequisite gaps. |
| **Configure** | Build the MG structure, custom roles, policy initiative, Defender plans, workspace — **in audit/`-WhatIf` mode first**. | All objects created with the exact names; policy in `Audit`/`AuditIfNotExists` effect. |
| **Pilot** | Apply guardrails to **one pilot subscription** only. | Validation script passes on the pilot scope; no unexpected `Deny` blocks legitimate work. |
| **Validate** | Confirm compliance, Secure Score movement, log flow, no broken access. | Validation + Report scripts show target compliance; sign-off recorded. |
| **Expand** | Move guardrails to remaining subscriptions via `Set-ScopeTargeting`. | Expanded scope passes validation; rollback rehearsed. |

## Who this is for

A competent-but-novice Azure administrator operating a **GCC High / Azure Government** tenant who needs to stand up governance guardrails correctly the first time, without assuming Commercial behavior. No prior Azure Government experience is assumed; every portal path uses `portal.azure.us` and every script connects with `-Environment AzureUSGovernment` (Az) / `-Environment USGov` (Microsoft Graph).

---

## Commercial vs Azure Government — what's different

This is the single most important section to read before starting. If you have deployed this baseline in Commercial Azure, **do not** reuse those URLs, endpoints, or feature assumptions. The table below is the summary; the companion file `gcc-high-parity-notes.md` carries the full list with a Microsoft doc URL or a "verify" flag for each item.

### Portals and endpoints (always different)

| Purpose | Commercial (do NOT use here) | Azure Government (use this) |
| --- | --- | --- |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Azure Resource Manager | `management.azure.com` | **`management.usgovcloudapi.net`** |
| Entra ID / sign-in authority | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph | `graph.microsoft.com` | **`graph.microsoft.us`** (DoD: `dod-graph.microsoft.us`) |
| Microsoft 365 / Entra admin | `admin.microsoft.com` / `entra.microsoft.com` | **`portal.office365.us`** / Entra via `portal.azure.us` |
| Key Vault | `vault.azure.net` | **`vault.usgovcloudapi.net`** |
| Storage (blob) | `blob.core.windows.net` | **`blob.core.usgovcloudapi.net`** |
| Log Analytics workspace portal | `mms.microsoft.com` | **`oms.microsoft.us`** |

Source: [Compare Azure Government and global Azure — endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers).

### PowerShell / CLI connection (always different)

- **Az PowerShell:** `Connect-AzAccount -Environment AzureUSGovernment`. Confirm endpoints with `Get-AzEnvironment -Name AzureUSGovernment`. Source: [Connect to Azure Government with PowerShell](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).
- **Microsoft Graph PowerShell:** `Connect-MgGraph -Environment USGov` (GCC High) or `-Environment USGovDoD` (DoD). Source: [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments).
- **Azure CLI:** `az cloud set --name AzureUSGovernment` before `az login`. Source: [Connect to Azure Government with Azure CLI](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-cli).

### Region names (always different)

Azure Government resources deploy only to Gov regions: `usgovvirginia`, `usgovtexas`, `usgovarizona` (and DoD: `usdodeast`, `usdodcentral`). The **Allowed Locations** policy in this baseline is set to these values — never `eastus`/`westus`. Source: [Connect to Azure Government with PowerShell — regions](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).

### Feature parity gaps that affect THIS baseline (doc-confirmed)

Per Microsoft's [Cloud feature availability for commercial and US Government customers](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability) (updated 2026), the following are **Not Available** in Azure Government and change how you build this baseline:

- **Microsoft Defender for Cloud — recommendation exemption rules** → Not Available. Plan governance around this: you cannot exempt individual recommendations; use policy exemptions or scope instead.
- **Defender for App Service, Defender for Azure Cosmos DB, Defender for Foundry/AI tools** → Not Available. Do **not** attempt to enable these plans; the baseline enables only the Gov-available plans (Servers, Storage, Key Vault, Resource Manager, Containers, SQL, DNS, open-source DBs).
- **Adaptive network hardening** and **Integrated vulnerability assessment for machines** (the legacy built-in VA) → Not Available. Use Defender for Servers' Microsoft Defender Vulnerability Management integration instead (verify plan coverage in your tenant).
- **Connect AWS / GCP account** (multicloud) → Not Available. This baseline is Azure-Gov-only; do not scope multicloud connectors.
- **Azure Lighthouse PIM (eligible/JIT) authorization** → Not enabled in Azure Government. If your RBAC design assumed PIM-eligible delegated access via Lighthouse, that path is unavailable — use standing scoped RBAC and document the compensating control. Source: [Compare Azure Government — Azure Lighthouse](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-lighthouse).
- **Microsoft Entra multifactor authentication — Trusted IPs** → Not supported in Azure Government. Use **Conditional Access named locations** instead. Source: [Compare Azure Government — Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#microsoft-entra-id-p1-and-p2).
- **Azure AD B2C** → Not available in Azure Government (not used by this baseline, noted for completeness).

Everything else in this baseline — management groups, Azure Policy, custom RBAC roles, Log Analytics, Secure Score — is available in Azure Government and behaves as in Commercial, only via the `*.us` portals and endpoints. Where a specific sub-feature is not confirmed in the Microsoft docs above, this guide states the Commercial path and flags it **"verify for Azure Government"** rather than asserting parity.

---

## What you will have at the end

- A named management-group governance hierarchy on your Gov tenant.
- A least-privilege RBAC model with the broad standing grants removed or reduced.
- An assigned Azure Policy security-baseline initiative enforcing secure configuration, proven on a pilot subscription.
- Microsoft Defender for Cloud enabled with the Gov-available plans and a tracked Secure Score.
- Centralized audit logging in a named Log Analytics workspace.
- Evidence: discovery, validation, and report outputs proving the baseline is in place — all read from US Gov endpoints.
