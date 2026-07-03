# Solution Overview — Microsoft Tunnel for MAM (Mobile Access to Intranet Resources) — Government (GCC High) Edition

**Solution code:** TUNMAMG · **Platform:** Microsoft Intune · **Cloud:** US Sovereign (GCC High / DoD) · **Tier:** T4

---

## Availability — read this first

**Good news, with caveats.** Microsoft Tunnel Gateway **and** Microsoft Tunnel for Mobile Application Management (MAM) **are both supported** in the US sovereign clouds — **US Government Community Cloud (GCC) High** *and* **US Department of Defense (DoD)**. This is not a case where a Commercial networking feature is missing in Government: Microsoft explicitly lists **Microsoft Tunnel for Mobile Application Management** among the Intune advanced capabilities that support GCC High and DoD.
> Source: *Microsoft Intune Government Service overview* (updated 2026-06-04) — "The following Intune advanced capabilities support the GCC High and DoD environments: … Microsoft Tunnel for Mobile Application Management." ([learn.microsoft.com](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-govt-service-description))
> Source: *Use Microsoft Tunnel VPN with Android/iOS devices that don't enroll with Intune* — "Microsoft Tunnel for MAM on Android/iOS is supported with the following sovereign cloud environments: U.S. Government Community Cloud (GCC) High, U.S. Department of Defense (DoD)." ([Android](https://learn.microsoft.com/en-us/intune/device-security/microsoft-tunnel/mam-android) · [iOS](https://learn.microsoft.com/en-us/intune/device-security/microsoft-tunnel/mam-ios))

**But three Government-specific constraints shape the whole deployment — know them before you buy hardware or write a design:**

1. **No FIPS.** *Microsoft Tunnel for MAM on Android and on iOS/iPadOS does **not** support Federal Information Processing Standard (FIPS).* If your ATO/STIG obligations mandate FIPS 140-validated cryptography for this data path, Tunnel for MAM is **not** the compliant control — flag this to your ISSO/ISSM before scoping. (Verified on both the Android and iOS Microsoft Learn pages.)
2. **Not on 21Vianet.** Tunnel for MAM is *not* supported on Azure operated by 21Vianet (China). Irrelevant to US Gov tenants, but recorded for completeness.
3. **Certificate-authority parity gap.** Microsoft **Cloud PKI** (the cloud-hosted CA advanced capability) is **GCC High only and still on the "planned" list** — it is **not yet generally available in DoD**, and even in GCC High you should **verify current status** before depending on it. Because Tunnel for MAM relies on a **TLS server certificate** (and often **trusted-root** profiles for on-prem resources), plan your PKI on an on-premises/enterprise CA or a supported public CA rather than assuming Cloud PKI. (Source: *Government Service overview*, "Intune features planned for GCC High and DoD" table.)

The rest of this solution assumes GCC High as the primary target and calls out DoD differences where they exist.

---

## What this solution delivers

**Microsoft Tunnel for MAM** lets users on **personal, unenrolled** Android and iOS/iPadOS devices reach your **on-premises intranet apps and resources** (internal web apps, line-of-business services) over a secure VPN — **without** enrolling the device in MDM and **without** giving IT control of the whole device. Access is scoped to **managed apps** (Microsoft Edge and your MAM-integrated line-of-business apps), protected by **modern authentication, single sign-on, Conditional Access, and app protection policies**.

It extends the **Microsoft Tunnel VPN Gateway** — a container that runs on a Linux server you host — to unenrolled devices. You must have the Tunnel Gateway deployed first; Tunnel for MAM is a set of **app configuration + app protection policies** layered on top of that gateway.

This edition packages the deployment for a **GCC High (or DoD) tenant**: the correct `*.us` sovereign admin portals, the **`intune_env=FXP`** government install flag for the gateway, US Gov Microsoft Graph endpoints (`-Environment USGov` / `-Environment USGovDoD`) in every script, and the Commercial-vs-Government parity gaps documented inline so a government tenant is configured correctly — not with Commercial steps that silently fail.

