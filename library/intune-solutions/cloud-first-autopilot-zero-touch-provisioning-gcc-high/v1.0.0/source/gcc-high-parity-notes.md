# GCC High Parity Notes — Cloud-First Autopilot Zero-Touch Provisioning

A single, **cited** reference of how the US sovereign cloud (GCC High / DoD) differs from
Commercial for this solution. Each row is **doc-confirmed** against Microsoft US Gov
documentation, or explicitly flagged **"verify for GCC High"** where Microsoft's public
docs did not confirm the exact detail at authoring time. **Nothing here is invented.**

> Cloud terminology (doc-confirmed): For **Intune**, "GCC" is the **Commercial** service
> instance; only **GCC High** and **DoD** are the separate government cloud (IL4/IL5 on
> Azure Government). This solution targets **GCC High / DoD**. (Microsoft, *Intune
> Government Service overview*.)

## 1. Provisioning technology

| Item | Commercial | GCC High / DoD | Status |
| --- | --- | --- | --- |
| Classic **Windows Autopilot** (deployment profiles, hardware-hash registration) | Available | **Not available; no plan to support** | Doc-confirmed |
| **Windows Autopilot device preparation** (user-driven, Entra join) | Available | **Available** | Doc-confirmed |
| Self-deploying mode / pre-provisioning (white-glove) | Available | **Not yet available (planned)** | Doc-confirmed |
| Rename device during OOBE by org structure | Available | **Not yet available (planned)** | Doc-confirmed |
| Enhanced Company Portal desktop onboarding for device prep | Available | **Not yet available (planned)** | Doc-confirmed |
| Provisioning modes requiring classic Autopilot registration | Available | **Not supported** | Doc-confirmed |
| **DFCI** management (UEFI/BIOS via Autopilot) | Available | **Not available (planned)** | Doc-confirmed |

*Sources:* Microsoft, *Intune Government Service overview* (tables: "Supported…",
"…planned…", "…not available…"); *Overview of Windows Autopilot device preparation*
(GCCH/DoD support; user-driven, Entra-join only).

## 2. Portals & service endpoints

| Purpose | Commercial | GCC High | Status |
| --- | --- | --- | --- |
| Intune admin center | `intune.microsoft.com` | **`https://intune.microsoft.us`** | Doc-confirmed |
| Azure portal | `portal.azure.com` | **`https://portal.azure.us`** | Doc-confirmed |
| Microsoft 365 admin | `admin.microsoft.com` | **`https://portal.office365.us`** | Doc-confirmed |
| Company Portal service | `portal.manage.microsoft.com` | **`https://portal.manage.microsoft.us`** | Doc-confirmed |
| Sign-in / Evo STS | `login.microsoftonline.com` | **`https://login.microsoftonline.us`** | Doc-confirmed |
| Microsoft Graph | `graph.microsoft.com` | **`https://graph.microsoft.us`** | Doc-confirmed |
| Enterprise registration (ADRS) | `enterpriseregistration.windows.net` | **`enterpriseregistration.microsoftonline.us`** | Doc-confirmed |
| MDM service (no SSL inspection) | `*.manage.microsoft.com` | **`*.manage.microsoft.us`** | Doc-confirmed |
| **Entra admin center** | `entra.microsoft.com` | **`entra.microsoft.us`** | **Verify for GCC High** — the Azure/Entra Gov portal is documented as `portal.azure.us`; the standalone `entra.microsoft.us` host is widely used but was not confirmed verbatim in the fetched Intune/M365 Gov endpoint docs at authoring time. Use `portal.azure.us` → Microsoft Entra ID if in doubt. |

