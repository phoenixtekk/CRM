# GCC High Parity Notes — Windows 365 Cloud PC (Government)

This reference is the **single source of truth** for what is different in the US sovereign cloud
(**GCC High**) versus Commercial for this solution. Every portal URL, endpoint, and feature-parity
gap called out elsewhere in this package traces back to the citations below. Where Microsoft's
public documentation does not explicitly confirm a GCC High behavior, it is flagged
**"verify for GCC High"** rather than asserted.

> **GCC is not GCC High.** Microsoft ships *two different* government experiences. In **GCC**, the
> Cloud PCs run in Azure Government but the **admin and end-user endpoints stay in the commercial
> `.com` domain** (`intune.microsoft.com`, `windows365.microsoft.com`). In **GCC High**, the entire
> experience is sovereign — admin and end-user endpoints move to the `.us` domain. **This package is
> authored for GCC High.** If your tenant is GCC (not GCC High), use the Commercial edition of this
> solution with the Azure-Gov region note, not this one. [Set up tenants for Windows 365 Government,
> Microsoft Learn — "the endpoints for admins and end users are in the commercial Azure domain" (GCC);
> "The instructions on this page don't apply to GCC High."]

---

## 1. Portal & endpoint map (Commercial → GCC High)

Every URL below is the sovereign replacement you use in this solution. Signing in to a Commercial
URL against a GCC High tenant is the single most common cause of "it looks broken / I can't see my
tenant."

| Purpose | Commercial | **GCC High (use this)** |
|---|---|---|
| Microsoft Entra ID sign-in (auth) | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin center | `admin.microsoft.com` | `admin.microsoft.us` |
| Microsoft Intune admin center | `intune.microsoft.com` | `intune.microsoft.us` |
| Intune / endpoint management (alt.) | `endpoint.microsoft.com` | `endpoint.microsoft.us` |
| Microsoft Entra admin center | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Microsoft Defender portal | `security.microsoft.com` | `security.microsoft.us` |
| Microsoft Purview / compliance | `compliance.microsoft.com` | `compliance.microsoft.us` |
| Windows 365 end-user portal | `windows365.microsoft.com` | `windows365.microsoft.us` |
| Intune Company Portal (web) | `portal.manage.microsoft.com` | `portal.manage.microsoft.us` |
| Microsoft Graph service root | `graph.microsoft.com` | `graph.microsoft.us` |
| Microsoft Graph SDK environment | `Global` (default) | `-Environment USGov` |

Citations: [Microsoft Graph national cloud deployments, Microsoft Learn — GCC High Graph =
`https://graph.microsoft.us`, Entra = `https://login.microsoftonline.us`, Azure portal =
`https://portal.azure.us`]; [Microsoft Intune Government Service overview, Microsoft Learn —
GCC High uses `endpoint.microsoft.us` / `graph.microsoft.us`, admin center `intune.microsoft.us`,
web Company Portal `portal.manage.microsoft.us`]; [What is Windows 365 Government, Microsoft Learn —
GCC High end-user portal `windows365.microsoft.us`].

> **DoD (IL5) note:** DoD uses the same `.us` admin portals but a **different Graph root**
> (`dod-graph.microsoft.us`) and the Graph SDK value **`-Environment USGovDoD`**. This package is
> authored for **GCC High (IL4)**; DoD tenants should substitute those two values. [Microsoft Graph
> national cloud deployments — DoD Graph = `https://dod-graph.microsoft.us`.]

---

## 2. Windows 365 Government feature-parity gaps (GCC High)

The following Windows 365 features are **not yet supported for Windows 365 Government (GCC and/or
GCC High)** per Microsoft. Design the deployment to **not depend on any of them** in GCC High.

| Feature | Status in GCC High | Consequence for this solution |
|---|---|---|
| **Windows 365 Security baseline** | Not yet supported | Do **not** rely on the built-in W365 security baseline. Harden Cloud PCs with an ordinary Intune **Settings catalog** configuration profile + a compliance policy instead (Implementation Step 5). |
| **GPU Cloud PCs** | Not yet supported | GPU SKUs are unavailable — size all workloads to CPU/RAM SKUs only. |
| **Windows 365 Boot** | GCC only — **not** GCC High | Cannot boot a physical device directly to a Cloud PC in GCC High. |
| **Windows 365 Switch** | Not yet supported | No Task-view switch between local desktop and Cloud PC. |
| **Windows 365 Reserve** | Not yet supported | No standby/reserve Cloud PC capability. |
| **New Microsoft Teams client (on Cloud PC)** | Not yet supported | Plan for the classic Teams experience; verify current Teams support for GCC High. |
| **Multimedia redirection (MMR)** | Not yet supported | Video-playback offload is unavailable; expect standard streamed video. |
| **Unified dashboard / system-based alerting / email notifications** | Not yet supported | No W365 monitoring dashboard or automatic system alerts — use the reporting script (`W365G-Report.ps1`) and Intune device views for state. |
| **Audit logs in Azure Log Analytics (for Cloud PCs)** | Not yet supported | Cannot stream W365 audit logs to Log Analytics; use Intune's in-portal views. |
| **Copilot in Intune for Windows 365** | Not yet supported | No Copilot assistance in the W365 admin experience. |
| **Cross-region disaster recovery / DR Plus** | Not yet supported | No built-in cross-region DR; plan resilience via user-data-in-OneDrive + reprovision. |
| **Windows 365 for Agents / Dev Box / Flex shared mode** | Not supported for GCC/GCC High | Out of scope for a GCC High Cloud PC deployment. |
| **Third-party protocols (Citrix HDX Plus, Omnissa Horizon/Blast, HP Anyware)** | Not yet supported | Connect with the **Windows App** / RDP only in GCC High. |
| **Migration API; RDP Shortpath over public networks (TURN)** | Not yet supported | No commercial↔gov migration API; expect standard RDP transport. |

