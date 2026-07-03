# Microsoft Tunnel for MAM — Mobile Access to Intranet Resources — Government (GCC High)

> **Version 1.0.0** · Category: Intune · Solution code: TUNMAMG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Tunnel for MAM (Mobile Access to Intranet Resources) — Government (GCC High) Edition

**Solution code:** TUNMAMG · **Platform:** Microsoft Intune · **Cloud:** US Sovereign (GCC High / DoD)

## The business problem
Government agencies, DoD components, and defense-industrial-base contractors need staff to reach **internal, on-premises applications** from **personal mobile devices** — without enrolling those devices in full management and without standing up costly legacy VPN infrastructure. The obstacle in the sovereign cloud is that **Government (GCC High / DoD) is not Commercial with a different sign-in**: the admin portals, service endpoints, and gateway install differ, and a Commercial runbook applied to a Government tenant **silently fails** (most often a Tunnel Gateway that installs but never appears in the admin center).

## The solution
This is the **Government (GCC High) edition** of the Microsoft Tunnel for MAM deployment. **Microsoft Tunnel for MAM** extends the Microsoft Tunnel VPN Gateway to **unenrolled Android and iOS/iPadOS devices**, giving users secure, app-scoped access to intranet resources through **Microsoft Edge and MAM-integrated line-of-business apps** — with modern authentication, single sign-on, Conditional Access, and app protection — while IT never takes control of the personal device.

The solution is packaged specifically for the US sovereign cloud: the correct **`*.us`** portals, the **`intune_env=FXP`** Government gateway install flag, **US Gov Microsoft Graph** endpoints in every script (`-Environment USGov` / `USGovDoD`), and every **Commercial-vs-Government parity gap** documented at the step where it matters.

## Availability finding (important)
**Tunnel for MAM is fully supported in both GCC High and DoD** — Microsoft lists it among the Intune advanced capabilities available in those environments (verified 2026). This is not a feature you must work around in Government. **However, it does not support FIPS** on the Android or iOS data path — a compliance-relevant constraint that must be reviewed and accepted by your ISSO/ISSM before deployment. Certificate issuance should plan on an **enterprise or public CA**, because **Cloud PKI is GCC-High-only and still "planned."**

## What the customer receives
- **Seven implementation documents** — overview (with a Commercial-vs-GCC-High comparison and availability caveat up front), requirements, click-by-click implementation in the Government portals, testing with pass/fail gates, troubleshooting, best practices, and a cited **GCC High parity reference**.
- **Five PowerShell scripts** — Discovery, Validation, Report (read-only), plus safe Remediation and Scope-Targeting (default **`-WhatIf`**) — all connecting to **US Gov Graph**.
- A gated deployment path — **Assess → Configure → Pilot → Validate → Expand** — so the design is proven on a pilot before it scales.

## Business outcome
A **correctly configured** Tunnel-for-MAM deployment on a GCC High / DoD tenant: BYOD access to intranet resources without device enrollment, the sovereign endpoints right the first time, parity gaps handled, and the no-FIPS decision made consciously — delivered self-guided at a fraction of the cost of a bespoke consulting engagement.

---
*White-label solution. Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time.*


---


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


---


# Requirements Guide — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG

Confirm every requirement below before you configure anything. This list is **in addition to** the category-level prerequisites in `global-requirements-intune-solutions.md` (Entra tenant, Intune subscription, admin roles, pilot group, network access) — but note that for Government you verify those in the **`*.us`** portals, not `*.com`.

Each requirement follows: **Description · Why · Verify · Implement-if-missing.** Where a detail is Government-specific and not fully documented, it is flagged **"verify for GCC High/DoD."**

---

## R1. GCC High or DoD tenant (US sovereign cloud)
**Description:** An active Microsoft 365 **Government** tenant — GCC High or DoD (built on Azure Government, IL4/IL5). Note: "GCC" (standard) is a *different* offering and rides the commercial Intune instance; this solution targets **GCC High / DoD**.
**Why:** The sovereign portals, endpoints, and the `intune_env=FXP` install flag only apply to the Government cloud. Commercial or GCC-standard steps will not match.
**Verify:** Sign in at **`https://portal.azure.us`** and **`https://intune.microsoft.us`**. Your sign-in should redirect through **`login.microsoftonline.us`**. In the Microsoft 365 admin center, the tenant's environment shows a Government plan.
**Implement:** Government tenants are provisioned through Microsoft's Government onboarding / an authorized Government reseller with eligibility validation — not self-service. Engage your Microsoft Government account team.

## R2. Intune Plan 2 (Government) or equivalent add-on
**Description:** Tunnel for MAM is an **Intune advanced capability**. It requires **Microsoft Intune Plan 2** *or* the **Intune Suite** / an additional subscription — in the **Government** SKU.
**Why:** Without the advanced-capability license, the Tunnel-for-MAM policies and the Defender tunnel client return "Invalid Licensing." (Verified: both Android and iOS MAM pages state "This feature requires Microsoft Intune Plan 2 or an additional subscription.")
**Verify:** In **`intune.microsoft.us`** → **Tenant administration → Connectors and tokens / Licensing**, confirm the advanced-capability entitlement. Confirm your users are assigned a Government license that carries Intune Plan 2 (e.g., **Microsoft 365 G5 Gov**, or **Intune Plan 1 Gov + Intune Plan 2 Gov add-on** / **Intune Suite Gov**). **Verify exact SKU availability for GCC High/DoD** with your licensing desk — Government SKU names and bundling differ from Commercial.
**Implement:** Assign the Government Intune Plan 2 / Suite license to pilot users, then all target users.

## R3. Intune Administrator role (Government portal)
**Description:** The operator account holds the **Intune Administrator** Entra role and an Intune license. The account that **registers the Tunnel Gateway** must be Intune Administrator (or equivalent) *and* licensed.
**Why:** Creating server/site configs, app configuration/protection policies, and completing gateway registration all require elevated Intune rights.
**Verify:** In Government Entra (via `portal.azure.us` → Microsoft Entra ID → **Roles and administrators**), confirm **Intune Administrator**. Confirm the same account has an Intune license.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes only.

