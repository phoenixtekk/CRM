# Troubleshooting — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common. On **any** failed provisioning,
run `GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap` **before** wiping the device — a wipe destroys the
evidence you need.

> **Vendor boundary:** problems on the **GlobalProtect portal / gateway** (portal rejects the auth
> method, gateway routing, head-end CA trust) are **deferred to Palo Alto Networks' official
> documentation and your Palo Alto admin**. This guide resolves the **Intune / Autopilot / Windows
> delivery** side and tells you when a failure points at the Palo Alto side.

---

## §"Unzipping" / 0x87D30067 — the Win32 app fails to unzip during Autopilot

**Symptom:** `GlobalProtect – Connect Before Logon (PLAP) – Win32` fails during the Enrollment Status
Page with an **"unzipping"** error; the IME log shows **`0x87D30067`**. The IME downloaded the
`.intunewin` but could not extract it into its content/cache path.

1. **Antivirus is locking or scanning the IMECache during extraction.** This is the most common cause.
   Microsoft Defender or a third-party AV holds a lock on
   `C:\Program Files (x86)\Microsoft Intune Management Extension\Content` (the IMECache) while the IME
   tries to unzip. **Add that path (and the IMECache) to the AV exclusion list applied during
   provisioning** (R11) and re-provision.
2. **Low disk space.** Extraction needs room for the unzipped payload. Confirm the device has adequate
   free disk; clear space and retry.
3. **Corrupt or improperly re-wrapped `.intunewin`.** A package wrapped from an **already-wrapped**
   payload (nesting), or wrapped with a stale tool, extracts inconsistently. **Re-wrap cleanly** with the
   **current Microsoft Win32 Content Prep Tool** (R12) from a minimal source folder (the MSI + the
   script) — never nest an already-wrapped file.
4. **Path / permission tampering.** A hardened image or a GPO that alters permissions on the IME content
   path can block extraction. Confirm the IME content path exists with default permissions.
5. **Verify the source folder.** Confirm the MSI and the install script are actually present in the
   source folder you wrapped, and the install command matches the script filename.

Confirm the fix: `GPPLAP-Collect-Logs.ps1` flags `0x87D30067` in the IME log; after the AV exclusion and a
clean re-wrap, the app installs and the flag is gone.

## §PLAP tile not visible — no Connect Before Logon / network sign-in at the sign-in screen

**Symptom:** Provisioning finishes but the **Connect Before Logon / network sign-in** tile never appears
at the Windows 11 sign-in screen, so there is no way to bring the tunnel up before logon.

1. **GlobalProtect app is below 5.2.** Connect Before Logon does not exist before app **5.2**. Confirm the
   installed version with `GPPLAP-Validation.ps1`; if it is below 5.2, package the correct MSI (R6) and
   redeploy.
2. **`Prelogon` registry not set.** The PLAP provider stays dormant unless
   `HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\Prelogon` = `1` (with a `Portal` value under
   the same key). Confirm with `GPPLAP-Validation.ps1`; if missing, fix the install script to write the
   `PanSetup` registry **before** registration and redeploy.
3. **`PanGPS.exe -registerplap` was never run, or not in the SYSTEM context.** Registration is what adds
   the tile. It must run as **SYSTEM** (the Win32 app runs as System). If the app ran as user, or the
   registration step was skipped, the provider is not registered — confirm the credential-provider
   registration under `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`
   and set the app's **Install behavior = System**, then redeploy.
4. **Registration ran before the GlobalProtect service (PanGPS) was ready.** If `-registerplap` executed
   before `PanGPS` was *Running*, registration silently no-ops. Add the **service-readiness wait** to the
   install script (poll `Get-Service PanGPS` until *Running*, bounded) so registration always runs after
   the service exists; redeploy.
5. **No reboot after install.** The tile may only surface after a reboot. Ensure the app **returns 3010**
   so the ESP takes the reboot (see the next section) and re-check at the sign-in screen.

## §Install fails after reboot / IME state lost — a reboot loop or lost app state

**Symptom:** The app "installs" then the device reboots and the install is lost, retried, or the ESP
loops; the IME log shows the agent restarting mid-install.

