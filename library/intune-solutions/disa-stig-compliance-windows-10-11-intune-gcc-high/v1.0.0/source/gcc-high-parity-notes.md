# GCC High / DoD Parity Reference (cited)

This reference lists the **Commercial-vs-GCC-High/DoD** differences that affect a DISA STIG-on-Intune deployment, each pinned to a **Microsoft US Government** source. The sovereign feature set **changes over time**, so every gap below is written as **"verify for GCC High/DoD"** — confirm current status in the cited Microsoft doc before relying on it.

> **Scope note:** "GCC" (used by many US state/local governments) is the **Commercial** Intune instance — Intune has no separate GCC instance. This document concerns **GCC High (IL4)** and **DoD (IL5)**, which run on the Microsoft Azure Government Cloud. Sources: Microsoft Learn, *Microsoft Intune Government Service overview* and *Network endpoints for US government deployments*.

---

## 1. Admin portals and sign-in (all `*.us`)

| Purpose | Commercial | GCC High / DoD |
| --- | --- | --- |
| Intune admin center | `intune.microsoft.com` | **`https://intune.microsoft.us/`** |
| Azure portal (Entra blades) | `portal.azure.com` | **`https://portal.azure.us/`** |
| Microsoft 365 admin | `admin.microsoft.com` | **`https://portal.office365.us/`** |
| Company Portal (web) | `portal.manage.microsoft.com` | **`https://portal.manage.microsoft.us/`** |
| Defender | `security.microsoft.com` | **`https://security.microsoft.us`** *(verify)* |
| Purview / compliance | `compliance.microsoft.com` | **`https://compliance.microsoft.us`** *(verify)* |
| Sign-in authority | `login.microsoftonline.com` | **`https://login.microsoftonline.us`** |

*Source: Microsoft Learn — "Network endpoints for US government deployments" (US Government customer designated endpoints): Azure portal `https://portal.azure.us/`, Microsoft 365 `https://portal.office365.us/`, Intune Company Portal `https://portal.manage.microsoft.us/`, Intune admin center `https://intune.microsoft.us/`. `https://learn.microsoft.com/intune/intune-service/fundamentals/intune-us-government-endpoints`.*

## 2. Microsoft Graph / PowerShell environment

| | GCC High | DoD |
| --- | --- | --- |
| Graph host | **`graph.microsoft.us`** | **`dod-graph.microsoft.us`** |
| Sign-in authority | `login.microsoftonline.us` | `login.microsoftonline.us` |
| `Connect-MgGraph -Environment` | **`USGov`** | **`USGovDoD`** |

*Source: Microsoft Learn — Microsoft Graph PowerShell "authentication commands," `Get-MgEnvironment` built-in list: `USGov → https://login.microsoftonline.us / https://graph.microsoft.us`; `USGovDoD → https://login.microsoftonline.us / https://dod-graph.microsoft.us`. `https://learn.microsoft.com/powershell/microsoftgraph/authentication-commands`. Also endpoints doc: "MS Graph: `https://graph.microsoft.us`".*

## 3. Network endpoints (proxy/firewall)

Allow (and, where noted, **exclude from SSL inspection**):

- **`*.manage.microsoft.us`** — device check-in/service; **SSL inspection not supported**; some tasks (e.g., update downloads) need **unauthenticated** proxy access.
- **`login.microsoftonline.us`** (Evo STS), **`enterpriseregistration.microsoftonline.us`** (ADRS).
- **`graph.microsoft.us`** (GCC High) / **`dod-graph.microsoft.us`** (DoD); Azure AD Graph `directory.microsoftazure.us` / `graph.microsoftazure.us`.
- **`*.dm.microsoft.us`** — Defender for Endpoint security settings management **and** Endpoint Privilege Management; **SSL inspection not supported**.
- **`*.events.data.microsoft.com`** — client health diagnostics.
- **`enterpriseregistration.microsoftonline.us`** for Windows auto-enrollment/registration.

*Source: Microsoft Learn — "Network endpoints for US government deployments" (Before you begin; Partner service endpoints; Defender / EPM sections). Same URL as §1.*

## 4. Features SUPPORTED in GCC High / DoD