*Sources:* Microsoft, *Network endpoints for US government deployments* ("US Government
customer designated endpoints"; "Partner service endpoints"); *Microsoft Graph national
cloud deployments*.

## 3. PowerShell / Graph connection

| Item | Commercial | GCC High | Status |
| --- | --- | --- | --- |
| Microsoft Graph PowerShell environment | (default / Global) | **`Connect-MgGraph -Environment USGov`** | Doc-confirmed |
| Graph base URL selected by that environment | `graph.microsoft.com` | `graph.microsoft.us` | Doc-confirmed |
| DoD variant | n/a | `-Environment USGovDoD` → `dod-graph.microsoft.us` | Doc-confirmed |

Every script in this solution connects with `-Environment USGov` and prints the resolved
environment so the operator can confirm sovereignty before any read. *(Source: Microsoft,
*Microsoft Graph national cloud deployments*; US Gov PowerShell samples.)*

## 4. Servicing & updates

| Item | GCC High / DoD | Status |
| --- | --- | --- |
| **Windows Autopatch** | **Not available** | Doc-confirmed |
| Feature / Quality / Expedite / Driver update policies for Windows | **Not available** | Doc-confirmed |
| Reports for feature update policies | **Not available** | Doc-confirmed |
| App & driver compatibility reports for Windows updates | **Not available** | Doc-confirmed |
| **Update rings for Windows 10 and later** | **Available** (the servicing mechanism to use) | Doc-confirmed |
| Windows Subscription Activation (Pro → Enterprise step-up) | **Not available** | Doc-confirmed |
| Delivery Optimization for Win32 apps | **Not available** | Doc-confirmed |

*Source:* Microsoft, *Intune Government Service overview* ("Autopatch and updates" planned
table; "not available" table).

## 5. Apps, PKI, attestation, support tooling

| Item | GCC High / DoD | Status |
| --- | --- | --- |
| **Microsoft Store for Business** | **Not available** | Doc-confirmed |
| **Cloud PKI** | **Not available (GCC High)** | Doc-confirmed |
| **Device Health Attestation (DHA)** | **Not available** | Doc-confirmed |
| **Remote Help** | **Not available (planned)** | Doc-confirmed |
| BIOS configuration profiles for Windows | **Not available (planned)** | Doc-confirmed |
| Microsoft Connected Cache for Enterprise/Education | **Not available** | Doc-confirmed |
| Windows Backup for Organizations | **Not available** | Doc-confirmed |
| eSIM cellular on Windows | **Not available** | Doc-confirmed |
| Endpoint Privilege Management (EPM) | **Available** in GCC High/DoD | Doc-confirmed |
| Defender for Endpoint security settings management | **Available** (incl. GCC/GCC High/DoD) | Doc-confirmed |

*Source:* Microsoft, *Intune Government Service overview* (supported / planned / not-
available tables).

## 6. Windows Hello for Business

| Item | GCC High / Azure Government | Status |
| --- | --- | --- |
| WHfB policy configuration via Intune | Available (standard WHfB policy path) | Doc-confirmed (general WHfB) |
| **Microsoft (hosted) PIN reset service** | **Not available in Azure Government** — configure PIN recovery via allowed sign-in URLs (Intune/CSP/GPO) | Doc-confirmed (WHfB configure docs) |
| Exact WHfB provisioning behavior under device preparation OOBE | — | **Verify for GCC High** for your Windows build |

*Source:* Microsoft, *Configure Windows Hello for Business* (PIN reset service not
available for Azure Government tenants).

## 7. Networking specifics

| Item | GCC High | Status |
| --- | --- | --- |
| `*.manage.microsoft.us` requires **unauthenticated** proxy access; **no SSL inspection** | Required | Doc-confirmed |
| Defender / EPM endpoints: **no SSL inspection** | Required | Doc-confirmed |
| Ports: HTTP 80, HTTPS 443, UDP 123 (NTP) | Required | Doc-confirmed |
| Autopilot device preparation still contacts `login.live.com` for the deployment service | Required | Doc-confirmed |

*Source:* Microsoft, *Network endpoints for US government deployments*; *Autopilot device
preparation requirements → Networking*.

---

## Full source list

- Microsoft Learn — *Microsoft Intune Government Service overview*
  (`/intune/intune-service/fundamentals/intune-govt-service-description`).
- Microsoft Learn — *Overview of Windows Autopilot device preparation*
  (`/autopilot/device-preparation/overview`).
- Microsoft Learn — *Windows Autopilot device preparation requirements*
  (`/autopilot/device-preparation/requirements`).
- Microsoft Learn — *Windows Autopilot device preparation — create an assigned device
  group* (`/autopilot/device-preparation/tutorial/user-driven/entra-join-device-group`).
- Microsoft Learn — *Network endpoints for US government deployments*
  (`/intune/intune-service/fundamentals/intune-us-government-endpoints` /
  `/intune/fundamentals/endpoints-us-government`).
- Microsoft Learn — *Microsoft Graph national cloud deployments* (`/graph/deployments`).
- Microsoft Learn — *Configure Windows Hello for Business*
  (`/windows/security/identity-protection/hello-for-business/configure`).

*Items flagged "verify for GCC High" were not confirmed verbatim in Microsoft public docs
at authoring time and must be validated against the live GCC High tenant before relying on
them.*