Citation: [What is Windows 365 Government, Microsoft Learn — "Features not yet supported Windows 365
Government," which enumerates the above and explicitly marks **Windows 365 Boot** "available for GCC,
not available for GCC High."]

---

## 3. Intune (GCC High) feature-parity gaps that affect Cloud PC management

Cloud PCs are managed by Intune, so Intune's own GCC High gaps matter. Per Microsoft, the following
are **not available in GCC High** (no current plan) or **not yet available** (planned):

| Intune feature | GCC High status | Consequence |
|---|---|---|
| **Windows Autopilot** (classic) | Not available (no plan) | Do not design Autopilot into the Cloud PC flow; W365 provisions via the **provisioning policy**, which does not require Autopilot. |
| **Windows Autopilot device preparation** | Partial — user-driven available; self-deploying/pre-provisioning **not** yet | Use user-driven only where relevant. |
| **Remote Help** | Not yet available (planned) | Plan an alternate remote-assistance tool for Cloud PC support. |
| **Cloud PKI** | Not yet available (planned, **GCC High only**) | If you need certificate issuance, verify availability before designing around it. |
| **Windows Autopatch; Feature/Quality/Expedite/Driver update rings** | Not yet available (planned) | Manage Cloud PC updates with classic Intune update policies / servicing; do not rely on Autopatch or the update-ring report types. |
| **Windows Backup for Organizations** | Not available (no plan) | Rely on OneDrive/known-folder redirection for user-data resilience. |
| **Security Copilot; Device Health Attestation** | Not yet available (planned) | Exclude from GCC High designs for now. |

Citation: [Microsoft Intune Government Service overview, Microsoft Learn — "Intune features planned
for GCC High and DoD" and "Intune features not available in GCC High and DoD" tables.]

---

## 4. Tenant / subscription model differences (GCC High)

- **No Azure Government subscription is required just to run Windows 365 Government** on the
  Microsoft-hosted network with gallery images — the fast path is the same as Commercial
  (Entra join + gallery image + Microsoft-hosted network). [Set up tenants for Windows 365
  Government, Microsoft Learn.]
- The **Windows 365 GCC Setup Tool / tenant-mapping** flow (mapping a `.com` tenant to a `.us`
  Azure Government tenant, granting the Windows 365 service principal
  `0af06dc6-e4b5-4f28-818e-e78e62d137a5`) is documented **for GCC** and Microsoft states it **does
  not apply to GCC High**. For **GCC High** custom-image / ANC setup, **verify the current
  GCC-High-specific procedure for GCC High** before building an ANC or uploading a custom image.
  [Set up tenants for Windows 365 Government, Microsoft Learn — note: "don't apply to GCC High."]
- Intune's government instance is a **shared IL4/IL5** service physically separate from Commercial;
  there is **no built-in migration** between Commercial and the government cloud — devices unenroll
  and re-enroll. [Microsoft Intune Government Service overview, Microsoft Learn.]

---

## 5. What is the SAME as Commercial (so you don't over-engineer)

- The **provisioning-policy model** (group-assigned, one Cloud PC per license), **Entra join vs.
  Entra hybrid join**, **Microsoft-hosted network vs. Azure Network Connection**, **gallery vs.
  custom image**, **resize/reprovision/restart** lifecycle, and **Intune compliance/configuration/
  app** management all work the same way — only the **portals, endpoints, and the parity gaps above**
  differ. [What is Windows 365?, Microsoft Learn; Provisioning in Windows 365, Microsoft Learn.]
- **Multi-Region Selection** for the Microsoft-hosted network (US Government region group) is
  available in GCC and GCC High for provisioning-policy resiliency. [Announcing Multi-Region
  Selection for Windows 365 in Government Community Cloud, Microsoft Windows IT Pro Blog.]

---

## Sources
- Microsoft Graph national cloud deployments — https://learn.microsoft.com/en-us/graph/deployments
- Microsoft Intune Government Service overview — https://learn.microsoft.com/en-us/intune/fundamentals/government-service
- What is Windows 365 Government? — https://learn.microsoft.com/en-us/windows-365/enterprise/introduction-windows-365-government
- Set up tenants for Windows 365 Government — https://learn.microsoft.com/en-us/windows-365/enterprise/set-up-tenants-windows-365-gcc
- Announcing Multi-Region Selection for Windows 365 in Government Community Cloud — https://techcommunity.microsoft.com/blog/windows-itpro-blog/announcing-multi%E2%80%91region-selection-for-windows-365-in-government-community-cloud/4500043