Confirmed available (per Microsoft's service description) — relevant to a STIG deployment:

- **Standard MDM features** — app policies, **device configuration profiles**, **compliance policies** (the core STIG delivery + gating mechanisms).
- **Advanced capabilities** in GCC High/DoD: **Advanced Analytics**, **Endpoint Privilege Management (EPM)**, Enterprise App Management, Microsoft Tunnel for MAM, Specialty devices, Firmware-over-the-air.
- **Microsoft Defender for Endpoint security settings management** — extends to GCC, GCC High, and DoD.
- **Log Analytics** — send Intune log data to Azure Storage / Event Hubs / Log Analytics.
- **Platform support** — Windows, plus Android/AOSP, iOS/iPadOS, Linux, macOS.

*Source: Microsoft Learn — "Microsoft Intune Government Service overview," §"Supported Intune features in GCC High and DoD." `https://learn.microsoft.com/intune/intune-service/fundamentals/intune-govt-service-description`.*

## 5. STIG audit baseline (Advanced Analytics)

- Intune **Advanced Analytics** is **supported in GCC High and DoD**. When enabled it can surface a **STIG audit baseline** that **assesses** Windows devices against DISA STIG recommendations.
- The STIG audit baseline is **audit-only** — it **does not configure or enforce** settings; enforcement remains your Settings Catalog/ADMX/custom profiles.
- Advanced Analytics requires a **subscription add-on** in addition to Intune Plan 1/Plan 2.
- Current guidance describes the STIG audit baseline as **GCC High**-oriented; **verify availability for your DoD tenant**.

*Sources: Microsoft Learn — "Microsoft Intune Government Service overview" (Advanced Analytics listed as GCC High/DoD-supported) and "Learn about Intune security baselines for Windows devices" / "Advanced Analytics Overview" (STIG audit baseline, audit-only, GCC High, Advanced Analytics licensing). `https://learn.microsoft.com/intune/device-security/security-baselines/overview`; `https://learn.microsoft.com/intune/advanced-analytics/`.*

## 6. Features PLANNED (not yet available) in GCC High / DoD

Design **around** these — Microsoft lists planning but no general availability (verify for latest ETA):

- **Cloud PKI** (GCC High only, planned) · **Remote Help**.
- **Windows Autopatch**; Windows **feature / quality / expedite / driver** update policies; Delivery Optimization for Win32 apps.
- **BIOS configuration profiles**; **DFCI** management.
- **Security Copilot** (in Intune).
- **Windows Device Health Attestation (DHA)**.
- **Windows Autopilot device preparation** — *partial*: user-driven deployments available; self-deploying/pre-provisioning and several OOBE customizations still planned.

*Source: Microsoft Learn — "Microsoft Intune Government Service overview," §"Intune features planned for GCC High and DoD." Same URL as §4.*

## 7. Features NOT available (no current plan) in GCC High / DoD

- **Windows Autopilot** (classic) — **not available**.
- Windows **Subscription Activation**; **Windows Backup for Organizations**.
- App & driver **compatibility reports** for Windows updates; reports for feature update policies.
- **Microsoft Store for Business**; **Microsoft Connected Cache** (Ent/Edu).
- **ServiceNow / TeamViewer** connectors; **Intune Power BI connector for DWH**.
- **eSIM cellular on Windows**; Windows **Diagnostic Data processor** configuration; **Windows Enterprise multi-session (AVD)**.

*Source: Microsoft Learn — "Microsoft Intune Government Service overview," §"Intune features not available in GCC High and DoD." Same URL as §4.*

## 8. DISA STIG rule content — deferred to DISA (not Microsoft)

- The STIG **benchmarks** (rule IDs `SV-…`, Group IDs `V-…`, CCIs, severities, check/fix) are published by **DISA** at the **DoD Cyber Exchange** and read with **STIG Viewer** — **not** invented here.
- Microsoft's own guidance points administrators to DISA: the Intune Government Service overview links the **STIGs Document Library** at `public.cyber.mil` for locking down tenants.

*Sources: DoD Cyber Exchange — STIGs Document Library `https://public.cyber.mil/stigs/downloads/`. Microsoft Learn — "Microsoft Intune Government Service overview," §"Enroll in government tenant" (links `public.cyber.mil` STIGs Document Library).*

---

## How to use this reference

1. **Before designing** any step that depends on an Intune feature, check §4–§7 and **click the cited Microsoft doc** to confirm current status — the sovereign feature set moves.
2. **When a setting is missing** from the Settings Catalog in `intune.microsoft.us`, first confirm it isn't a §6/§7 gap, then fall back to ADMX or custom OMA-URI (`03-implementation.md` §2b–2d).
3. **Never** substitute a Commercial URL, `graph.microsoft.com`, or `-Environment Global` — see §1–§3.

*All Microsoft citations reflect docs current at authoring (2026-07). Because Microsoft continuously ships features into GCC High/DoD, re-verify against the live Microsoft Learn pages linked above before relying on any gap.*
