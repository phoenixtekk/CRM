# GCC High Parity Notes — Entra ID Governance (PIM, Access Reviews & Entitlement Management)

This reference records what is confirmed, what differs, and what is unconfirmed for **Entra ID
Governance on the US Government (GCC High / DoD) cloud** versus Commercial. Every claim is cited to
Microsoft documentation or explicitly flagged **"verify for GCC High"** where Microsoft has not
confirmed sovereign parity. **Never assume Commercial parity** for preview, external-collaboration,
or cross-cloud features. Verify against current docs at deployment time, as sovereign availability
changes.

## 1. Sovereign endpoints (confirmed)
Use the `*.us` plane for every portal, sign-in, and Graph call. The Commercial endpoints reject GCC
High accounts.

| Purpose | GCC High (US Gov L4) | DoD (US Gov L5) | Commercial |
|---|---|---|---|
| Microsoft Entra admin center | `https://entra.microsoft.us` | `https://entra.microsoft.us` | `https://entra.microsoft.com` |
| Azure portal | `https://portal.azure.us` | `https://portal.azure.us` | `https://portal.azure.com` |
| Sign-in / authentication | `https://login.microsoftonline.us` | `https://login.microsoftonline.us` | `https://login.microsoftonline.com` |
| Microsoft Graph | `https://graph.microsoft.us` | `https://dod-graph.microsoft.us` | `https://graph.microsoft.com` |
| Graph PowerShell `-Environment` | `USGov` | `USGovDoD` | `Global` |

Sources:
- Microsoft Learn — *Microsoft Graph national cloud deployments* (`https://learn.microsoft.com/en-us/graph/deployments`): Graph = `graph.microsoft.us` (GCC High) / `dod-graph.microsoft.us` (DoD); Azure portal `portal.azure.us`; Entra ID endpoint `login.microsoftonline.us`. Also: **Graph Explorer is "Not supported"** for the US Gov L4/L5 endpoints.
- Microsoft Learn — *Microsoft Entra admin center* and Microsoft 365 US Government GCC High endpoints: Entra admin center = `entra.microsoft.us`.

## 2. Core governance capabilities — Generally Available in US Gov (confirmed)
Microsoft's *Entra feature availability in Azure for US Government* lists the following under
**Identity governance** as available (✅):

| Capability | US Gov availability |
|---|---|
| Access reviews | ✅ Available |
| Entitlement management | ✅ Available |
| Privileged Identity Management (PIM) | ✅ Available |
| Lifecycle workflows (in Entra ID Governance) | ✅ Available |
| Automated user provisioning to apps | ✅ Available |
| Automated group provisioning to apps | ✅ Available |
| Terms of use | ✅ Available |
| Self-service entitlement management (My Access) | ✅ Available |

Source: Microsoft Learn — *Microsoft Entra feature availability in Azure for US Government*
(`https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability`).

**Implication:** the core deployment in this solution (PIM eligibility + activation policy, access
reviews for roles/groups/apps, entitlement-management catalogs and access packages) is fully
supported on GCC High.

## 3. Licensing in US Gov (confirmed)
- PIM, access reviews, and entitlement management require **Microsoft Entra ID P2** or **Microsoft Entra ID Governance**.
- In the US Government clouds the governance capability ships as **"Microsoft Entra ID Governance for Government"** (User SL; prerequisite: a product with the `AAD_PREMIUM` or `AAD_PREMIUM_P2` service plan) and **"Microsoft Entra ID Governance Add-on for Microsoft Entra ID P2 for Government"** (prerequisite: `AAD_PREMIUM_P2`). Microsoft documents both as **available in GCC, GCC High, and DoD**.
- Government bundles that carry the prerequisite service plans include **Microsoft 365 G3/G5** (G3 → `AAD_PREMIUM`, G5 → `AAD_PREMIUM_P2`) and **EMS E3/E5**.
- License every member user in scope of, or configuring, the governance features (eligible role holders, approvers, reviewers, and users/self-reviewers in access reviews).

