# Troubleshooting — Pre-Logon VPN Symptom → Cause → Fix Matrix

This is the heart of the product: a comprehensive **symptom → likely cause → fix** matrix for
pre-logon VPN, covering **both** mechanisms — Cisco **Start Before Logon (SBL/PLAP)** and the Windows
Always On VPN **device tunnel**. Work top-down within a section; the first cause listed is the most
common. Everything here stays **read-only** on the diagnostic side — the *fix* changes state and is
applied in the owning plane (see `03-implementation.md` Phase 3).

> **Vendor boundary:** the **VPN head-end / gateway** internals — the Cisco Secure Client profile
> editor and ASA/FTD config, and the RRAS / third-party IKEv2 gateway config, including which issuing
> CA the gateway trusts — are **deferred to the vendor's official documentation and your gateway
> admin**. This guide resolves the **Windows / Intune / certificate** side and tells you when a
> failure points at the gateway.

> Reuse names verbatim: **`Pre-Logon VPN – Device Tunnel – Profile`**,
> **`Pre-Logon VPN – SBL Module – Win32`**, **`Pre-Logon VPN – SBL – Profile`**,
> **`Pre-Logon VPN – Trusted Root`**, **`Pre-Logon VPN – Device Cert (SCEP)`**,
> **`PILOT – Pre-Logon VPN Devices`**.

---

## §SBL/PLAP — the Network sign-in tile is missing

**Symptom:** On the Windows logon screen there is **no "Network sign-in" / PLAP option**, so the user
can't bring the VPN up before signing in. `PLAPDX-Check-PlapSbl.ps1` shows the first FAIL.

1. **Start Before Logon module not installed.** The tile needs the **SBL module** MSI, and **Core VPN
   must be installed first**. If `PLAPDX-Check-PlapSbl.ps1` reports the module absent, deploy
   `Pre-Logon VPN – SBL Module – Win32` (Core VPN as a dependency/first) to the device group and
   re-sync.