## R4. Microsoft Tunnel Gateway — Linux host
**Description:** A **Linux server** (on-premises or in Azure Government) that runs a container hosting the Tunnel Gateway software.
**Why:** Tunnel for MAM extends an existing Tunnel Gateway; the gateway is the VPN termination point that bridges devices to your intranet.
**Verify:** Supported OS/container (per Microsoft prerequisites): **Red Hat Enterprise Linux (RHEL) 8.9–9.7 / 10.0 with Podman**, or **Ubuntu 22.04 / 24.04 with Docker CE**; **64-bit AMD/Intel**. Sizing example: **~1,000 devices = 4 CPU, 4 GB RAM, 30 GB disk, 1 server** (scale out with more servers behind a load balancer). Confirm the OS is a supported, patched build.
**Implement:** Stand up the Linux host, install Podman (RHEL) or Docker CE (Ubuntu), and apply your STIG hardening baseline *before* installing Tunnel. (Install steps are in `03-implementation.md`.)
> **Verify for GCC High/DoD:** exact supported RHEL/Ubuntu/Podman/Docker versions move over time — confirm against the current *Microsoft Tunnel prerequisites* page at deployment. ([learn.microsoft.com](https://learn.microsoft.com/en-us/intune/device-security/microsoft-tunnel/prerequisites))

## R5. TLS server certificate (from a non-Cloud-PKI source)
**Description:** A trusted **TLS certificate** (PEM `site.crt`+`site.key`, or `site.pfx`) whose **Subject Alternative Name (SAN)** matches the gateway's **public FQDN or IP**. Key **2048-bit or larger**. OCSP/CRL endpoint reachable from the server.
**Why:** The TLS cert secures the device-to-gateway tunnel. iOS caps public certs at **398 days** (admin-installed roots up to 730); Android recommends 398 days max.
**Verify:** Certificate SAN = gateway FQDN/IP; chain is complete (root + intermediates); not expired; revocation endpoint reachable.
**Implement:** Issue from your **enterprise/on-premises CA** or a **supported public CA**.
> **Government caveat:** Do **not** assume **Microsoft Cloud PKI** — it is **GCC High only and "planned"** (not GA in DoD; verify status in GCC High). Plan certificate issuance on an enterprise or public CA. If your on-prem resources use a **private CA**, you will also need **trusted-root certificate profiles** (see R9).

## R6. Network — inbound/outbound for the gateway
**Description:** Firewall openings for the Tunnel Gateway.
**Why:** Devices reach the gateway inbound; the gateway reaches Intune/Entra/Graph outbound.
**Verify / Implement:**
- **Inbound to gateway:** **TCP 443** and **UDP 443** (UDP improves performance via DTLS; you may disable UDP and force TCP). Optional **TCP 22** for SSH admin.
- **Outbound from gateway (TCP 443):** the Microsoft Tunnel service FQDNs — `*.manage.microsoft.com`, `login.microsoftonline.com`, `graph.microsoft.com`, `*.sts.windows.net`, `*.blob.core.windows.net` / `*.blob.storage.azure.net`, `powerlift-frontdesk.acompli.net`.
> **Verify for GCC High/DoD:** in the sovereign cloud several of these resolve to **`*.us`** Government endpoints (e.g., Government Graph/login). Allow the **US Government** Office 365 / Intune URL & IP ranges published for GCC High/DoD, not only the Commercial list. Confirm the current Government endpoint list before locking firewall rules.

## R7. Public DNS + publicly routable entry point
**Description:** The gateway **Site** uses a **public IP or FQDN** that resolves in **public DNS** to a **publicly routable** address (directly or via a load balancer).
**Why:** Unenrolled BYOD devices connect from the internet; the site endpoint must be reachable and match the TLS SAN.
**Verify:** `nslookup <gateway-fqdn>` from the public internet returns the expected address.
**Implement:** Create the public DNS record; ensure the TLS cert SAN matches it exactly.

## R8. Required mobile apps (BYOD devices)
**Description:** The apps users must have on their **unenrolled** device.
**Why:** These deliver the tunnel client and the managed browser.
**Verify / Implement:**
- **Android Enterprise:** **Microsoft Defender** (the tunnel client — must be **v1.0.4722.0101+**), **Microsoft Edge**, and **Company Portal** (installed but **no sign-in / no enrollment** required). Install manually from Google Play; on unenrolled devices these often will **not** surface in Company Portal.
- **iOS/iPadOS:** **No Company Portal or Defender requirement.** The VPN is provided by the **Tunnel for MAM iOS SDK** compiled into each managed app (and Microsoft Edge). Users need **Microsoft Edge** and your MAM-integrated LOB apps.
> **Verify for GCC High/DoD:** confirm the Government-cloud builds of Defender/Edge/Company Portal support Tunnel for MAM in your tenant.

## R9. Trusted-root certificate profile (if on-prem resources use a private CA)
**Description:** An Intune **trusted certificate profile** carrying your private CA **root and all intermediates**.
**Why:** Edge/LOB apps must trust the on-prem server's TLS chain. Android requires **MAM SDK 9.5.0+** for trusted-root support; iOS SDK requires **DER-encoded X.509 or PEM**. Android can fail chain-building if intermediates are missing — deploy the **full chain**.
**Verify:** Profile contains root + every intermediate; format is DER/PEM.
**Implement:** Create the trusted certificate profile in `intune.microsoft.us` and reference it from the app configuration policy (steps in `03-implementation.md`).

## R10. Line-of-business (LOB) app MAM SDK integration (only if publishing internal apps)
**Description:** Internal iOS/Android apps that will use the tunnel must integrate the **Intune App SDK + MSAL**, and — for iOS — the **Tunnel for MAM iOS SDK**; for Android, MAM SDK **9.5.0+** for trusted roots.
**Why:** The tunnel is scoped to MAM-managed apps; an un-integrated app cannot use it.
**Verify:** App builds link the required SDK versions (iOS: MAM-SDK 16.1.1+, MSAL 1.2.3+, Xcode 14+); Entra app registration matches the app's Bundle/Package ID.
**Implement:** Hand the SDK integration to your app developers (out of scope for infrastructure admins). Microsoft Edge already supports the tunnel with no code work — many agencies pilot with **Edge-only** first.

## R11. Pilot security group (Government Entra)
**Description:** An Entra **security group** of pilot BYOD users (per the category global requirement, in the Government tenant).
**Why:** All three MAM policies must target the **same** groups; you pilot before expanding.
**Verify:** Group **`GRP-TUNMAMG-Pilot`** exists in Government Entra.
**Implement:** Create it (or let the included `TUNMAMG-Set-ScopeTargeting.ps1` build/populate it against US Gov Graph). Naming and reuse are covered in `03-implementation.md`.

---

### Naming convention used throughout this solution
Reuse these names so every artifact is traceable:
| Artifact | Name |
| --- | --- |
| Server configuration | `SC-TUNMAMG-Gov` |
| Tunnel Site | `SITE-TUNMAMG-Gov` |
| App config policy — Defender (Android) | `AC-TUNMAMG-Defender-Android` |
| App config policy — Edge (Android) | `AC-TUNMAMG-Edge-Android` |
| App protection policy — Edge (Android) | `AP-TUNMAMG-Edge-Android` |
| App config policy — Edge/LOB (iOS) | `AC-TUNMAMG-Edge-iOS` |
| App protection policy — iOS | `AP-TUNMAMG-iOS` |
| Trusted root profile | `CERT-TUNMAMG-Root` |
| Pilot group | `GRP-TUNMAMG-Pilot` |
| Production group | `GRP-TUNMAMG-Prod` |

---
*Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time.*


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation Guide — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG · **Model:** Assess → Configure → Pilot → Validate → Expand

This guide is written for a **novice administrator**. It gives full navigation in the **Government** (`*.us`) portals and calls out **GCC-High/DoD caveats inline at the step where they matter**. Reuse the object names from `02-requirements.md`.

> **Portals you will use (Government):**
> - **Intune admin center:** `https://intune.microsoft.us`
> - **Azure Government portal:** `https://portal.azure.us` (Linux VM, networking, Entra ID Government)
> - **Sign-in authority:** `https://login.microsoftonline.us`
> - **Device-login (gateway registration):** `https://microsoft.com/devicelogin`

---

## Phase 1 — Assess (gate 0)

1. Work through `02-requirements.md`. Do not proceed until R1–R8 pass.
2. **Run the Discovery script** from this package to snapshot the Government tenant:
   ```
   powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Discovery.ps1
   ```
   It connects to **US Gov Graph** (`-Environment USGov`) and reports existing Tunnel sites/server configs, Tunnel-for-MAM app config/protection policies, and target groups.
3. **Compliance pre-check (critical):** confirm with your **ISSO/ISSM** that **no-FIPS** on the Tunnel-for-MAM data path is acceptable for the data classification you intend to carry. *Tunnel for MAM does not support FIPS on Android or iOS.* If FIPS is mandated, **stop** — this is not the compliant control.

**Gate 0 → proceed only if:** requirements pass, licensing (Intune Plan 2 Gov) confirmed, and the no-FIPS decision is signed off.

---

## Phase 2 — Configure

You will (A) install the Tunnel Gateway with the **Government install flag**, then (B) create the Server configuration and Site, then (C) layer the Tunnel-for-MAM policies.

### A. Install the Microsoft Tunnel Gateway (Government)

> ⚠️ **The #1 Government mistake:** installing without `intune_env=FXP`. The gateway then registers against **Commercial** Intune and never appears in `intune.microsoft.us`. Do not skip the flag.

1. On the prepared Linux host (R4), download the installer:
   ```
   wget --output-document=mstunnel-setup https://aka.ms/microsofttunneldownload
   ```
2. **Run the installer with the Government cloud flag:**
   ```
   sudo intune_env=FXP ./mstunnel-setup
   ```
   The `intune_env=FXP` variable points the gateway at the **US Government** cloud. (Microsoft's documented Government sequence: run `sudo ./mstunnel-setup`, then `sudo intune_env=FXP ./mstunnel-setup`.) For a rootless Podman container, prefix `mst_rootless_mode=1` as well.
3. Accept the **EULA** when prompted.
4. When prompted, install the **TLS certificate** (R5):
   - **PEM:** full chain → `/etc/mstunnel/certs/site.crt`; private key → `/etc/mstunnel/private/site.key`.
   - **PFX:** → `/etc/mstunnel/private/site.pfx`.
5. **Register with Intune:** the script shows a device code. Browse to **`https://microsoft.com/devicelogin`**, enter the code, and sign in with an **Intune Administrator** account that has an Intune license. Because your tenant is Government, this authenticates against **`login.microsoftonline.us`** automatically.
6. When prompted for a **Site GUID**, you will pick the Site you create in step B (you can create the Server config + Site first, then return — the script resumes where it left off).
7. On RHEL, finish with `mst-cli server restart`.

> **Caveat — proxy/firewall:** if egress passes an SSL-inspecting proxy, add trusted roots to `/etc/mstunnel/ca-trust` and configure the proxy per Microsoft's install doc. In Government, ensure your firewall allows the **US Gov** Intune/Entra/Graph endpoints (R6), not only the Commercial ranges.

### B. Create the Server configuration and Site (in `intune.microsoft.us`)

**Server configuration → name it `SC-TUNMAMG-Gov`:**
1. Sign in to **`https://intune.microsoft.us`**.
2. Go to **Tenant administration → Microsoft Tunnel Gateway → Server configurations tab → Create new**.
3. **Basics:** Name = `SC-TUNMAMG-Gov`. **Next**.
4. **Settings:**
   - **IP address range:** a range that does **not** conflict with your intranet (Microsoft suggests the APIPA range `169.254.0.0/16`).
   - **Server port:** e.g. `443`.
   - **DNS servers:** your internal DNS (so tunnel clients resolve intranet names). Add the DNS server IPs to **split-tunnel include** rules if you use corporate DNS.
   - **DNS suffix search** (optional): your internal domain.
   - **Split tunneling:** add **include** rules for the intranet subnets/hosts BYOD users must reach (e.g., `192.168.0.0/16`). **Never** use a `0.0.0.0` include/exclude — the gateway cannot route with it.
5. **Review + create → Create.**

**Site → name it `SITE-TUNMAMG-Gov`:**
1. **Tenant administration → Microsoft Tunnel Gateway → Sites tab → Create.**
2. **Name** = `SITE-TUNMAMG-Gov`.
3. **Public IP address or FQDN:** the public entry point (R7) — must be resolvable in public DNS and match the TLS SAN.
4. **Server configuration:** select `SC-TUNMAMG-Gov`.
5. **URL for internal network access check:** an internal HTTP(S) URL the server can reach every 5 minutes to prove intranet connectivity.
6. Set upgrade/maintenance-window options as your change process requires. **Create.**
7. Return to the Linux installer (step A.6) and enter this Site's GUID. Confirm the server shows **online** under **Microsoft Tunnel Gateway → Health status**.

**Gate — gateway:** server is **online** and **Internal network accessibility** is healthy before you touch MAM policies.

### C. Configure Tunnel-for-MAM policies

You deploy **three** policies **per platform**, all targeting the **same** group (`GRP-TUNMAMG-Pilot` first). For Android that's two app config policies (Defender, Edge) + one app protection policy (Edge). For iOS that's an app config policy (Edge/LOB) + app protection policy, plus optional trusted-cert profile.

> **Caveat — enrolled devices:** a device may use **either** MDM Tunnel **or** MAM Tunnel, **never both**. Do not deploy MAM Tunnel app-config settings to a device that already has an MDM Tunnel VPN profile — it causes client networking failures.

#### C-Android-1 · App configuration policy — Defender (tunnel client)
Name: **`AC-TUNMAMG-Defender-Android`**
1. In **`intune.microsoft.us`** → **Apps → Configuration → Create → Managed Apps**.
2. **Basics:** Name = `AC-TUNMAMG-Defender-Android`. **Select public apps** → **Microsoft Defender Endpoint** (Android) → **Select → Next**.
3. **Settings → Microsoft Tunnel settings:**
   - **Use Microsoft Tunnel VPN** = **Yes**.
   - **Connection name:** e.g. `mam-tunnel-vpn`.
   - **Select a site** → `SITE-TUNMAMG-Gov`.
   - **Per-App VPN (Android)** *(optional but recommended)*: add **Microsoft Edge** (include Edge so identity-switch and notifications work). Add other managed apps as needed.
   - Do **not** enable **Always-on VPN** — MAM Tunnel for Android does **not** support it; use **Strict Tunnel Mode** via the Edge policy instead to block traffic when the tunnel is down.
4. **Assignments** → add **`GRP-TUNMAMG-Pilot`**. **Next → Create.**
> ⚠️ Target only **one** Defender app config policy per device, pointing at a **single** Site. Multiple Defender policies with different sites cause a race condition and tunnel failure.

#### C-Android-2 · App configuration policy — Edge (identity switch / strict tunnel)
Name: **`AC-TUNMAMG-Edge-Android`**
1. **Apps → Configuration → Create → Managed Apps.** Name = `AC-TUNMAMG-Edge-Android`. Public app = **Microsoft Edge** (Android). **Next.**
2. **Settings → General configuration settings** — add these **Name/Value** pairs (no trailing spaces):
   | Name | Value | Effect |
   | --- | --- | --- |
   | `com.microsoft.intune.mam.managedbrowser.StrictTunnelMode` | `True` | Blocks Edge internet traffic when the MAM tunnel is down |
   | `com.microsoft.intune.mam.managedbrowser.TunnelAvailable.IntuneMAMOnly` | `True` | Identity switch: connect VPN on work account, disconnect on personal/in-private |
3. **Assignments** → **`GRP-TUNMAMG-Pilot`** (same group as the Defender policy). **Create.**

#### C-Android-3 · App protection policy — Edge (auto-start tunnel)
Name: **`AP-TUNMAMG-Edge-Android`**
1. **Apps → Protection → Create → Android.** Name = `AP-TUNMAMG-Edge-Android`. **Next.**
2. **Apps:** Select public apps → **Microsoft Edge → Next.**
3. **Data protection:** scroll to bottom → **Start Microsoft Tunnel connection on app-launch** = **Yes**. **Next.**
4. Pass through **Access requirements** and **Conditional launch** (set to your data-protection standard). 
5. **Assignments** → **`GRP-TUNMAMG-Pilot`** (same group). **Create.**

When all three Android policies target the same group, launching Edge automatically connects the tunnel.

#### C-iOS-1 · App configuration policy — Edge / LOB
Name: **`AC-TUNMAMG-Edge-iOS`**
1. **Apps → Configuration → Create → Managed Apps.** Name = `AC-TUNMAMG-Edge-iOS`.
   - For **Edge**: **Select public apps → Microsoft Edge for iOS/iPadOS.**
   - For **LOB apps**: **+ Select custom apps** → enter the app's **Bundle ID**, Platform **iOS/iPadOS → Add**.
2. **Settings → Microsoft Tunnel for Mobile Application Management settings:**
   - **Use Microsoft Tunnel for MAM** = **Yes**.
   - **Connection name:** `mam-tunnel-vpn`.
   - **Select a Site** → `SITE-TUNMAMG-Gov`.
   - **Root Certificate** (optional): select `CERT-TUNMAMG-Root` if reaching private-CA-protected resources.
3. **Edge identity switch / strict tunnel** — add the same two Name/Value pairs as Android (`StrictTunnelMode` = `True`, `TunnelAvailable.IntuneMAMOnly` = `True`).
4. **Federated Entra tenants only** — add General config Name `com.microsoft.tunnel.custom_configuration`, Value `{"bypassedUrls":["<your-federation-STS-host>"]}` so sign-in bypasses the tunnel for the STS. *(Many Government tenants are federated — do not skip this if yours is.)*
5. **Assignments** → **`GRP-TUNMAMG-Pilot`**. **Create.**

#### C-iOS-2 · App protection policy — iOS
Name: **`AP-TUNMAMG-iOS`**
1. **Apps → Protection → + Create policy → iOS/iPadOS.** Name = `AP-TUNMAMG-iOS`. **Next.**
2. **Apps:** add **Microsoft Edge** (public) and/or your LOB app by **Bundle ID** (+ Select custom apps).
3. Configure **Data protection / Access requirements / Conditional launch** to your standard.
4. **Assignments** → **`GRP-TUNMAMG-Pilot`** (same group). **Create.**

> **iOS reality check:** on iOS the tunnel is **Per-App only** (no device-wide VPN), delivered by the **Tunnel for MAM iOS SDK** — so **LOB apps must be recompiled** with the SDK (Edge works out of the box). VPN connections **do not appear** in iOS Settings. Edge on iOS does **not** support Kerberos or certificate-based auth to on-prem sites (NTLM SSO is supported for Edge, not LOB).

#### C-optional · Trusted-root certificate profile
Name: **`CERT-TUNMAMG-Root`** — needed only if on-prem resources use a **private CA**.
1. **Devices → Configuration → Create → New Policy** → platform (any; a trusted-cert profile for any platform is accepted by Tunnel for MAM) → **Templates → Trusted certificate.**
2. Upload the **root and all intermediate** certs (DER/PEM). Name = `CERT-TUNMAMG-Root`. Create.
3. Reference it from the app config policy's **Root Certificate** selector (C-iOS-1 step 2 / Android app-config Tunnel-for-MAM settings).
> Deploy the **full chain** (root + intermediates). Android/iOS can fail server-trust if intermediates are missing.

---

## Phase 3 — Pilot

1. Ensure all policies for the platform you're piloting target **`GRP-TUNMAMG-Pilot`** only. Use `TUNMAMG-Set-ScopeTargeting.ps1` to build/populate the group (defaults to `-WhatIf`; add `-Commit` to apply).
2. Pilot users install the required apps (R8) manually from the store:
   - **Android:** Microsoft Defender (v1.0.4722.0101+), Microsoft Edge, Company Portal (no sign-in).
   - **iOS:** Microsoft Edge and any MAM-integrated LOB app.
3. Launch **Microsoft Edge**, sign in with the **work/Government** account, browse to an **internal** URL.

**Gate — pilot:** run `TUNMAMG-Validation.ps1` (below) — all checks pass — and pilot users reach intranet resources through Edge.

---

## Phase 4 — Validate

Run the validation script and the manual tests in `05-testing.md`:
```
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Validation.ps1
```
It confirms (read-only, US Gov Graph): gateway site/server present and healthy; the three MAM policies exist and target the same group; licensing/advanced-capability present; no MDM-Tunnel + MAM-Tunnel collision on the same group.

**Gate — validate:** validation clean + intranet access proven + Strict Tunnel Mode blocks traffic when disconnected.

---

## Phase 5 — Expand

1. Create/confirm **`GRP-TUNMAMG-Prod`** and add production BYOD users (use `TUNMAMG-Set-ScopeTargeting.ps1`).
2. Add `GRP-TUNMAMG-Prod` to the **Assignments** of **all** the platform's policies (keep the group set identical across the three policies).
3. Scale the gateway: add Tunnel servers to `SITE-TUNMAMG-Gov` behind a load balancer as device count grows (each server joins the same Site and inherits `SC-TUNMAMG-Gov`).
4. Generate a point-in-time report:
   ```
   powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Report.ps1
   ```
5. Establish operations: monitor **Health status**, keep servers within one version of current (auto-upgrade or maintenance window), and rotate the TLS cert before expiry (`mst-cli import_cert` → `mst-cli server restart`).

**Gate — expand:** production group live, reporting captured, cert-rotation and upgrade runbook documented.

---

## Government install & endpoint quick-reference
| Item | Value (GCC High) | Value (DoD) |
| --- | --- | --- |
| Intune portal | `intune.microsoft.us` | `intune.microsoft.us` |
| Azure portal | `portal.azure.us` | `portal.azure.us` |
| Sign-in authority | `login.microsoftonline.us` | `login.microsoftonline.us` |
| Gateway install flag | `intune_env=FXP` | `intune_env=FXP` |
| Graph endpoint | `graph.microsoft.us` (`-Environment USGov`) | `dod-graph.microsoft.us` (`-Environment USGovDoD`) |

---
*Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time. Steps marked "verify" should be confirmed live in your tenant.*


---


# Testing & Validation — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG

Run these after Phase 2 (Configure) and before Phase 5 (Expand). Each test has an explicit **Pass / Fail** gate. Combine the automated `TUNMAMG-Validation.ps1` run (US Gov Graph, read-only) with the manual device tests below.

---

## A. Automated validation (control plane)

```
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Validation.ps1
```
Connects with `-Environment USGov` and checks the tenant-side configuration.

| # | Check | Pass | Fail action |
| --- | --- | --- | --- |
| A1 | Graph context is a **US Gov** endpoint (`graph.microsoft.us` / `dod-graph.microsoft.us`) | Context shows `.us` host | You're on Commercial Graph — reconnect with `-Environment USGov`/`USGovDoD` |
| A2 | Tunnel **Site** `SITE-TUNMAMG-Gov` exists and references `SC-TUNMAMG-Gov` | Both present, linked | Re-create per `03-implementation.md` §B |
| A3 | At least one Tunnel **server** is registered and **online** | Health = online | If missing, the gateway likely installed **without `intune_env=FXP`** — reinstall with the flag |
| A4 | Android: `AC-TUNMAMG-Defender-Android`, `AC-TUNMAMG-Edge-Android`, `AP-TUNMAMG-Edge-Android` exist | All three present | Create the missing policy |
| A5 | iOS: `AC-TUNMAMG-Edge-iOS`, `AP-TUNMAMG-iOS` exist | Present | Create the missing policy |
| A6 | All policies for a platform target the **same** group(s) | Group sets match | Align assignments (use `TUNMAMG-Set-ScopeTargeting.ps1`) |
| A7 | **Single** Defender app-config policy per targeted device, one Site | Exactly one | Remove duplicates (race-condition risk) |
| A8 | No device/group has **both** MDM-Tunnel and MAM-Tunnel settings | No overlap | Separate the groups — collision breaks networking |
| A9 | Intune **Plan 2 / advanced capability** licensing present | Entitled | Assign Government Intune Plan 2 / Suite |

**Gate A → pass when A1–A9 all pass.**

---

## B. Manual device tests (data plane)

Perform on a real pilot BYOD device in `GRP-TUNMAMG-Pilot`.

### B1 — Android: apps present & tunnel client valid
- Install **Microsoft Defender (v1.0.4722.0101+)**, **Microsoft Edge**, **Company Portal** from Google Play.
- **Pass:** apps installed; Defender does **not** report "Invalid Licensing." **Fail:** "Invalid Licensing" → install the supported Defender version.

### B2 — Android: intranet reachable via Edge
- Open **Edge**, sign in with the **Government work account**, browse to an **internal-only** URL.
- **Pass:** the internal page loads (a brief first-attempt failure right after launch is expected — refresh once). **Fail:** page never loads → check split-tunnel include rules, DNS servers in `SC-TUNMAMG-Gov`, gateway health.

### B3 — Android: Strict Tunnel Mode
- Disconnect the tunnel (or take the gateway unreachable). Try to browse in Edge with the work account.
- **Pass:** internet traffic in Edge is **blocked** until the tunnel reconnects. **Fail:** traffic flows → verify `StrictTunnelMode=True` (no trailing space) in `AC-TUNMAMG-Edge-Android`.

### B4 — Android: identity switch
- Switch Edge to a **personal** account or in-private.
- **Pass:** VPN disconnects for personal, reconnects for work. **Fail:** verify `TunnelAvailable.IntuneMAMOnly=True`.

### B5 — iOS: Edge intranet access (Per-App)
- Install **Edge**, sign in with the work account, browse to an internal URL.
- **Pass:** internal page loads via the SDK-provided Per-App VPN (note: **no VPN entry appears in iOS Settings** — that is expected). **Fail:** check Site selection in `AC-TUNMAMG-Edge-iOS`, and for **federated** tenants confirm the `bypassedUrls` STS entry.

### B6 — iOS: LOB app (if applicable)
- Launch an SDK-integrated LOB app; access an on-prem resource.
- **Pass:** resource loads through the tunnel. **Fail:** confirm the app links **Tunnel for MAM iOS SDK + MSAL**, Bundle ID matches the Entra app registration, and the `Tunnel_Allow` API permission has admin consent.

### B7 — Private-CA resource trust (if applicable)
- Access an on-prem site secured by your **private CA**.
- **Pass:** no certificate error. **Fail:** deploy `CERT-TUNMAMG-Root` with **root + all intermediates**; on Android, manually install the root on the device if a WebView LOB app still fails.

**Gate B → pass when every applicable B-test passes on at least two pilot devices per platform.**

---

## C. Government-specific verification

| # | Check | Pass |
| --- | --- | --- |
| C1 | All admin work performed in **`*.us`** portals (`intune.microsoft.us`, `portal.azure.us`) | Yes |
| C2 | Gateway installed with **`intune_env=FXP`** and visible in `intune.microsoft.us` | Yes |
| C3 | Scripts connected via **US Gov Graph** (`-Environment USGov` / `USGovDoD`) — no `*.com` calls | Yes |
| C4 | **No-FIPS** limitation reviewed and accepted by ISSO/ISSM for the data carried | Signed off |
| C5 | Firewall allows the **US Government** Intune/Entra/Graph endpoint ranges (not only Commercial) | Yes |
| C6 | Certificate source is enterprise/public CA (**not** assumed Cloud PKI, which is GCC-High-only/planned) | Yes |

**Gate C → pass when C1–C6 confirmed.** Only then proceed to **Expand**.

---
*Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time.*


---


# Troubleshooting — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG

Symptom → likely cause → fix. Government-specific issues are marked **[GOV]** and appear first because they are the most common cause of "it worked in Commercial but not here."

---

## Government-specific issues **[GOV]**

### The Tunnel Gateway installed successfully but never appears in `intune.microsoft.us`
**Cause:** The gateway was installed **without** the Government cloud flag, so it registered against the **Commercial** Intune service.
**Fix:** Reinstall referencing the Government cloud: `sudo intune_env=FXP ./mstunnel-setup`. Confirm under **Tenant administration → Microsoft Tunnel Gateway → Health status** in `intune.microsoft.us`. This is the single most frequent Government failure.

### Scripts return no data / authenticate to the wrong tenant
**Cause:** Connected to **Commercial** Graph (`graph.microsoft.com`) instead of US Gov.
**Fix:** Reconnect with `Connect-MgGraph -Environment USGov` (GCC High) or `-Environment USGovDoD` (DoD). The provided scripts default to `USGov`; pass DoD parameters for DoD. Verify with `(Get-MgContext).Environment` and confirm the endpoint host ends in `.us`.

### Admin can't find Tunnel settings / "the portal looks different"
**Cause:** Signed in to a `*.com` portal.
**Fix:** Use `https://intune.microsoft.us` and `https://portal.azure.us`. Sign-in should route through `login.microsoftonline.us`.

### Gateway can reach the internet but can't register with Intune
**Cause:** Firewall allows only Commercial endpoint ranges.
**Fix:** Allow the **US Government** Office 365/Intune/Entra/Graph endpoint ranges (`*.manage.microsoft.com` and the Gov `login`/`graph` `*.us` hosts). Re-verify against the current Government endpoint list.

### First-time sign-in fails in Edge/LOB app on a federated Government tenant
**Cause:** The federation **STS** URL is being routed through the tunnel before authentication completes.
**Fix:** In the Edge/LOB app configuration policy add General config key `com.microsoft.tunnel.custom_configuration` = `{"bypassedUrls":["<your-federation-STS-host>"]}`. Many Government tenants are federated — do not skip this.

### Compliance flags the deployment for FIPS
**Cause:** Tunnel for MAM does **not** support FIPS (Android or iOS) — expected behavior, not a misconfiguration.
**Fix:** This cannot be enabled. Obtain ISSO/ISSM acceptance for the data classification, or select a FIPS-validated alternative for this path.

### Planned to issue certificates from Cloud PKI — it's not available
**Cause:** Cloud PKI is **GCC High only and "planned"** (not GA in DoD; verify in GCC High).
**Fix:** Issue the TLS server cert (and trusted-root material) from an **enterprise/on-premises CA** or a supported **public CA**.

---

## Gateway / infrastructure

### Server shows offline or "Internal network accessibility" unhealthy
**Cause:** Gateway service down, network path blocked, or the internal check URL unreachable.
**Fix:** On the host run `mst-cli server restart` (required after install on RHEL 8.4+). Confirm inbound **TCP/UDP 443** reach the server and the site's **internal network access check URL** resolves from the server.

### TLS certificate errors when devices connect
**Cause:** SAN mismatch, incomplete chain, expired cert, or unreachable OCSP/CRL.
**Fix:** Ensure the cert **SAN = the site's public FQDN/IP**, the **full chain** is installed (`site.crt` root+intermediates, `site.key` unencrypted), it isn't expired (iOS ≤ 398 days for public certs), and the revocation endpoint is reachable from the server. Update with `mst-cli import_cert` → `mst-cli server restart`.

### Upgrades not applying
**Cause:** Manual-approval upgrade mode or a maintenance window.
**Fix:** Approve pending upgrades, or check the site's maintenance-window settings. Stay within one version of the current release.

---

## Android device issues

### Defender: "Invalid Licensing, please contact administrator"
**Cause:** Defender for Endpoint version predates Tunnel support.
**Fix:** Install Defender **v1.0.4722.0101+** from Google Play. (Also confirm Intune Plan 2 / advanced-capability licensing is assigned.)

### Tunnel doesn't auto-connect when Edge launches
**Cause:** The three Android policies don't all target the **same** group, or the app protection "Start Microsoft Tunnel connection on app-launch" is not set.
**Fix:** Confirm `AC-TUNMAMG-Defender-Android`, `AC-TUNMAMG-Edge-Android`, and `AP-TUNMAMG-Edge-Android` all target the same group; set app-launch start = **Yes** in the protection policy.

### Tunnel connects then drops / behaves erratically
**Cause:** Multiple Defender app-config policies with different Sites (race condition), or Always-on VPN enabled.
**Fix:** Target **one** Defender policy per device with **one** Site. Do **not** enable Always-on VPN with MAM Tunnel — use **Strict Tunnel Mode** in the Edge policy instead.

### Strict Tunnel Mode not blocking traffic
**Cause:** `StrictTunnelMode` key missing/mistyped or has a **trailing space**; or device isn't AM-API enrolled (for device-wide strict mode).
**Fix:** Set `com.microsoft.intune.mam.managedbrowser.StrictTunnelMode` = `True` with no trailing space in `AC-TUNMAMG-Edge-Android`.

### The three required apps aren't visible in Company Portal
**Cause:** Expected on unenrolled devices.
**Fix:** Have users install Defender, Edge, and Company Portal **manually** from Google Play (links in `02-requirements.md`).

### Edge can't reach internal resource immediately after launch
**Cause:** Edge attempts the connection before the tunnel establishes.
**Fix:** Refresh the page once the tunnel connects — expected transient behavior.

### Private-CA internal site fails (WebView LOB app / Defender cert error)
**Cause:** Missing intermediates or Defender not yet trusting the private root.
**Fix:** Deploy `CERT-TUNMAMG-Root` with **root + all intermediates**; if a WebView LOB app still fails, manually install the root on the device. For Defender's private-CA TLS error, manually install the corresponding root on the device.

---

## iOS/iPadOS device issues

### No VPN entry appears in iOS Settings
**Cause:** Expected — the Tunnel for MAM iOS SDK provides a Per-App VPN scoped to the app's networking layer; it is not a system VPN.
**Fix:** None needed. Verify via `mst-cli` active client connections instead.

### LOB app can't use the tunnel
**Cause:** App not integrated with the required SDKs, or Entra app registration mismatch.
**Fix:** Ensure the app links **Tunnel for MAM iOS SDK + Intune App SDK + MSAL** (Xcode 14+, MAM-SDK 16.1.1+, MSAL 1.2.3+); the app's **Bundle ID** must match the Entra app registration; grant admin consent to **Microsoft Tunnel Gateway (`Tunnel_Allow`)** and **Microsoft Mobile Application Management** API permissions; add the **`acct`** optional access-token claim.

### MFA Conditional Access breaks the iOS tunnel
**Cause:** Known issue — the Authenticator app doesn't complete the token flow for Tunnel-for-MAM CA MFA.
**Fix:** Implement `onTokenRequiredWithCallback` in the LOB app's Tunnel Delegate class.

### Edge on iOS can't authenticate to an on-prem site
**Cause:** Kerberos and certificate-based auth to on-prem sites are **not supported** by Tunnel for MAM on iOS Edge.
**Fix:** Use a supported auth method (NTLM SSO is supported for Edge, not LOB apps). No workaround for Kerberos/cert-based.

### Both Tunnel VPN and Defender VPN drop on sleep (iOS combined mode)
**Cause:** "Disconnect on Sleep" without properly configured On-Demand rules.
**Fix:** Configure On-Demand rules (Per-App VPN recommended); note SSO conflicts with an all-domains connect rule + Disconnect-on-Sleep.

---

## General

### A device using both MDM Tunnel and MAM Tunnel has networking failures
**Cause:** A device may use **either** MDM Tunnel or MAM Tunnel, never both simultaneously.
**Fix:** Separate the groups so no device receives both an MDM Tunnel VPN profile and MAM Tunnel app-config settings.

### Newly added custom (LOB) app doesn't show in the policy UI
**Cause:** Known admin-center UX refresh issue.
**Fix:** Refresh the Intune admin center and reopen the policy; the Bundle ID should then appear.

---

*If a symptom isn't listed, re-run `TUNMAMG-Validation.ps1` (US Gov Graph) to localize the fault to control plane vs data plane, then consult the matching section above. Verify all GCC-High/DoD specifics against current Microsoft US Government documentation.*


---


# Best Practices — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG

Field-tested guidance for running Tunnel for MAM correctly on a **GCC High / DoD** tenant. Grouped by theme; Government-specific items are marked **[GOV]**.

---

## Deployment discipline
- **Follow the gates.** Assess → Configure → Pilot → Validate → Expand. Never add production users until pilot validation (`05-testing.md`) is clean.
- **Edge-first pilot.** Microsoft Edge uses the tunnel with **no code changes**. Pilot with Edge to an internal web app before investing in LOB SDK integration — it de-risks the infrastructure independently of app development.
- **Reuse the naming convention** (`SC-`, `SITE-`, `AC-`, `AP-`, `CERT-`, `GRP-TUNMAMG-*`). Traceable objects make audits, troubleshooting, and the included scripts reliable.
- **Keep assignment groups identical** across the three policies for a platform. Mismatched targeting is the most common reason "the tunnel doesn't auto-connect."

## Government correctness **[GOV]**
- **Always install the gateway with `intune_env=FXP`.** Bake it into your build automation so no one can forget. A gateway registered without it lands in Commercial and silently never appears in `intune.microsoft.us`.
- **Standardize on `*.us` everywhere** — portals (`intune.microsoft.us`, `portal.azure.us`), sign-in (`login.microsoftonline.us`), and Graph (`graph.microsoft.us` / `dod-graph.microsoft.us`). Update bookmarks, runbooks, and any automation copied from a Commercial project.
- **Pin the right Graph environment in scripts:** `-Environment USGov` for GCC High, `-Environment USGovDoD` for DoD. The scripts in this package default to USGov — change the parameter for DoD.
- **Firewall the Government endpoints.** Allow the **US Government** Office 365/Intune URL & IP ranges, not the Commercial set. Re-verify the published Government endpoint list periodically.
- **Federated tenants:** most Government tenants federate. Configure the Edge/LOB `bypassedUrls` value with your **federation STS host** or first-time sign-in through the tunnel will fail.

## Security & compliance **[GOV]**
- **Treat no-FIPS as a design constraint, not a footnote.** Tunnel for MAM does not support FIPS on Android or iOS. Get written ISSO/ISSM acceptance for the data classification before go-live; if FIPS is mandated for this path, choose a different control.
- **STIG-harden the Linux host** to the DISA MDM/EMM baseline and enable **auditd** (install `mst.rules`) so tunnel activity is logged for your SIEM.
- **Least privilege:** operators hold **Intune Administrator**, not Global Administrator. The gateway registers with an interactive sign-in once; thereafter it uses app credentials — no stored user passwords.
- **Conditional Access:** gate tunnel access with CA (device/user risk, compliant app, MFA). Note the known iOS issue: with an MFA grant on the Tunnel Gateway CA policy, LOB apps must implement `onTokenRequiredWithCallback` — coordinate with developers.
- **Rootless Podman** on RHEL 8.8+ reduces container-escape blast radius (throughput ceiling ~230 Mbps per rootless server — size accordingly).

## Certificates & PKI **[GOV]**
- **Do not assume Cloud PKI.** It is **GCC High only and "planned"** (not GA in DoD; verify in GCC High). Issue the TLS server cert from an **enterprise or supported public CA**.
- **SAN must match** the public FQDN/IP of the Site exactly. Mind lifetimes: iOS public certs ≤ **398 days**.
- **Deploy full chains.** For private-CA-protected intranet resources, put **root + all intermediates** in `CERT-TUNMAMG-Root`; missing intermediates cause Android/iOS server-trust failures.
- **Automate rotation:** replace `site.crt`/`site.key` (or `site.pfx`) → `mst-cli import_cert` → `mst-cli server restart`. Use `import_cert delay <minutes>` to stage a cutover.

## Networking & performance
- **Split-tunnel deliberately.** Include only the intranet ranges BYOD users need; keep general internet off the tunnel to protect capacity and privacy. Never use a `0.0.0.0` include/exclude.
- **Add corporate DNS** to the Server configuration **and** to split-tunnel include rules, or internal name resolution fails.
- **Scale horizontally.** Add servers to the same Site behind a load balancer; ~4 CPU / 4 GB / 30 GB per ~1,000 devices is Microsoft's starting point — measure and grow.
- **UDP on** (DTLS) for best performance; only disable UDP (force TCP) if your network blocks it, and only after clients use Defender as the tunnel client.

## Platform gotchas
- **One tunnel model per device.** MDM Tunnel and MAM Tunnel must not coexist on the same device — segregate groups.
- **Android:** no Always-on VPN with MAM Tunnel; use Strict Tunnel Mode instead. One Defender app-config policy, one Site. The required apps often won't appear in Company Portal on unenrolled devices — tell users to install manually.
- **iOS:** Per-App only, SDK-delivered, invisible in iOS Settings. Edge on iOS does not support Kerberos or cert-based auth to on-prem sites; native WebSocket APIs are unsupported (JavaScript WebSockets in web views work).

## Operations
- **Monitor Health status** and internal-network-accessibility per site; alert on server offline.
- **Stay within one version** of the current Tunnel release; use maintenance windows to control upgrades.
- **Re-run the scripts** on a cadence: `TUNMAMG-Validation.ps1` after any change, `TUNMAMG-Report.ps1` for periodic evidence, `TUNMAMG-Discovery.ps1` when onboarding a new admin.
- **Document your deltas.** Record any place you had to "verify for GCC High/DoD" and what you found — Microsoft updates Government parity often; your notes are the next admin's shortcut.

---
*Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time.*


---


# Deliverables Summary — Microsoft Tunnel for MAM — Government (GCC High) Edition

**Solution code:** TUNMAMG · **Platform:** Microsoft Intune · **Cloud:** US Sovereign (GCC High / DoD)

Everything included in this solution package and what each piece is for.

---

## Documents (source)
| File | Purpose |
| --- | --- |
| `executive-summary.md` | Business framing, the availability finding, and the no-FIPS caveat for decision-makers. |
| `01-solution-overview.md` | What Tunnel for MAM is on GCC High, the **Commercial vs GCC High — what's different** comparison, and the availability caveat up front. |
| `02-requirements.md` | Every prerequisite (R1–R11) with **verify** + **implement** steps and the object naming convention. |
| `03-implementation.md` | Ordered, click-by-click steps in the **`*.us`** portals — gateway install with `intune_env=FXP`, server config, site, and the three MAM policies per platform — with Government caveats inline. |
| `05-testing.md` | Automated (control-plane) + manual (data-plane) tests with explicit **pass/fail gates**, plus Government-specific verification. |
| `06-troubleshooting.md` | Symptom → cause → fix, weighted toward GCC-High-specific gotchas. |
| `07-best-practices.md` | Operational guidance; Government-specific items marked **[GOV]**. |
| `gcc-high-parity-notes.md` | Cited Commercial-vs-Government parity reference (availability, FIPS, portals, Graph endpoints, Cloud PKI, licensing). |
| `08-deliverables-summary.md` | This file. |

*(Category-level prerequisites are published once in `global-requirements-intune-solutions.md`.)*

---

## PowerShell scripts (`scripts/`)
All connect to **US Government Microsoft Graph** (`-Environment USGov`; pass DoD parameters for `USGovDoD`). Discovery/Validation/Report are **read-only**; Remediation and Set-ScopeTargeting default to **`-WhatIf`** (no change until you add `-Commit`).

| Script | Type | What it does |
| --- | --- | --- |
| `TUNMAMG-Discovery.ps1` | Read-only | Inventories the Government tenant: Tunnel sites/server configs, Tunnel-for-MAM app config/protection policies, target groups, and confirms the Graph context is a US Gov endpoint. |
| `TUNMAMG-Validation.ps1` | Read-only | Checks the deployment against this solution's expected state (gates A1–A9 in `05-testing.md`): site/server present & online, all three policies per platform exist and share assignment groups, single Defender policy, no MDM/MAM collision, licensing present. |
| `TUNMAMG-Report.ps1` | Read-only | Produces a point-in-time summary/evidence report (console + optional CSV/JSON) of the Tunnel-for-MAM configuration for audits and change records. |
| `TUNMAMG-Remediation.ps1` | Safe write (`-WhatIf` default) | Proposes and (with `-Commit`) applies safe fixes — e.g., aligning assignment groups across the three policies, flagging duplicate Defender policies. Never deletes gateway infrastructure. |
| `TUNMAMG-Set-ScopeTargeting.ps1` | Safe write (`-WhatIf` default) | Creates/populates the pilot and production groups (`GRP-TUNMAMG-Pilot` / `GRP-TUNMAMG-Prod`) and can align policy assignments to them. |

**Run pattern:**
```
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Discovery.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Validation.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Report.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Set-ScopeTargeting.ps1   # add -Commit to apply
powershell -ExecutionPolicy Bypass -File .\scripts\TUNMAMG-Remediation.ps1          # add -Commit to apply
```

---

## Named objects this solution creates
`SC-TUNMAMG-Gov` (server config) · `SITE-TUNMAMG-Gov` (site) · `AC-TUNMAMG-Defender-Android`, `AC-TUNMAMG-Edge-Android`, `AP-TUNMAMG-Edge-Android` (Android policies) · `AC-TUNMAMG-Edge-iOS`, `AP-TUNMAMG-iOS` (iOS policies) · `CERT-TUNMAMG-Root` (trusted root, if needed) · `GRP-TUNMAMG-Pilot`, `GRP-TUNMAMG-Prod` (groups).

---

## Deployment model
**Assess → Configure → Pilot → Validate → Expand**, with a go/no-go gate between phases (including a Government compliance gate for the no-FIPS decision).

---
*White-label solution. Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time.*