Source: Microsoft Learn — *Microsoft Entra ID Governance licensing fundamentals*
(`https://learn.microsoft.com/en-us/entra/id-governance/licensing-fundamentals`): "The Microsoft
Entra ID Governance for Government and Microsoft Entra ID Governance Add-on for Microsoft Entra ID P2
for Government products are available in the US Government community cloud (GCC), GCC-High, and
Department of Defense cloud environments."

## 4. Known differences and limitations vs Commercial (confirmed)
| Area | Commercial | US Gov (GCC High / DoD) | Source |
|---|---|---|---|
| Graph Explorer (browser tool) | Supported | **Not supported** for `graph.microsoft.us` / `dod-graph.microsoft.us` — use PowerShell `-Environment USGov` | Graph national cloud deployments |
| HR-driven provisioning | Available | **Partial** (see HR-provisioning apps table) | Entra feature availability for US Government |
| My Staff (delegated user management portal) | Available | **Not available (❌)** | Entra feature availability for US Government |
| Microsoft Entra threat intelligence (ID Protection detection) | Available | **Not available (❌)** — noted because ID Protection can gate governance approvals | Entra feature availability for US Government |
| Enterprise state roaming (shared device sign-out context) | Available | Not available for Windows 10 devices | Entra feature availability for US Government |

## 5. Verify for GCC High (unconfirmed sovereign parity — do not assume Commercial parity)
The following are **Preview** or **externally-scoped** in Commercial and are **not confirmed** for GCC
High at authoring time. Treat each as "verify for GCC High" before you depend on it; check current
Microsoft US Gov documentation at deployment time.

- **Machine-learning access-review recommendations** (user-to-group affiliation, inactive-user recommendations as ML helpers) — marked Governance/Preview capabilities in Commercial. **Verify for GCC High.** Default to owner/manager reviewers.
- **Catalog access reviews (Preview)** and **custom-data-resource access reviews (Preview)**. **Verify for GCC High.**
- **Entitlement management external / cross-cloud collaboration** — connected organizations and access packages that span **Commercial ↔ US Gov**, and **cross-cloud synchronization** (in preview). Microsoft notes cross-cloud sync in GCC High is delivered under the *Entra ID Governance for Government* SKU, and that B2B direct connect is not supported across different Microsoft clouds. **Verify for GCC High** before designing external-guest access packages that cross a cloud boundary; keep pilots in-tenant first.
- **EM — Microsoft Entra Roles in access packages (Preview)**, **SAP IAG integration (Preview)**, **Verified ID / Insider Risk / ID Protection integrations** — Governance/Preview features in Commercial. **Verify for GCC High.**
- **Suggested access packages in My Access**, **My Access approver-detail visibility (Preview)**, **delegate approvals in My Access (Preview)** — **verify for GCC High.**

> General rule: features marked **Preview** in Microsoft's Commercial licensing/feature tables should
> be assumed **later or absent** in the sovereign clouds until Microsoft's US Gov documentation
> confirms them. When in doubt, flag "verify for GCC High" and deploy the GA path.

## 6. Sources
- Microsoft Learn — *Microsoft Graph national cloud deployments*: `https://learn.microsoft.com/en-us/graph/deployments`
- Microsoft Learn — *Microsoft Entra feature availability in Azure for US Government*: `https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability`
- Microsoft Learn — *Microsoft Entra ID Governance licensing fundamentals*: `https://learn.microsoft.com/en-us/entra/id-governance/licensing-fundamentals`
- Microsoft Learn — *Connect-MgGraph (Microsoft.Graph.Authentication)* national cloud `-Environment` values (`USGov` → `graph.microsoft.us`): `https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph`
- Microsoft Learn — *Manage connected organizations in entitlement management* / *Cross-tenant synchronization overview* (cross-cloud collaboration behavior and preview status).
