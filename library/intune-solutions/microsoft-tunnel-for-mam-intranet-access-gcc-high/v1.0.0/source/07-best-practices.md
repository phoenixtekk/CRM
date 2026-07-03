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
