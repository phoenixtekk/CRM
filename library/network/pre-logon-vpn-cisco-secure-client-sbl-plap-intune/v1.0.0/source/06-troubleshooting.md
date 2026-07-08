# Troubleshooting — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Vendor boundary:** problems on the **Cisco head-end** (tunnel-group rejects the cert, ISE posture
> denies access, gateway config, head-end CA trust) are **deferred to Cisco's official documentation
> and your Cisco admin**. This guide resolves the **Intune/Entra/Windows delivery** side and tells you
> when a failure points at the Cisco side.

---

## §PLAP option not showing — no "Network sign-in" at the logon screen

**Symptom:** You lock or sign out and the **"Network sign-in"** (PLAP) option never appears at the
Windows logon screen, so there is no way to bring the tunnel up before logon.

1. **`UseStartBeforeLogon` is not `true` in the deployed profile.** This is the most common cause. The
   PLAP credential provider stays dormant unless the VPN client profile XML in
   `%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile` contains
   `<UseStartBeforeLogon>true</UseStartBeforeLogon>`. Confirm with `SBLVPN-Validation.ps1`; if it's
   missing or `false`, redeploy the **SBL-enabled** XML (R6) via the Win32 package.
2. **The Start Before Logon module is not installed.** The SBL module registers the PLAP DLL
   (`vpnplap64.dll`). If the client is present but `vpnplap64.dll` is missing (check
   `%ProgramFiles(x86)%\Cisco\Cisco Secure Client\vpnplap64.dll`), the Win32 package installed Core
   only. Fix the install script to install the **Start Before Logon** module and update the detection
   rule to check for the PLAP DLL on `Cisco Secure Client – Pre-Logon (SBL) – Win32`.
3. **Wrong install order (SBL before Core).** The Start Before Logon module must install **after** the
   Core VPN module. If the order was reversed, correct the `install.cmd` (Core first, then SBL) and
   redeploy.
4. **No reboot after install.** SBL/PLAP registration may require a reboot to surface at the logon
   screen. Reboot the device and re-check.
5. **PLAP credential provider not registered.** Confirm a Cisco PLAP entry exists under
   `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`. If the module
   installed but no provider is registered, reinstall the SBL module (the client is present but the
   provider registration failed).

## §Tunnel up but logon fails — pre-logon connects yet Windows sign-in doesn't work

