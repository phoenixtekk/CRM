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