### The deployment model
Every step in this solution follows the standard gated model: **Assess → Configure → Pilot → Validate → Expand**, with a go/no-go gate between each phase so you never scale a misconfiguration.

### What's in the box
- **This Solution Overview** and a **Requirements Guide** (`02-requirements.md`) with verify + implement steps for every prerequisite.
- **Implementation Guide** (`03-implementation.md`) — ordered, click-by-click steps in the GCC High portals with Government caveats inline.
- **Testing & Validation** (`05-testing.md`) with pass/fail gates.
- **Troubleshooting** (`06-troubleshooting.md`) with GCC-High-specific gotchas.
- **Best Practices** (`07-best-practices.md`), an **Executive Summary**, a **GCC High parity reference** (`gcc-high-parity-notes.md`), and a **deliverables summary**.
- **5 PowerShell scripts** — Discovery, Validation, Report, Remediation, and Set-ScopeTargeting — all connecting to **US Gov Microsoft Graph** (`-Environment USGov`).

---

## Commercial vs GCC High — what's different

If you have deployed Microsoft Tunnel for MAM in a Commercial tenant, here is the delta for Government. **The product and the click-path are essentially the same; the URLs, endpoints, and a handful of parity constraints differ.**

| Area | Commercial | GCC High / DoD (this edition) |
| --- | --- | --- |
| **Feature availability** | Supported | **Supported** (advanced capability) in **both GCC High and DoD**. Verified 2026-06-04. |
| **Intune admin center** | `intune.microsoft.com` / `endpoint.microsoft.com` | **`intune.microsoft.us`** |
| **Azure portal** (Linux VM, networking) | `portal.azure.com` | **`portal.azure.us`** (Azure Government) |
| **Entra admin center** (app registration, groups) | `entra.microsoft.com` | **Entra ID Government** via `portal.azure.us` / Entra Gov endpoints |
| **Sign-in authority** | `login.microsoftonline.com` | **`login.microsoftonline.us`** (both GCC High and DoD) |
| **Microsoft Graph** | `graph.microsoft.com` (`-Environment Global`) | **GCC High:** `graph.microsoft.us` (`-Environment USGov`) · **DoD:** `dod-graph.microsoft.us` (`-Environment USGovDoD`) |
| **Tunnel Gateway install** | `sudo ./mstunnel-setup` | **`sudo intune_env=FXP ./mstunnel-setup`** (the `intune_env=FXP` flag points the gateway at the Government cloud) |
| **Device login page** | `microsoft.com/devicelogin` | `microsoft.com/devicelogin` (same URL; authenticates against the Gov authority) |
| **FIPS** | (Tunnel for MAM does not support FIPS in either cloud) | **No FIPS support** — a compliance-relevant gap in Government. |
| **Cloud PKI** (for TLS/trusted-root certs) | Generally available | **GCC High only, "planned"** (verify status); **not in DoD.** Use enterprise/public CA. |
| **Licensing** | Intune Plan 2 or add-on | Same requirement; ensure the **Government** SKU (G3/G5 Gov, Intune Plan 2 Gov) carries it. |
| **STIG hardening** | Optional | **Expected** — DISA MDM/EMM STIGs apply to the tenant and the Linux host. |

**The single most common Government failure:** running the gateway installer **without** `intune_env=FXP`. The gateway then tries to register against the Commercial Intune service and **never appears** in your `intune.microsoft.us` admin center. See `03-implementation.md` and `06-troubleshooting.md`.

**The second most common:** admins bookmark or automate against `*.com` portals/Graph out of habit; in Government every plane is `*.us`. Every script in this package defaults to the US Gov endpoints.

---

## Who this is for
Government agencies, DoD components, and defense-industrial-base (DIB / CMMC) contractors on a **GCC High or DoD** Microsoft 365 tenant who need **BYOD / unenrolled** mobile access to internal, on-premises resources without full device enrollment — and who need it configured correctly for the sovereign cloud the first time.

---
*White-label solution. Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time; Microsoft updates Government feature parity frequently. Items marked "verify for GCC High/DoD" should be confirmed live in your tenant.*