1. **The install script called a forced `Restart-Computer`.** This is the root cause to eliminate. A
   scripted reboot during the ESP interrupts the Intune Management Extension and loses app state. **Remove
   any `Restart-Computer` from the script** and instead **`exit 3010`** so **Intune/ESP owns the reboot**.
2. **Return codes not mapped on the app.** If the app does not know `3010` means "soft reboot", it treats
   the reboot request as a failure. On the Win32 app, map return codes: `0`/`1707` success, **`3010` soft
   reboot**, `1618` retry.
3. **Missing `Start-Process … -Wait`.** Without `-Wait`, the MSI (or `-registerplap`) returns immediately
   and the app reports complete before the work finishes — the reboot then lands mid-install. Ensure the
   MSI and the registration are launched with `-Wait`.
4. **Device restart behavior override.** Set the app's **Device restart behavior** to *Determine behavior
   based on return codes* so the `3010` mapping actually drives the reboot.

## §Autopilot ESP hangs on the app — provisioning blocks and never releases

**Symptom:** The Enrollment Status Page sits on `GlobalProtect – Connect Before Logon (PLAP) – Win32` and
never completes.

1. **The app genuinely failed (unzip / install error).** Check the IME log via `GPPLAP-Collect-Logs.ps1`;
   resolve per §"Unzipping" / 0x87D30067 or §Install fails after reboot.
2. **Detection rule never becomes true.** If detection checks something the install never writes, the app
   never reports *Installed* and the ESP blocks forever. Detection must check **GP≥5.2 AND `Prelogon=1`
   AND the PLAP credential-provider registration** — and each of those must actually be produced by the
   install. Fix the detection rule to match what the script writes.
3. **The app returns an unmapped non-zero code.** If the script exits with a code the app treats as
   failure (and it is not `3010`/`1618`), the ESP fails. Confirm the script's exit codes and the app's
   return-code mapping.
4. **App not correctly on the ESP blocking list.** Confirm the app is listed under the ESP's blocking apps
   (`ESP – Autopilot – GlobalProtect PLAP Blocking`) and that the device's group is in the ESP's scope.

## §Enrollment-time device group empty — nothing deploys during Autopilot

**Symptom:** The device provisions but the GlobalProtect PLAP app (and any profile) never targets it; the
Autopilot **device group is empty at enrollment** even though you added devices.

1. **The group is missing the Provisioning Client SP owner.** Enrollment-time device grouping only works
   when the **Assigned** group is **owned** by the Intune Provisioning Client service principal
   (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**). Add the SP as an **owner**: Entra → **Groups >
   <group> > Owners > Add owners** → search by **AppId** (the display name, often *Intune Autopilot
   ConfidentialClient*, varies). `GPPLAP-Discovery.ps1` flags a missing SP owner;
   `GPPLAP-Set-ScopeTargeting.ps1` sets it.
2. **The group is Dynamic, not Assigned.** Enrollment-time grouping needs an **Assigned** group. If the
   group was created as Dynamic, recreate it as **Assigned** and re-add devices + the SP owner.
3. **The SP is absent from the tenant.** If the Provisioning Client SP cannot be found, provision it by
   opening the Intune portal **once as a Global Administrator**, then add it as owner.

## §Works on Windows 10 but not Windows 11 (or vice-versa)

**Symptom:** The exact same package that behaved on the Windows 10 test machine behaves differently on the
Windows 11 production target (tile missing, registration timing, or install result differs).

1. **You validated on the wrong OS.** Early testing here was on Windows 10; **production is Windows 11**.
   Do not assume parity — **re-test the full flow on Windows 11** (pilot device, `GPPLAP-Validation.ps1`,
   and the sign-in-tile check). Make Windows 11 the pilot OS.
2. **OS-version requirement mismatch on the app.** Confirm the app's **Requirements** minimum OS matches
   the Windows 11 target and Palo Alto's support matrix, so the app is *Applicable* on Windows 11.
3. **Service-readiness timing differs across OS builds.** If registration timing is marginal, the
   difference surfaces as "works on one OS, not the other." Ensure the **service-readiness wait** is
   present (not a fixed sleep) so registration reliably follows `PanGPS` becoming *Running* on either OS.
4. **If a Windows 10 estate remains,** treat it as a **separate target** and re-validate there rather than
   shipping the Windows-11-validated package blindly.

