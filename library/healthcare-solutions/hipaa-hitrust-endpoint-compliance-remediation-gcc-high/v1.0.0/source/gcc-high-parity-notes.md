# GCC High Parity Notes — HIPAA/HITRUST Endpoint Compliance & Remediation (Government)

**What this is:** the cited **Commercial-vs-US-Government** reference for the two products this solution
depends on — **Microsoft Intune** and **Microsoft Defender for Endpoint** (including Defender
Vulnerability Management) — so you configure a **GCC High** tenant correctly and know which
capabilities to **verify in your own tenant** before you depend on them. Both services for US
Government are built in the **Azure US Government** environment and use the **same underlying
technology** as Commercial — but they **do not have complete parity**. Where this file says
*verify for GCC High*, treat the capability as unconfirmed until you see it in `*.us`.

> **Primary sources (re-check the live pages — availability changes over time):**
> - Microsoft Learn, *"Microsoft Defender for Endpoint for US Government customers"*
>   (`learn.microsoft.com/en-us/defender-endpoint/gov`) — page dated 2026-01-05, updated 2026-06-03.
> - Microsoft Learn, *"Microsoft Intune Government Service overview"*
>   (`learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description`)
>   — page dated 2026-06-04, updated 2026-07-01.
> - Microsoft Learn, *"Network endpoints for US government deployments"* (Intune)
>   (`learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints`).

---

## 1. Portal URLs (which portal is *your* portal)

Every admin surface is a `.us` (or `portal.office365.us`) host, not `.com`. A bookmark or a doc that
sends you to a `.com` portal is Commercial and will show you the **wrong (or an empty) tenant**.

| Purpose | Commercial URL | **GCC High URL (use this)** |
| --- | --- | --- |
| Sign-in / authentication | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Entra admin center | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Microsoft Defender portal | `security.microsoft.com` | **`security.microsoft.us`** |
| Microsoft Purview / compliance | `compliance.microsoft.com` | **`compliance.microsoft.us`** |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** |

> The **Defender portal** URL differs again by cloud: **GCC → `security.microsoft.com`**,
> **GCC High → `security.microsoft.us`**, **DoD → `security.apps.mil`**. This solution targets
> **GCC High**. GCC customers migrating from Commercial reach legacy Commercial data at
> `transition.security.microsoft.com`. Cited: Microsoft — Defender for Endpoint *for US Government
> customers*, "Portal URLs."

> **Intune "GCC" nuance:** for **Intune**, *GCC* is the **same instance as Commercial** — Intune has no
> separate GCC instance. Only **GCC High** and **DoD** are the physically separate government cloud
> (IL4 / IL5). So in Intune docs, "GCC High"/"DoD" = the government cloud; "GCC" = Commercial. Cited:
> Microsoft — Intune Government Service overview, "Intune commercial and government instances."

## 2. API / Graph base URIs (for the included scripts and any custom tooling)

| Endpoint type | GCC | **GCC High & DoD** |
| --- | --- | --- |
| Sign in (authority) | `https://login.microsoftonline.com` | **`https://login.microsoftonline.us`** |
| Microsoft Graph | `https://graph.microsoft.com` | **`https://graph.microsoft.us`** (US Gov L4) |
| Defender for Endpoint API | `https://api-gcc.securitycenter.microsoft.us` | **`https://api-gov.securitycenter.microsoft.us`** |

- All five included scripts connect with **`Connect-MgGraph -Environment USGov`**, which targets
  **`graph.microsoft.us`**. A script that omits `-Environment USGov` silently talks to the Commercial
  cloud and returns nothing for your tenant. Cited: Microsoft — Intune, "Network endpoints for US
  government deployments" (`graph.microsoft.us`, `login.microsoftonline.us`).
- Do **not** use the public `api.securitycenter.microsoft.com`. Cited: Microsoft — Defender for
  Endpoint *for US Government customers*, "API."

## 3. Licensing (US Gov SKUs)

**Desktop licensing** (one of these is required):

| GCC | GCC High | DoD |
| --- | --- | --- |
| Microsoft 365 GCC G5 | Microsoft 365 E5 for GCC High | Microsoft 365 G5 for DOD |
| Microsoft 365 G5 Security GCC | Microsoft 365 G5 Security for GCC High | Microsoft 365 G5 Security for DOD |
| Microsoft Defender for Endpoint - GCC | Microsoft Defender for Endpoint for GCC High | Microsoft Defender for Endpoint for DOD |
| Windows 10 Enterprise E5 GCC | Windows 10 Enterprise E5 for GCC High | Windows 10 Enterprise E5 for DOD |

**G3 includes Microsoft Defender for Endpoint Plan 1.** Defender Vulnerability Management **core**
capabilities are included in **Defender for Endpoint Plan 2**. Cited: Microsoft — Defender for
Endpoint *for US Government customers*, "Licensing requirements."

## 4. Connectivity (US Gov endpoints devices and admins must reach)

If a proxy/firewall allows only specific domains, add the Microsoft-published **Gov/GCC/DoD** URLs:

- **Defender for Endpoint** — two lists exist:
  - **Streamlined Connectivity URL list for Gov/GCC/DoD** — a reduced URL set (or static IP ranges); a
    dedicated endpoint group supports streamlined connectivity in government and consolidates several
    service dependencies into fewer URLs. *(Marked **Preview** on the source page — verify for GCC
    High/DoD.)*
  - **Standard Connectivity URL list for Gov/GCC/DoD** — the full per-service DNS records.
- **Downlevel / MMA:** choose **Azure US Government** as the Azure Cloud (or set
  `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`); a required KB may need to be deployed **before**
  onboarding so a downlevel device registers to the correct (Gov) environment.
