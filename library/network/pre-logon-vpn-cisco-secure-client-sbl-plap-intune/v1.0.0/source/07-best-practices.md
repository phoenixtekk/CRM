# Best Practices — Pre-Logon VPN with Cisco Secure Client Start Before Logon (SBL/PLAP) via Intune

Field-proven practices for the assign-once, repeat-everywhere model. These make the pre-logon
deployment predictable, reversible, and easy to operate at scale.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** The app, the VPN profile, the two
  certificate profiles, the groups, and the filter all follow `Cisco Secure Client – Pre-Logon … ` /
  `PILOT – Pre-Logon VPN (SBL) Users`. The discovery, validation, report, and remediation scripts find
  objects **by these names** — drift breaks automation and reporting.
- **One app + one VPN profile + one cert chain for pre-logon.** Keep exactly one Win32 app, one VPN
  profile, one trusted-root profile, and one device-cert profile. Do not fork "test" copies in
  production; use assignment (pilot vs prod group) to stage.
- **Keep pilot and production groups separate and both assigned.** `PILOT – Pre-Logon VPN (SBL) Users`
  stays assigned after expansion so pilot members keep the build and you retain a fast test cohort.

## Get Start Before Logon actually working (the three non-negotiables)
- **Install Core first, then the Start Before Logon module.** Order matters — the SBL module layers on
  Core. Enforce the order in the Win32 install script.
- **Ship a profile with `<UseStartBeforeLogon>true</UseStartBeforeLogon>`.** The PLAP credential
  provider stays dormant unless the deployed VPN profile sets this to `true`. Bundle the SBL-enabled XML
  in the Win32 package and drop it into the Secure Client profile directory on install.
- **Detect the SBL component, not just the client.** Add a detection rule on the PLAP DLL
  (`vpnplap64.dll`) so a device missing the Start Before Logon module is reported *not installed* rather
  than a false *Installed*.
- **Reboot to surface the PLAP option** if SBL registration requires it, so testers actually see
  "Network sign-in" at the logon screen.

## Pilot-first, always
- **Never skip the pilot,** even for "simple" profile changes. Every change to the app package, the SBL
  XML, or the certificate profile goes to `PILOT – Pre-Logon VPN (SBL) Users` first and passes the
  Testing gates (including the decisive pre-logon connect + logon test) before production.
- **Test the real scenarios in the pilot.** Include a **first-time / no-cached-credential** logon and an
  **off-network password change** — the situations pre-logon exists for — not just a normal re-logon.
- **Expand in waves.** For large fleets, add production sub-groups over several days and watch
  `SBLVPN-Report.ps1` between waves rather than assigning everyone at once.

## Certificates and pre-logon authentication
- **Use a Device (machine) certificate — never a user certificate — for pre-logon.** There is no user
  context at the logon screen; only a machine cert in `LocalMachine\My` can authenticate the pre-logon
  tunnel. Deliver it via `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`.
- **Deploy the trusted root/intermediate first,** then the device SCEP certificate, then the VPN
  profile that references the cert — order matters so the cert exists when the tunnel needs it.
- **Set a renewal threshold comfortably before expiry** (e.g. renew at 20% remaining lifetime).
  Pre-logon breaks silently the moment the cert expires — treat certificate lifecycle as a first-class,
  monitored concern, not a set-and-forget.
- **Ensure the issuing CA is trusted by the Cisco head-end** (Cisco-side trust config per Cisco docs);
  a correctly issued cert still fails if the head-end doesn't trust its chain.

## Packaging (Windows)
- **Use the vendor's signed binaries.** Do not re-sign or repackage Cisco installers; use the exact
  entitled version (Core VPN + Start Before Logon modules) your head-end supports.
- **Keep the bundled XML and any Intune VPN profile in sync.** If you ship the SBL-enabled XML in the
  Win32 package *and* push `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`, keep gateway and
  behavior identical so the two never contradict.
- **Set install behavior to System** and match Cisco's supported OS/architecture (x64) in Requirements.

## Change control and rollback
- **Keep a one-click rollback ready:** exclude the group, or flip the Windows Win32 app to
  **Uninstall** (which removes the SBL/PLAP component and the "Network sign-in" option). Test the
  rollback (Testing T9) before you ever need it.
- **Deploy inside a change window** and announce it — changes to the *logon experience* affect real
  users the moment they lock or reboot.
- **Version your inputs.** Track which Core/SBL module version, SBL-enabled XML, and gateway values a
  given rollout used, so you can reproduce or revert precisely.

## Operate and monitor
- **Run `SBLVPN-Report.ps1` on a schedule** (e.g. weekly) to track coverage drift and to catch an
  expiring or failed device certificate early — before it silently breaks pre-logon.
- **Remediate safely.** `SBLVPN-Remediation.ps1` defaults to **-WhatIf** — always preview the planned
  actions, then re-run with `-WhatIf:$false`. Never let a remediation run act without a preview first.
- **Least-privilege admin.** Use Intune Administrator + Groups Administrator for the operator; reserve
  Global Administrator for tenant-wide changes only.

## Security hygiene
- **Never store VPN credentials in Intune profiles.** Pre-logon uses the device certificate; where
  interactive auth is unavoidable, let the PLAP window prompt — do not embed secrets.
- **Protect the machine key.** Prefer a TPM-backed key storage provider for the device certificate so
  the private key is hardware-protected.
- **Keep the client patched.** Update the Core/SBL module package when Cisco releases fixes; pilot the
  new version (re-verify the PLAP option still appears) before fleet-wide expansion.