## §Tunnel up but hybrid first-logon fails — Connect Before Logon connects yet Windows sign-in doesn't work

**Symptom:** The Connect Before Logon tunnel establishes at the sign-in screen, but the subsequent
first-time **hybrid domain** logon fails ("no logon servers available", first-time logon rejected, or
password change won't complete).

1. **Domain controller not reachable over the tunnel.** The tunnel is up but the DC isn't routed. Confirm
   with your Palo Alto/network team that the **DC subnets are inside the tunnel** and reachable from the
   VPN pool. Split-tunnel routing that excludes DC subnets is a common cause (Palo Alto-side).
2. **On-prem Domain Join (ODJ) not completing.** Hybrid Azure AD Join Autopilot completes domain join via
   the **Intune Connector for Active Directory**. Confirm the connector is **Active** (R4) and the
   **Domain Join** profile targets the right domain/OU; a device that can reach the DC but has no ODJ blob
   won't finish join.
3. **DNS not resolving internal names pre-logon.** The pre-logon tunnel must hand the client internal DNS
   so the DC name resolves. Confirm DNS pushed by the portal/gateway (Palo Alto-side) is applied before
   logon.
4. **Time skew.** A large clock difference between the device and the DC breaks Kerberos/domain logon.
   Confirm the device time is correct (Autopilot devices off-network can drift before first sync).
5. **Certificate rejected by the portal (cert auth).** If Connect Before Logon uses a certificate and the
   tunnel authenticates but access is denied, the **portal must trust the issuing CA** — a **Palo
   Alto-side** trust decision, deferred to Palo Alto docs. Provide your Palo Alto admin the issuing CA
   chain; confirm the device cert is a **machine** cert in `LocalMachine\My` (T4).
6. **Cached-credential test masks the issue.** If you tested with a user who has signed in before, Windows
   may use cached credentials rather than the tunnel. **Re-test with a first-time / no-cached-credential
   logon** to truly exercise pre-logon reachability.

## §Certificate issues — device certificate missing, wrong store, or rejected (cert-auth deployments)

**Symptom:** `GlobalProtect – PLAP – Device Cert (SCEP) – Windows` fails, or the pre-logon tunnel can't
authenticate.

1. **SCEP profile not applied yet.** Confirm the profile shows *Succeeded* in Intune and the device has
   synced. `GPPLAP-Discovery.ps1` shows whether it is assigned to the pilot device group.
2. **Certificate issued to the user store, not the machine store.** Connect Before Logon needs a **Device
   (machine)** certificate in `LocalMachine\My` (there is no user context at the sign-in screen). If
   **Certificate type** was *User*, set it to **Device** and redeploy.
3. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Confirm the trusted-root profile is *Succeeded*, then the SCEP profile.
4. **Head-end doesn't trust the issuing CA (Palo Alto side).** If the cert is issued correctly but the
   portal still rejects it, the **portal/gateway must trust the issuing CA** — Palo Alto-side, deferred to
   Palo Alto docs.

## §Reporting / script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph -Scope
   CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts need only
   `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** — confirm
   the object is named to convention verbatim (including the en-dash `–` and spacing). Rename any drifted
   object to the convention.
3. **Discovery flags the group's SP owner as missing but you added it.** Confirm you added the SP by
   **AppId** `f1346770-5b25-470b-88bd-d5744ab7952c` (the display name varies) and that the group is
   **Assigned**, not Dynamic.
4. **Validation says PLAP not registered but the tile shows.** The script checks the credential-provider
   registration and the GP service/DLL; if Palo Alto changed the program path/DLL name for your version,
   note the actual path (per Palo Alto docs) — the **logon-screen tile is the ground truth**.
5. **Log collector missing sections.** Run `GPPLAP-Collect-Logs.ps1` **elevated** so the IME logs, MDM
   diagnostics, and Event channels can be read; confirm the source paths exist on this device.

---

If a failure persists after the Intune / Autopilot / Windows side is confirmed healthy (validation PASS,
app *Installed*, `Prelogon=1`, PLAP registered, the Connect Before Logon tile showing, and the tunnel
establishing) and the **hybrid logon still fails or the portal still rejects the connection**, treat it as
a **GlobalProtect portal / gateway issue** and continue with **Palo Alto Networks' official documentation**
and your Palo Alto admin.