2. **`UseStartBeforeLogon` not set to true.** Even with the module installed, the tile only appears
   when the Secure Client **VPN profile** carries `<UseStartBeforeLogon>true</UseStartBeforeLogon>`.
   The check reports the value it found; if it's `false`/absent, set it in `Pre-Logon VPN – SBL –
   Profile` and re-push.
3. **`vpnplap64.dll` missing or PLAP provider not registered.** The 64-bit PLAP DLL renders the tile
   and must be registered as a credential provider under
   `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`. If the DLL is
   present but the provider isn't registered (or vice-versa), the module install is broken — repair/
   reinstall the SBL module so `vpnplap64.dll` registers.
4. **32-bit vs 64-bit mismatch.** On modern 64-bit Windows the PLAP component is **`vpnplap64.dll`**;
   a leftover 32-bit `vpnplap.dll` from an old install won't render the tile. Confirm the 64-bit DLL is
   the one present and registered.
5. **VPN profile not present on the device.** If the Secure Client profile that carries the SBL flag
   never arrived, there's nothing to read the flag from. Confirm the profile is present (the collector
   lists it) and that its Intune assignment reached the device.
6. **Wrong mechanism for this device.** If this machine was designed to use the **device tunnel**, the
   missing SBL tile is expected — run `PLAPDX-Check-DeviceTunnel.ps1` instead (see the next section).

## §SBL/PLAP — the tile appears but the connection fails

**Symptom:** The Network sign-in tile shows, the user picks it, but the VPN won't connect or
authentication is rejected.

1. **Certificate rejected (if cert auth).** Run `PLAPDX-Check-Certificate.ps1`. A missing/expired cert,
   a cert without the **Client Authentication** EKU, or a broken chain is the usual cause — see
   §Certificate below.
2. **Gateway doesn't trust the issuing CA (vendor side).** If the cert is valid device-side but the
   head-end still rejects it, the **gateway must trust the issuing CA** — this trust config is
   **vendor-side, deferred to vendor docs**. Give your gateway admin the issuing-CA name from the
   certificate check.
3. **Gateway/head-end unreachable pre-logon.** The pre-logon network may not resolve or reach the
   gateway FQDN. Confirm the machine can reach the head-end from the pre-logon context (a captive
   portal or missing route breaks this) — a transport problem, not an Intune one.
4. **Secure Client version mismatch.** If the head-end requires a different client version than
   installed, align the packaged version and re-pilot. Exact head-end version requirements are
   vendor-side.

## §Device tunnel — never establishes at boot

**Symptom:** The Always On VPN **device tunnel** doesn't come up before logon; `Get-VpnConnection
-AllUserConnection` shows it disconnected or absent. `PLAPDX-Check-DeviceTunnel.ps1` shows the FAIL.

1. **Wrong OS SKU or join type.** The device tunnel requires **Windows Enterprise or Education** and a
   **domain-joined or hybrid-joined** device. On Pro or an Entra-only (not hybrid) join, the device
   tunnel is unsupported — the check flags this first. Fix the SKU/join, or use SBL instead.
2. **Profile assigned to a user context instead of the device.** The device tunnel connects with **no
   user** at boot, so its profile (VPNv2 CSP / ProfileXML) must be **device-scoped** — assigned to a
   **device** group, not a user group. Run `PLAPDX-Check-Intune.ps1`; if `Pre-Logon VPN – Device
   Tunnel – Profile` is assigned to a user group, re-assign it to `PILOT – Pre-Logon VPN Devices` (a
   device group).
3. **More than one device tunnel.** Windows allows **exactly one** device tunnel per device. A second
   device tunnel (a leftover or a duplicate profile) makes the tunnel fail. The check counts them;
   remove the extra.
4. **Not IKEv2.** Device tunnels support **IKEv2 only**. If the profile's connection type is anything
   else, reissue `Pre-Logon VPN – Device Tunnel – Profile` as IKEv2.
5. **Missing `DeviceTunnel=true` / `AlwaysOn=true`.** If the ProfileXML doesn't set both flags, Windows
   treats it as an ordinary user tunnel that never auto-connects at boot. The check reads both flags;
   fix the ProfileXML and re-push.
6. **Machine certificate problem.** The device tunnel authenticates with a **machine certificate** in
   `LocalMachine\My` (Client Auth EKU). If it's missing/expired/wrong-EKU, the tunnel can't
   authenticate — see §Certificate.

## §Certificate — the machine / VPN certificate is the fault

**Symptom:** `PLAPDX-Check-Certificate.ps1` FAILs on one or more facts; the tunnel or SBL connect is
rejected at authentication.

1. **No certificate present.** No client-authentication certificate in `LocalMachine\My`. The
   **trusted root must be deployed first**, then the SCEP/PKCS cert. Deploy `Pre-Logon VPN – Trusted
   Root`, then `Pre-Logon VPN – Device Cert (SCEP)`, and re-sync.
2. **Wrong EKU.** A certificate present but **without the Client Authentication EKU** won't be accepted
   for VPN. Fix the certificate template / SCEP profile to include Client Authentication
   (`1.3.6.1.5.5.7.3.2`).
3. **Expired / not-yet-valid (clock skew).** An in-date cert can appear **not-yet-valid** or **expired**
   if the device clock is off. The check flags expiry and not-yet-valid; if the dates look fine but
   validation still fails on time, check device time sync — this masquerades as a cert fault.
4. **Chain incomplete / untrusted root.** The cert chains to a root the device doesn't trust — the
   `Pre-Logon VPN – Trusted Root` profile is missing or failed. Deploy/repair it so the chain
   completes.
5. **No private key.** A cert imported without its key (a PKCS export issue, or SCEP key generation
   failed) can't be used for authentication. Reissue so the private key is present.
6. **Issued by the wrong CA.** Pass `-CaThumbprint <expected>` to confirm the issuing CA matches the
   design. A cert from the wrong CA/template will be rejected by a gateway that only trusts the
   intended issuer.
7. **Valid device-side but rejected at the gateway.** A clean chain locally plus a gateway rejection
   means the **gateway's trust store** doesn't include your issuing CA (or checks revocation it can't
   reach). Resolved on the **gateway side** — give the admin the issuer name; **deferred to vendor
   docs**.

## §Cross-cutting — affects either mechanism

1. **Profile assigned to the wrong context.** A device-tunnel profile on a **user** group, or an
   SBL/cert profile that never applies because the device isn't in the target group. `PLAPDX-Check-
   Intune.ps1` shows assignment and scope; correct group membership / target.
2. **Domain controller not reachable through the tunnel before logon.** Even with the tunnel/tile up, a
   first-time user can't log on if **no DC is reachable** over the pre-logon path (the tunnel's routes
   don't include the DC subnets, or DNS for the domain doesn't resolve pre-logon). This is a
   routing/DNS design issue on the tunnel/gateway side.
3. **Device not synced / not enrolled.** Nothing (module, profile, cert) applies to a device that isn't
   enrolled and syncing. Confirm enrollment and force a sync, then re-collect.
4. **Naming drift.** The Intune check matches objects **by exact display name**. If an object was
   renamed off the convention (including the en-dash `–` and spacing), it shows MISSING though it
   exists. Rename it back to convention.

## §Script / tooling issues

1. **Access denied reading `LocalMachine\My` or the Credential Providers key.** Run the device-side
   scripts **elevated** (R2). Read-only, but elevation is needed for visibility.
2. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the read scopes `PLAPDX-Check-Intune.ps1` lists in its header.
3. **`Get-VpnConnection -AllUserConnection` returns nothing.** Either there is genuinely no device
   tunnel (a valid finding — see §Device tunnel) or you didn't run elevated; confirm elevation first.

---

## When to stop diagnosing and escalate to the gateway vendor

Diagnosis is read-only by design. When the **Windows / Intune / certificate** side is confirmed clean
(the focused checks PASS and the collector shows no FAIL) but the tunnel still won't authenticate,
treat it as a **gateway / head-end issue** and continue with the **vendor's official documentation**
and your gateway admin. Hand over: the certificate check output (issuer, EKU, validity, chain), a
statement that the device side is clean, and the exact rejection time so the admin can find the attempt
in the gateway log. A complete package turns a multi-round case into a single decisive one.
