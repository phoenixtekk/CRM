# GCC High Parity Notes — Enterprise App & Service Principal Governance

This reference records what is **confirmed** about Microsoft Entra in the US sovereign cloud
(GCC High / US Government L4) as it affects this solution, with citations. Anything not confirmed by
a Microsoft US Gov source is marked **"verify for GCC High"** — never treat it as fact. GCC High is a
network-isolated instance; features and timelines can differ from Commercial, so re-check the live
portal and the cited pages before relying on a capability.

> Scope note: this covers **GCC High (US Government L4)**. **GCC** (moderate) uses the *Commercial*
> worldwide endpoints, and **DoD (L5)** uses a different Graph host (`dod-graph.microsoft.us`,
> `Connect-MgGraph -Environment USGovDoD`). This edition targets GCC High.

## 1. Endpoints and sign-in (confirmed)

| Purpose | GCC High value | Source |
|---|---|---|
| Entra admin center | `https://entra.microsoft.us` | MS Learn / Entra admin center [1][6] |
| Azure portal | `https://portal.azure.us` | Graph national cloud deployments [1] |
| Microsoft Entra sign-in / authority | `https://login.microsoftonline.us` | Graph national cloud deployments [1]; Connect-MgGraph reference [3] |
| Microsoft Graph service root (L4 / GCC High) | `https://graph.microsoft.us` | Graph national cloud deployments [1] |
| Microsoft Graph PowerShell environment | `Connect-MgGraph -Environment USGov` | Connect-MgGraph reference [3] |
| Microsoft 365 admin center | `https://portal.office365.us` | M365 US Gov GCC High endpoints [2] |

- **Tokens are not interchangeable across clouds.** "Access tokens acquired for a national cloud
  deployment are not interchangeable with those acquired for the global service or any other national
  cloud." [1] A GCC High account is only recognized on the `.us` endpoints.
- **`Get-MgEnvironment` confirms the mapping**: `USGov` -> AzureAD endpoint
  `https://login.microsoftonline.us`, Graph endpoint `https://graph.microsoft.us`; `USGovDoD` ->
  `https://dod-graph.microsoft.us`. [3]

## 2. Graph Explorer / browser tooling (confirmed gap)

- **Graph Explorer is "Not supported"** for Microsoft Graph for US Government L4 (GCC High) and for
  L5 (DoD). [1] Practically: you cannot use the browser-based Graph Explorer to poke the API in
  GCC High — use the Microsoft Graph PowerShell SDK (`-Environment USGov`), which is exactly what
  this package's scripts do.

## 3. App governance, consent, and identity governance (confirmed GA)

- **Enterprise app governance surfaces** — Enterprise applications, Consent and permissions, and the
  admin-consent workflow — are the standard Entra experiences reached via `entra.microsoft.us` ->
  Entra ID -> Enterprise apps. [4][6]
- **Microsoft Entra ID Governance** (which includes Access reviews, Entitlement management, PIM, and
  Lifecycle workflows) is **available in GCC, GCC High, and DoD**. [5] The Entra feature-availability
  table for US Government lists Access reviews, Entitlement management, and PIM as ✅ available. [5]
- **Conditional Access** and **RBAC** are ✅ available in US Government. [5] These back the roles this
  solution uses (Application Administrator, Cloud Application Administrator).
- **Defender for Cloud Apps app governance** is available in GCC High, but note the cadence: "new
  feature releases … will be available in GCC High and DoD environments within three months of
  release in the … commercial environment." [7] So Defender-side app-governance features can trail
  Commercial by up to ~3 months. This solution's core does not require Defender for Cloud Apps app
  governance — it uses native Entra consent controls and Microsoft Graph — but if you layer Defender
  app governance on top, expect the lag.

## 4. Confirmed parity gaps adjacent to this solution

From the Microsoft Entra feature availability in Azure for US Government table [5]:

| Feature | US Gov status | Impact on this solution |
|---|---|---|
| Graph Explorer (browser) | Not supported (L4/L5) [1] | Use PowerShell SDK — this package already does |
| Microsoft Entra threat intelligence (ID Protection risk detection) | ❌ Not available [5] | Do not rely on this specific risk signal to flag risky apps; use the over-permission report instead |
| Delegated user management portal (My Staff) | ❌ Not available [5] | Not used by this solution |
| HR-driven provisioning | Partial [5] | Not used by this solution |
| Enterprise State Roaming (Windows 10) | Not available [5] | Not used by this solution |

- Most **ID Protection risk detections** (leaked credentials, anonymous IP, atypical/impossible
  travel, password spray, suspicious inbox rules, etc.) **are ✅ available** in US Government; only
  **Microsoft Entra threat intelligence** is ❌. [5] If you use risk-based Conditional Access as an
  adjacent control, that one detection type will be missing.

## 5. Items to verify for GCC High (not confirmed here — do not assume)

- **Exact rollout state of any specific consent/permission-classification sub-feature** in your
  tenant. The *capability* is GA, but a brand-new sub-option seen in a Commercial screenshot may not
  yet be present. **Verify in your `entra.microsoft.us` portal** before writing a runbook around it.
- **Microsoft Entra Verified ID, external identities / B2B collaboration specifics, and any preview
  feature.** Preview features in particular often reach GCC High later. **Verify for GCC High.**
- **Any third-party gallery/SaaS app's availability in the GCC High gallery.** Gallery contents can
  differ. **Verify for GCC High** in the portal's Enterprise applications -> New application gallery.

## Sources
- [1] Microsoft Graph national cloud deployments — https://learn.microsoft.com/en-us/graph/deployments
- [2] Microsoft 365 U.S. Government GCC High endpoints — https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints
- [3] Connect-MgGraph (Microsoft.Graph.Authentication) reference — https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph
- [4] Configure the admin consent workflow — https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/configure-admin-consent-workflow
- [5] Microsoft Entra feature availability in Azure for US Government — https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability
- [6] Microsoft Entra admin center — https://learn.microsoft.com/en-us/entra/fundamentals/entra-admin-center
- [7] US Government offerings — Microsoft Defender for Cloud Apps — https://learn.microsoft.com/en-us/defender-cloud-apps/editions-cloud-app-security-gcc
