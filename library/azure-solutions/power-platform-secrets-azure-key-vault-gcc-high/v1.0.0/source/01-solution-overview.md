# Solution Overview — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

## What this solution does

Power Platform makers routinely need secrets — API keys, client secrets, connection strings — to authenticate cloud flows, custom connectors, and Copilot Studio agents. Left to habit, those secrets get pasted into flow steps, connection references, or configuration tables in plain text, where they are hard to rotate, impossible to audit, and easy to leak.

This solution replaces that pattern with the supported, governed approach: store every secret in **Azure Key Vault** and reference it from Power Platform using an **environment variable of type Secret**. The secret value stays in Key Vault; Power Platform holds only a *reference* (subscription, resource group, vault name, secret name). Rotation happens in one place, access is controlled by Azure RBAC, and every read is auditable.

This is the **Government (GCC High) edition**. It is authored for the US sovereign cloud, using the correct `*.us` admin portals and US Government Azure endpoints, and it calls out — explicitly — where GCC High differs from Commercial so a government tenant is configured correctly rather than with Commercial steps that silently fail.

The engagement follows the standard model — **Assess → Configure → Pilot → Validate → Expand**, with a go/no-go gate between each phase — and ships with five read-only-first PowerShell scripts (discovery, validation, reporting, safe remediation, and a Copilot Studio scope-tag builder) that connect to US Government endpoints and **never read secret values** (metadata only).

## What you get

- **This overview**, including the **Commercial vs GCC High — what's different** section below.
- **Requirements guide** (`02-requirements.md`) — every prerequisite with how to verify and implement it, GCC-High-aware.
- **Implementation guide** (`03-implementation.md`) — exact ordered steps using the GCC High portals, with parity caveats inline at the step where they matter.
- **Testing guide** (`05-testing.md`) — pass/fail gates for each phase.
- **Troubleshooting guide** (`06-troubleshooting.md`) — GCC-High-specific gotchas and fixes.
- **Best practices** (`07-best-practices.md`) and a **GCC High parity reference** (`gcc-high-parity-notes.md`) with citations.
- **5 PowerShell scripts** (`scripts/`) — US Gov Graph/Az endpoints (`-Environment AzureUSGovernment`), read-only discovery/validation/report plus WhatIf-by-default remediation and scope-targeting.

## The deployment model (Assess → Configure → Pilot → Validate → Expand)

| Phase | Goal | Gate to advance |
| --- | --- | --- |
| **Assess** | Inventory existing vaults, secrets (by name), permission models, and where Power Platform secrets live today. Confirm GCC High tenant, licensing, roles, and endpoint reachability. | Prerequisites met; a clean discovery report exists. |
| **Configure** | Register the `Microsoft.PowerPlatform` provider, stand up (or adopt) a vault per environment on Azure RBAC, grant Key Vault Secrets User to the Dataverse principal and makers. | Validation script reports all required controls PASS on the pilot vault. |
| **Pilot** | Create one environment-variable secret in a non-production Power Platform environment; consume it from a test flow. | Test flow retrieves the secret successfully; value never appears in run history. |
| **Validate** | Confirm access control, network posture, tagging (for Copilot Studio), and rotation behavior against the pass/fail gates. | All gates in `05-testing.md` pass. |
| **Expand** | Roll the pattern out per environment (a vault per environment), migrate remaining plaintext secrets, and hand off runbooks. | Governance report clean; operators trained. |

## Named, reused objects

Every object created is named `<Purpose> – <Scope> – <Stage>` and reused verbatim thereafter. Examples used throughout this solution:

- **Key vault:** `PowerPlatform Secrets – <EnvName> – Prod` (one vault per Power Platform environment).
- **Admin/maker group:** `Key Vault Secrets – Makers – <EnvName>` (Entra security group granted Key Vault Secrets User).
- **Environment variable:** `Secret – <SystemName> – <EnvName>` (type Secret, referencing the vault secret).

## Commercial vs GCC High — what's different

> This is the section that keeps a government tenant from being configured with Commercial steps. Read it before you touch anything. Fuller, cited detail is in `gcc-high-parity-notes.md`.

**1. Different portals and endpoints — not the same URL with a different login.**

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Power Platform admin center | `admin.powerplatform.microsoft.com` | `high.admin.powerplatform.microsoft.us` |
| Power Apps maker portal | `make.powerapps.com` | `make.high.powerapps.us` |
| Power Automate | `flow.microsoft.com` | `high.flow.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Entra sign-in | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Key Vault data plane (DNS) | `vault.azure.net` | `vault.usgovcloudapi.net` |
| Azure Resource Manager | `management.azure.com` | `management.usgovcloudapi.net` |

Sources: Power Apps US Government service URLs and Azure Government endpoint comparison (see `gcc-high-parity-notes.md`).

**2. Identity is Microsoft Entra Government.** GCC High requires the customer to use Microsoft Entra Government for identities (unlike GCC, which uses public Entra ID). Your service principals, groups, and role assignments live in the `.us` identity plane.

**3. PowerShell must target the sovereign cloud.** All scripts connect with `Connect-AzAccount -Environment AzureUSGovernment` (Az) and, where Graph is used, `Connect-MgGraph -Environment USGov`. Running the Commercial default silently points at `management.azure.com` and will not see your Gov resources.

**4. Key Vault feature itself is at parity; the plumbing around it differs.** Azure Key Vault, Azure RBAC, the **Key Vault Secrets User** role, and the `Microsoft.PowerPlatform` provider registration all exist in Azure Government. What differs is endpoints, the identity plane, network/IP allowlists (Power Platform US Gov IP ranges), and one caveat below.

**5. The Dataverse first-party principal object may differ in GCC High — verify.** The Commercial Dataverse app id is `00000007-0000-0000-c000-000000000000`. In GCC High the first-party service principal that must hold **Key Vault Secrets User** can surface under a different display name / object id in your tenant. The scripts flag this as **"verify for GCC High"** rather than assuming — confirm the actual principal in **Entra ID → Enterprise applications** before granting.

**6. Some management conveniences are absent in Azure Government.** Notably, **Privileged Identity Management (PIM) / eligible (JIT) role activation is not available in Azure Government** — so least-privilege here is achieved with standing-but-scoped RBAC groups and Conditional Access, not JIT elevation. Plan role assignments accordingly.

**7. Availability can lag.** Microsoft targets functional parity but documents exceptions in the Business Applications US Government availability summary. Where a specific capability (for example a preview) is not confirmed for GCC High, this solution flags it **"verify for GCC High"** rather than asserting it works.

## Who this is for

Government, DoD-contractor, and other ITAR/CJIS-regulated organizations running Power Platform on **GCC High** who need their makers to consume secrets the supported, auditable way — with the sovereign-cloud specifics handled.
