# GCC High Parity Notes — Compliance-Failure Diagnostics (cited)

This is the **cited reference** for every Commercial-vs-GCC High difference this solution relies on.
Each item states the fact, why it changes a compliance diagnosis, and the Microsoft source. Where
Microsoft does not explicitly confirm a behavior for GCC High, it is marked **⚠ verify for GCC High**
rather than assumed. Endpoints and feature lists **change** — always re-confirm against the live
Microsoft docs cited below.

> Sources were retrieved from Microsoft Learn in **July 2026**. GCC High = government cloud (IL4);
> DoD = IL5. Note per Microsoft: **"GCC"** in Intune docs refers to the **Commercial** instance;
> **"GCC High"/"DoD"** refers to the separate government cloud.

## 1. Admin portals and service URLs are all `*.us`
- **Fact:** US Government designated endpoints — Azure portal `https://portal.azure.us/`, Microsoft
  365 `https://portal.office365.us/`, Intune Company Portal `https://portal.manage.microsoft.us/`,
  **Intune admin center `https://intune.microsoft.us/`**. Sign-in (Evo STS) is
  `https://login.microsoftonline.us`; Microsoft Graph is `https://graph.microsoft.us`.
- **Why it matters:** a `.com` portal/endpoint on a GCC High tenant causes authentication failures —
  the device or admin silently never reaches the service.
- **Source:** *Network endpoints for US government deployments — Microsoft Intune* (Microsoft Learn),
  "US Government customer designated endpoints" and "Partner service endpoints that Intune depends on."
  https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints

## 2. Device service endpoints — and no SSL inspection
- **Fact:** Intune requires **unauthenticated** proxy access to `manage.microsoft.us`; **SSL
  inspection is not supported** on `*.manage.microsoft.us` or `has.spserv.microsoft.com`. Defender for
  Endpoint security-settings-management and Endpoint Privilege Management use **`*.dm.microsoft.us`**
  (wildcard covers enrollment, check-in, reporting), and **SSL inspection isn't supported** on those
  endpoints either. Entra device registration uses `enterpriseregistration.microsoftonline.us`.
- **Why it matters:** breaking TLS on these endpoints is a leading cause of GCC High devices stuck at
  **Not evaluated** or going stale.
- **Source:** same *Network endpoints for US government deployments* article — "Before you begin,"
  "Microsoft Defender for Endpoint," "Microsoft Intune Endpoint Privilege Management," and "Partner
  service endpoints."

## 3. Microsoft Graph PowerShell — `-Environment USGov`
- **Fact:** `Connect-MgGraph -Environment USGov` targets `graph.microsoft.us` /
  `login.microsoftonline.us`; `-Environment USGovDoD` targets `dod-graph.microsoft.us`. Without
  `-Environment`, the module authenticates against the **Commercial** endpoint. USGov/USGovDoD can use
  the **built-in** Microsoft Graph PowerShell app; **other** sovereign clouds (BleuCloud, DelosCloud,
  GovSGCloud) require a **custom app registration**.
- **Why it matters:** empty script output on GCC High is almost always a missing `-Environment`.
- **Source:** *Connect-MgGraph (Microsoft.Graph.Authentication)* and *Get-MgEnvironment* (Microsoft
  Learn, graph-powershell-1.0).
  https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph

## 4. Device Health Attestation (DHA) — core rules yes, some capabilities planned
- **Fact (supported):** Devices across Intune **commercial, GCC High, and DoD** running Windows 10 use
  the **DHA service**; the Windows compliance rules **Require BitLocker / Require Secure Boot / Require
  code integrity** rely on the DHA CSP + DHA service.
- **Fact (planned):** the Intune Government service description lists **"Windows Device Health
  Attestation (DHA)"** under features **not yet available / planned** for GCC High and DoD — this
  refers to newer/expanded DHA capability, not the core BitLocker/Secure Boot/Code Integrity rules.
- **Why it matters:** the common Device Health compliance rules work in GCC High, but **⚠ verify for
  GCC High** before promising a rule that depends on an expanded DHA attribute.
- **Sources:** *Windows compliance settings / Device compliance settings for Windows in Intune*
  (Microsoft Learn) for DHA use across commercial/GCC High/DoD; *Microsoft Intune Government Service
  overview* (Microsoft Learn) "Intune features planned for GCC High and DoD" list.
  https://learn.microsoft.com/en-us/intune/device-security/compliance/ref-windows-settings ·
  https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description