- **Intune** — devices/admins must reach the government endpoints (e.g. `graph.microsoft.us`,
  `login.microsoftonline.us`, and `manage.microsoft.us` for enrollment/update downloads). Cited:
  Microsoft — Intune, "Network endpoints for US government deployments"; Defender for Endpoint *for US
  Government customers*, "Required connectivity settings."

## 5. Defender for Endpoint — feature parity gaps (the part that changes your design)

MDE for US Government does not have complete parity with Commercial. **Known gaps** per Microsoft:

| Feature | GCC | GCC High | DoD |
| --- | --- | --- | --- |
| Microsoft Secure Score | Available* | Available | Available |
| **Microsoft Threat Experts** | **Not available** | **Not available** | **Not available** |
| MDE Security Configuration Management | Available | Available | Available |
| **Microsoft Defender for IoT (enterprise IoT security)** | **Not available** | **Not available** | **Not available** |

\* **Secure Score** is available for GCC/GCC High/DoD, but **some security recommendations are not
available** — so a "Microsoft Secure Score for Devices" figure or a specific recommendation you see in
Commercial may differ or be absent in GCC High. Cited: Microsoft — Feature parity with commercial (note).

**Defender Vulnerability Management (TVM) — availability in GCC High.** This is the **good news** for
this solution: DVM **core** capabilities (included in Defender for Endpoint Plan 2) **and premium**
capabilities are **available** for GCC/GCC High/DoD. Exposure score, security recommendations,
remediation requests, and exceptions all work — that is the remediation engine this solution relies
on. **The two DVM functions that are NOT available for GCC/GCC High/DoD:**

- **Report inaccuracy** (you cannot flag a recommendation as inaccurate from the portal).
- **Request CVE support** (you cannot request coverage for a missing CVE from the portal).

Cited: Microsoft — Defender for Endpoint *for US Government customers*, "Feature parity with commercial"
(Mobile Threat Defense table + the Defender Vulnerability Management note).

## 6. Intune — feature parity gaps that affect *this* solution

Intune in GCC High/DoD lags Commercial on several update and provisioning features. The ones that
**change a step in this solution**:

- **Windows Update *policies* — largely NOT yet available in GCC High/DoD.** Microsoft lists as
  *planned (not yet available)* for GCC High/DoD: **Feature updates**, **Quality updates**, **Expedite
  updates**, **Driver updates**, **Windows Autopatch**, and **Delivery Optimization for Win32 apps**.
  **Impact:** the patch-currency safeguard in this solution is delivered by an **Update ring for Windows
  10 and later** (Windows Update for Business rings) — which **is** a standard MDM feature and works in
  GCC High — **not** by the newer feature/quality/expedite update *policies*, which you should assume
  are absent until you confirm them in `intune.microsoft.us`. Also **absent:** *Reports for feature
  update policies* and *App and driver compatibility reports for Windows updates*. Plan patch evidence
  around the Update ring + the compliance policy's **Minimum OS version**, not the update-policy
  reports. *Verify for GCC High.*
- **Classic Windows Autopilot — NOT available in GCC High/DoD** (listed under "not available"). Only
  **Windows Autopilot device preparation** is partially available. **Impact:** do not assume
  Autopilot-based provisioning of clinical endpoints; enroll via the supported methods for your cloud.
  *Verify for GCC High.*
- **Remote Help — NOT yet available** (planned). **Cloud PKI — NOT yet available** (planned, GCC High
  only). **BIOS configuration profiles / DFCI — NOT yet available** (planned). **Security Copilot in
  Intune — NOT yet available** (planned). None are required by this solution, but do not build a step
  on them.
- **Available and relied upon by this solution (confirmed):** standard MDM features — **compliance
  policies, device configuration profiles (settings catalog), disk encryption (BitLocker) policy,
  Microsoft Defender Antivirus/Firewall endpoint-security policies, Update rings** — plus **Advanced
  Analytics**, **Endpoint Privilege Management**, **Log Analytics** export, and **MDE security settings
  management** (manage Defender settings on Defender-onboarded devices). **MTD connectors** work only
  with vendors that **also support** GCC High — when you sign in to a GCC High tenant you see only the
  connectors available there. Cited: Microsoft — Intune Government Service overview ("Supported…",
  "…planned…", and "…not available… in GCC High and DoD").

## 7. Capabilities to verify in your tenant (do not assume from Commercial docs)

Government feature rollout **trails Commercial**, and the greatest parity gaps have historically been
in **analytics, reporting, and integration** surfaces. **Before you depend on any of these, confirm in
`intune.microsoft.us` / `security.microsoft.us` — flag "verify for GCC High" until confirmed:**

- **Any newer analytics/reporting dashboard** in Intune or Defender — a dashboard present in Commercial
  may be absent or delayed in GCC High. *Verify.*
- **Automated Investigation & Response (AIR)** and **advanced hunting / third-party SIEM & connector
  integrations** — integration surfaces commonly lag in Government. *Verify.*
- **Streamlined connectivity URL list** — marked **Preview** for Gov/GCC/DoD. *Verify.*
- **The exact Secure Score recommendations** you rely on for evidence — some are omitted in Government.
  *Verify.*

> **Rule:** for any capability not in an "Available"/confirmed row above and not personally confirmed in
> your tenant, treat it as **unconfirmed** and write a manual playbook rather than assuming the
> Commercial behavior. **Never invent a GCC High specific.**

---
*Primary sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"
(learn.microsoft.com/en-us/defender-endpoint/gov, dated 2026-01-05, updated 2026-06-03); "Microsoft
Intune Government Service overview"
(learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description, dated
2026-06-04, updated 2026-07-01); "Network endpoints for US government deployments"
(learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints). All GCC
High / DoD specifics must be re-verified against the live pages and your tenant, as US Government
availability changes over time.*
