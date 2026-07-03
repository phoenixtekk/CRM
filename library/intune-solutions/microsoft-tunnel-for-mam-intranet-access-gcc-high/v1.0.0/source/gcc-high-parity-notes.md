# GCC High / DoD Parity Notes — Microsoft Tunnel for MAM

**Solution code:** TUNMAMG

A cited reference of how **Microsoft Tunnel for MAM** behaves in the **US sovereign clouds (GCC High / DoD)** versus Commercial. Use this to avoid applying Commercial steps that silently fail in Government. Every claim is sourced or flagged **"verify for GCC High/DoD."**

> **Standing caveat:** Microsoft updates Government feature parity frequently. Confirm each item against the current Microsoft US Government documentation at deployment time.

---

## 1. Feature availability — SUPPORTED in Government

Microsoft Tunnel Gateway and **Tunnel for Mobile Application Management (MAM)** are **supported in both GCC High and DoD**.

- The *Microsoft Intune Government Service overview* lists **"Microsoft Tunnel for Mobile Application Management"** among the **Intune advanced capabilities that support the GCC High and DoD environments** (page updated 2026-06-04).
  Source: <https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description>
- The per-platform pages state it directly:
  > "Microsoft Tunnel for MAM on Android is supported with the following sovereign cloud environments: U.S. Government Community Cloud (GCC) High, U.S. Department of Defense (DoD)."
  Source: <https://learn.microsoft.com/en-us/intune/device-security/microsoft-tunnel/mam-android>
  > "Microsoft Tunnel for MAM on iOS/iPadOS is supported with the following sovereign cloud environments: … GCC High … DoD."
  Source: <https://learn.microsoft.com/en-us/intune/device-security/microsoft-tunnel/mam-ios>

**Interpretation:** This is *not* a "Commercial-only" networking feature. Unlike several Windows-update and Autopilot features (which are absent or "planned" in Government), Tunnel for MAM is generally available in GCC High and DoD.

---

## 2. FIPS — NOT supported (compliance-relevant gap)

> "Microsoft Tunnel for MAM on Android doesn't support Federal Information Processing Standard (FIPS)."
> "Microsoft Tunnel for MAM on iOS/iPadOS doesn't support Federal Information Processing Standard (FIPS)."
Sources: mam-android, mam-ios (above).

**Implication:** If your ATO/STIG obligations require FIPS 140-validated cryptography on this data path, Tunnel for MAM is not the compliant control. Obtain ISSO/ISSM sign-off before deploying. **Not on Azure operated by 21Vianet** either (not relevant to US Gov, noted for completeness).

---

## 3. Gateway install — Government cloud flag `intune_env=FXP`

The Linux gateway must be told to register against the Government cloud:
> "**For the U.S. government cloud**, the command line must reference the government cloud environment. To do so, run the following commands to add *intune_env=FXP* … `sudo ./mstunnel-setup` … `sudo intune_env=FXP ./mstunnel-setup`."
Source: <https://learn.microsoft.com/en-us/intune/device-security/microsoft-tunnel/install>

**Failure mode:** Omitting `intune_env=FXP` registers the gateway with **Commercial** Intune; it never appears in `intune.microsoft.us`.

---

## 4. Admin portals — all `*.us`

| Plane | Commercial | GCC High / DoD |
| --- | --- | --- |
| Intune admin center | `intune.microsoft.com` / `endpoint.microsoft.com` | **`intune.microsoft.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** (Azure Government) |
| Entra / app registration | `entra.microsoft.com` | Entra ID **Government** (via `portal.azure.us`) |
| Sign-in authority | `login.microsoftonline.com` | **`login.microsoftonline.us`** (GCC High **and** DoD) |
| Gateway device-login | `microsoft.com/devicelogin` | `microsoft.com/devicelogin` (authenticates to the Gov authority) |

Government portal URLs are Microsoft-published for GCC High/DoD. **Verify** the Entra Government entry point for your tenant.

---

## 5. Microsoft Graph endpoints (used by the scripts)

| Environment | `Connect-MgGraph -Environment` | Graph endpoint | Sign-in |
| --- | --- | --- | --- |
| GCC High | **`USGov`** | `graph.microsoft.us` | `login.microsoftonline.us` |
| DoD | **`USGovDoD`** | `dod-graph.microsoft.us` | `login.microsoftonline.us` |
| Commercial (for contrast) | `Global` | `graph.microsoft.com` | `login.microsoftonline.com` |

Sources: *Connect-MgGraph* / *Get-MgEnvironment* Microsoft Graph PowerShell docs (learn.microsoft.com/powershell/module/microsoft.graph.authentication). The five scripts in this package default to **`USGov`**; pass DoD parameters for DoD.

---

## 6. Certificate authority — Cloud PKI parity gap

**Microsoft Cloud PKI** (cloud-hosted CA advanced capability) appears in the *Government Service overview* **"Intune features planned for GCC High and DoD"** table, annotated **"(GCC High only)"** — i.e., **planned, GCC High only, not yet in DoD.**
Source: government-service overview (above).

**Implication:** Do not assume Cloud PKI is available for issuing the TLS server certificate or trusted-root material. Use an **enterprise/on-premises CA** or a **supported public CA**. **Verify current Cloud PKI status for GCC High** if you intend to use it.

---

## 7. Other Government parity items worth knowing (context)

From the same *Government Service overview*:
- **Remote Help** — planned, not yet available in GCC High/DoD (relevant if you planned to assist BYOD users remotely).
- **Windows Autopilot**, several **Windows Update** report/policy features, **BIOS/DFCI**, **Security Copilot**, **Device Health Attestation** — **not available** in GCC High/DoD. Not required for Tunnel for MAM, but note if your broader mobility design assumed them.
- **Standard MDM features, app policies, compliance policies, MTD connectors** (vendors that also support GCC High) **are** available.

---

## 8. Licensing

Tunnel for MAM requires **Intune Plan 2 or an additional subscription** (Commercial and Government alike):
> "This feature requires Microsoft Intune Plan 2 or an additional subscription."
Sources: mam-android, mam-ios.

**Verify for GCC High/DoD:** confirm the exact **Government** SKU that carries Intune Plan 2 / Intune Suite (e.g., M365 G5 Gov, Intune Plan 2 Gov add-on) with your licensing desk — Government bundle names differ from Commercial.

---

## Summary — the Government delta in one paragraph
Tunnel for MAM **works in GCC High and DoD**. The differences that matter operationally are: install the gateway with **`intune_env=FXP`**; do everything in **`*.us`** portals; connect scripts with **`-Environment USGov`** (GCC High) or **`USGovDoD`** (DoD); accept **no FIPS** on this path (ISSO/ISSM sign-off); source certificates from an **enterprise/public CA** (Cloud PKI is GCC-High-only/planned); allow **US Government** endpoint ranges through the firewall; and, for federated tenants, set the **`bypassedUrls`** STS exclusion.

---
*White-label reference. All external claims are cited to Microsoft Learn; items without a citation are flagged "verify for GCC High/DoD." Re-verify at deployment.*