## 5. Mobile Threat Defense (MTD) — vendor must also support GCC High
- **Fact:** MTD connectors for Android and iOS/iPadOS can be used **only with MTD vendors that also
  support the GCC High environment**; when signed into a GCC High tenant you see only the connectors
  available there.
- **Why it matters:** a **"device threat level"** compliance rule cannot be evaluated if your MTD
  vendor isn't present in Gov — a parity gap, not a misconfiguration.
- **Source:** *Microsoft Intune Government Service overview* — "Supported Intune features," Mobile
  Threat Defense row.

## 6. Windows Autopilot — classic unavailable; device preparation partial
- **Fact:** **Windows Autopilot (classic)** is listed under **"not available … no current planning"**
  for GCC High/DoD. **Windows Autopilot device preparation** is partially available (user-driven now;
  self-deploying/pre-provisioning and other modes **planned**).
- **Why it matters:** "not compliant right after provisioning" has a different root cause in GCC High;
  Commercial Autopilot compliance-timing guidance doesn't apply.
- **Source:** *Microsoft Intune Government Service overview* — "Supported," "planned," and "not
  available" tables.

## 7. Cloud PKI and Remote Help — planned, not yet available
- **Fact:** **Cloud PKI** (GCC High only) and **Remote Help** are listed as **planned, not yet
  available** in GCC High/DoD.
- **Why it matters:** certificate-based compliance/remediation and assisted (Remote Help) remediation
  workflows differ from Commercial — don't design a GCC High fix around them yet. **⚠ verify for GCC
  High** current status before relying on either.
- **Source:** *Microsoft Intune Government Service overview* — "Intune features planned for GCC High
  and DoD."

## 8. Windows update workflows largely unavailable in GCC High
- **Fact:** **Windows Autopatch**, and **Feature / Quality / Expedite / Driver update** policies for
  Windows in Intune, plus **Delivery Optimization for Win32 apps**, are listed as **planned / not
  available** for GCC High/DoD; **feature-update reports** and **app/driver compatibility reports** are
  **not available**.
- **Why it matters:** you can't lean on Intune's update workflows to remediate a **Minimum OS version**
  compliance failure in GCC High — use your available patching mechanism.
- **Source:** *Microsoft Intune Government Service overview* — "planned" and "not available" tables.

## 9. Other compliance-adjacent features absent in GCC High
- **Fact:** **not available / no planning:** Microsoft Store for Business, TeamViewer & ServiceNow
  connectors, Chrome Enterprise Connector, On-premises Exchange Connector, Windows Backup for
  Organizations, Windows Subscription Activation, AVD multi-session, Intune PowerBI connector for DWH,
  Security Copilot (planned). Standard MDM (compliance policies, configuration profiles, app policies)
  **is** supported; platform support includes Windows, iOS/iPadOS, macOS, Android, **AOSP** (some
  device restrictions), and **Linux** (GA).
- **Why it matters:** rules or remediations that assume any absent connector/feature will never work
  in GCC High. **⚠ verify for GCC High** for AOSP-specific capabilities.
- **Source:** *Microsoft Intune Government Service overview* — feature tables.

## 10. FedRAMP / accreditation context
- **Fact:** Intune is **FedRAMP Moderate** authorized in GCC and **FedRAMP High** in GCC High and DoD;
  the government cloud is a physically separate datacenter (IL4/IL5), and there is **no in-place
  migration** between Commercial and government cloud (devices unenroll then re-enroll).
- **Why it matters:** a device from a Commercial tenant will never appear/evaluate in the GCC High
  tenant until re-enrolled.
- **Source:** *Microsoft Intune Government Service overview* — "Intune commercial and government
  instances," "Enroll in government tenant," "Compliance and certifications."

---
### Verify-before-you-trust checklist
1. Every URL you use ends in **`.us`** (except Microsoft-designated `.com` dependencies like
   `has.spserv.microsoft.com` / `*.events.data.microsoft.com` — **⚠ verify** against the live list).
2. Scripts connect with **`-Environment USGov`** (or `USGovDoD`).
3. `*.manage.microsoft.us` and `*.dm.microsoft.us` are **excluded from SSL inspection**.
4. The failing rule's feature is confirmed **supported in GCC High** before you treat it as a bug.
5. Anything Microsoft doesn't explicitly confirm for GCC High is labeled **⚠ verify for GCC High** —
   never invented.