**Symptom:** The pre-logon tunnel establishes at the logon screen, but the subsequent Windows logon
fails (e.g. "no logon servers available", first-time logon rejected, password change won't complete).

1. **Domain controller not reachable over the tunnel.** The tunnel is up but the DC isn't routed. Check
   the profile's **tunnel mode / split-tunnel routes** (R7) — the domain controller subnets must be
   inside the tunnel. Confirm with your network team that DC subnets are reachable from the VPN pool.
2. **DNS not resolving internal names pre-logon.** The pre-logon tunnel must hand the client internal
   DNS so the DC's name resolves. Verify DNS settings pushed by the head-end (Cisco-side) and that the
   client uses them before logon.
3. **The device certificate authenticated the tunnel, but the head-end doesn't grant DC access.** ISE
   posture/authorization or the tunnel-group ACL may allow the tunnel but restrict traffic — a
   **Cisco-side** decision, deferred to Cisco docs. Capture the tunnel-group name and work it with your
   Cisco admin.
4. **Cached-credential test masks the issue.** If you tested with a user who has logged on before,
   Windows may be using cached credentials rather than the tunnel. Re-test with a **first-time / no
   cached credential** logon to truly exercise pre-logon.

## §Certificate issues — device certificate missing, wrong, or rejected

**Symptom:** `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows` fails, the pre-logon
tunnel can't authenticate, or no certificate is present at the logon screen.

1. **SCEP profile not applied / not yet delivered.** Confirm the profile shows *Succeeded* in Intune
   and the device has synced. `SBLVPN-Discovery.ps1` shows whether the profile is assigned to
   `PILOT – Pre-Logon VPN (SBL) Users`; `SBLVPN-Remediation.ps1 -FixMissingAssignments` adds a missing
   assignment.
2. **Certificate issued to the user store, not the machine store.** Pre-logon needs a **Device
   (machine)** certificate in `LocalMachine\My`. If **Certificate type** was set to *User*, the cert
   isn't available at the logon screen. Set **Certificate type = Device** on the SCEP profile (R8) and
   redeploy.
3. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Confirm `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows` is *Succeeded*, then
   the SCEP profile.
4. **SCEP infrastructure error.** Check NDES / Intune Certificate Connector health and the SCEP server
   URL(s) in the profile. Re-sync after fixing.
5. **Head-end doesn't trust the issuing CA (Cisco side).** If the cert is issued correctly but the
   tunnel still rejects it, the **Cisco head-end must trust the issuing CA** — this trust config is
   **Cisco-side, deferred to Cisco docs**. Provide your Cisco admin the issuing CA chain.
6. **Certificate expired (pre-logon suddenly stopped working).** A previously working device lost
   pre-logon when its device cert expired. Confirm the **renewal threshold** (R10) precedes expiry;
   re-issue and watch cert status in `SBLVPN-Report.ps1`.

## §Install failures — the Win32 app won't install

**Symptom:** Intune shows `Cisco Secure Client – Pre-Logon (SBL) – Win32` as *Failed* or stuck
*Pending*.

1. **Device not synced / not in the group.** Confirm the device's user is a member of
   `PILOT – Pre-Logon VPN (SBL) Users` and the assignment intent is **Required**. Force a sync (Company
   Portal → **Sync**, or `SBLVPN-Remediation.ps1 -RetryFailedInstalls`).
2. **Detection rule wrong.** If detection doesn't match what the installer writes, Intune reports
   *Failed* even when the client installed — or reports *Installed* when only Core (not SBL) is present.
   Fix the detection rules (Core MSI product code **and** the PLAP DLL `vpnplap64.dll`) on the app.
3. **Install command / order / silent switches wrong.** Verify `install.cmd` installs **Core first,
   then the Start Before Logon module** silently and returns success (exit 0/3010), then drops the XML.
   Check the Intune Management Extension log
   (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`).
4. **XML not landing in the profile directory.** If the client installs but there is no VPN profile,
   confirm the install step copies the SBL-enabled XML into
   `%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile`.
5. **Architecture / OS requirement mismatch.** Confirm the app **Requirements** are x64 and the minimum
   OS matches Cisco's support matrix.

## §Profile not applying — the Intune VPN profile doesn't take

**Symptom:** `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows` shows *Error*/*Conflict*, or
the connection entry never appears.

1. **Profile not assigned to the group.** Confirm it's assigned to `PILOT – Pre-Logon VPN (SBL) Users`.
   `SBLVPN-Discovery.ps1` flags UNASSIGNED profiles; `SBLVPN-Remediation.ps1 -FixMissingAssignments`
   adds the assignment.
2. **App not installed yet.** The profile configures the *client*; if the app isn't installed, resolve
   §Install failures first, then re-sync.
3. **Conflicting VPN profile / leftover config.** Another VPN profile (or a leftover Cisco config)
   targeting the same device can conflict. Remove/scope it so only the pre-logon profile applies.
4. **Bundled XML vs Intune profile disagree.** If you ship the SBL-enabled XML in the Win32 package
   *and* push the Intune VPN profile, keep them consistent (same gateway/behavior). Validate with
   `SBLVPN-Validation.ps1`.

## §Reporting/script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts
   need only `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** —
   confirm the object is named to convention verbatim (including the en-dash `–` and spacing). Rename
   any drifted object to the convention.
3. **Validation says SBL missing but the option shows.** The script checks for `vpnplap64.dll` and the
   PLAP registration; confirm the Cisco program path for your version and, if Cisco changed it, note the
   actual path (per Cisco docs) — the logon-screen option is the ground truth.
4. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with
   `-WhatIf:$false` after reviewing the previewed actions.

---

If a failure persists after the Intune/Entra/Windows side is confirmed healthy (validation PASS,
profiles *Succeeded*, device cert issued, PLAP option showing) and the pre-logon tunnel still won't
establish or authenticate, treat it as a **Cisco head-end issue** and continue with **Cisco's official
documentation** and your Cisco admin.
