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
