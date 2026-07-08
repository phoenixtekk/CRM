# Best Practices — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

Field-proven practices for the deploy-and-diagnose model. These make the Autopilot build predictable,
reversible, and easy to troubleshoot when the enrollment sequence misbehaves.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** The app, the cert profile, the device
  groups, the ESP reference, and the filter all follow the Implementation table (`GlobalProtect –
  Connect Before Logon (PLAP) – Win32`, `PILOT – GlobalProtect PLAP – Autopilot Devices`, …). The
  discovery, validation, log-capture, and report scripts find objects **by these names** — drift breaks
  automation and reporting (including the en-dash `–` and spacing).
- **Prefer the single Win32 app.** Keep install, the `PanSetup` registry, the service-readiness wait, and
  `PanGPS.exe -registerplap` in **one** app. Splitting them into a two-app model reintroduces the
  ordering/reboot seam where the unzip and sequencing failures cluster — only split when your environment
  already does.
- **Keep pilot and production device groups separate and both assigned.**
  `PILOT – GlobalProtect PLAP – Autopilot Devices` stays assigned after expansion so you retain a fast
  Windows 11 test cohort.

## Autopilot enrollment-time targeting
- **Use an Assigned group owned by the Provisioning Client SP.** Enrollment-time device grouping only
  works when the group is **Assigned** (not Dynamic) and the Intune Provisioning Client service principal
  (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**) is an **owner**. Without the owner the group is empty
  at enrollment and nothing deploys — verify the owner in discovery, not just the group.
- **Make the app an ESP blocking app.** So provisioning **waits** for Connect Before Logon to install and
  register before the user reaches the desktop, and honors the app's `3010` reboot at the right moment.

## Reboot sequencing (the rule that removes the biggest failure)
- **Never call `Restart-Computer` from the install script during the ESP.** It interrupts the Intune
  Management Extension and causes install failures / lost state. **Return exit code `3010`** and let
  **Intune/ESP** own the reboot.
- **Map the return codes on the app:** `0`/`1707` = success, `3010` = soft reboot, `1618` = retry.
- **Always `Start-Process … -Wait`** for the MSI (and for `-registerplap`) so the app never reports
  complete before the installer/registration actually finishes.

## Avoiding the "unzipping" 0x87D30067 failure
- **Exclude the IME content/IMECache path from AV during provisioning**
  (`C:\Program Files (x86)\Microsoft Intune Management Extension\Content` and the IMECache). AV locking
  or scanning the cache during extraction is the most common cause.
- **Re-wrap cleanly with the current Content Prep Tool.** Never nest an already-wrapped payload; keep the
  source folder minimal (MSI + script). Keep enough free disk on target devices.

## Connect Before Logon correctness
- **Require GlobalProtect ≥ 5.2.** Connect Before Logon does not exist below 5.2 — enforce it in the
  app's detection rule, not just the requirements.
- **Set the `PanSetup` registry before registration and before the sign-in screen.** `Prelogon = 1` and
  the default `Portal` must exist before `-registerplap` and before the lock screen is reached.
- **Register PLAP as SYSTEM, after the service is ready.** Run `PanGPS.exe -registerplap` in the System
  context (the Win32 app runs as System), and only after `PanGPS` is *Running* — add a bounded readiness
  wait rather than a fixed sleep.
- **Detect all three conditions.** Detection should check GP≥5.2 **and** `Prelogon=1` **and** the PLAP
  credential-provider registration — detecting only the MSI hides a device where the tile will never
  appear.

## Windows 11 vs Windows 10
- **Pilot and validate on the production OS (Windows 11).** "Works on Win10, not Win11" (or the reverse)
  is a real early-signal in this scenario — never assume parity. Re-test the full flow on Windows 11 and,
  if a Windows 10 estate remains, test it as a separate target.

## Diagnose fast
- **Keep `GPPLAP-Collect-Logs.ps1` in the test-window kit.** On any failed provisioning, capture the IME
  logs (`IntuneManagementExtension.log`, `AgentExecutor.log`, `AppWorkload.log`), the
  `MdmDiagnosticsTool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -zip` bundle, and the
  GlobalProtect `PanGPS`/`PanGPA` logs **before** wiping and retrying — a wipe destroys the evidence.
- **Read the IME log for the app exit code.** The `3010`/`1618`/error the app returned, and the unzip
  `0x87D30067` if present, are in `IntuneManagementExtension.log` / `AppWorkload.log`.

## Certificates (if cert auth)
- **Use a Device (machine) certificate.** There is no user context at the sign-in screen; issue the cert
  to `LocalMachine\My` and deploy the trusted root **first**, then the SCEP profile.
- **Ensure the portal trusts the issuing CA** (Palo Alto-side trust config per Palo Alto docs) and set a
  renewal threshold comfortably before expiry so Connect Before Logon never silently loses auth.

## Change control and rollback
- **Keep a one-click rollback ready:** exclude the group, remove the app from the ESP blocking list, or
  flip the Win32 app to **Uninstall** (running `PanGPS.exe -unregisterplap` first). Test the rollback
  (Testing T10) before you ever need it.
- **Deploy inside a change window** and announce it — this changes the provisioning and sign-in
  experience for real users.
- **Version your inputs.** Track which GlobalProtect MSI version, portal FQDN, and auth method a given
  rollout used, so you can reproduce or revert precisely.

## Security hygiene
- **Never embed VPN credentials.** Use the portal's certificate or SAML/credential prompt at the Connect
  Before Logon window; do not store secrets in the registry or the package.
- **Least-privilege admin.** Use Intune Administrator + Groups Administrator for the operator; a Global
  Administrator may be needed once to provision/own the first-party SP on the group.
- **Keep the client patched.** Update the app package when Palo Alto releases fixes; pilot the new version
  on Windows 11 before fleet-wide expansion, same as any change.
