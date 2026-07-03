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
