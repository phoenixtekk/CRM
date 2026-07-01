# Best Practices — Cisco Secure Client (AnyConnect) VPN via Intune

Field-proven practices for the assign-once, repeat-everywhere model. These make the deployment
predictable, reversible, and easy to operate at scale.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** Apps, VPN profiles, the cert
  profile, groups, and filters all follow `Cisco Secure Client – VPN – …` / `PILOT – Cisco VPN
  Users`. The discovery, validation, report, and remediation scripts find objects **by these names**
  — drift breaks automation and reporting.
- **One app + one profile per platform.** Keep exactly one app object and one VPN profile per
  platform. Do not fork "test" copies in production; use assignment (pilot vs prod group) to stage.
- **Keep pilot and production groups separate and both assigned.** `PILOT – Cisco VPN Users` stays
  assigned after expansion so pilot members keep the client and you retain a fast test cohort.

## Pilot-first, always
- **Never skip the pilot,** even for "simple" profile changes. Every change to the app package or the
  VPN profile goes to `PILOT – Cisco VPN Users` first and passes the Testing gates before production.
- **Cover every platform in the pilot.** Include at least one Windows, macOS, iOS, and Android device
  so a platform-specific packaging or profile issue is caught before fleet rollout.
- **Expand in waves.** For large fleets, add production sub-groups over several days and watch
  `CSCVPN-Report.ps1` between waves rather than assigning everyone at once.

## The app-plus-profile discipline
- **Always deploy the app and the matching profile to the same group.** A device should be either
  fully ready or clearly not — never an installed client with no connection defined, or a profile
  with no client.
- **Use assignment filters** (e.g. `Filter – Cisco VPN – Windows`) to scope by OS/ownership when a
  single group spans platforms, so each platform's app/profile only targets the right devices.

## Authentication and certificates
- **Prefer certificate authentication** for silent, always-available connect on managed devices.
  Deliver the device/user cert via `Cisco Secure Client – VPN – Device Cert (SCEP)` and ensure the
  **issuing CA is trusted by the Cisco head-end** (Cisco-side trust config per Cisco docs).
- **Deploy the trusted root/intermediate first,** then the SCEP profile, then the VPN profile that
  references the cert — order matters so the cert exists when the VPN needs it.
- **Watch certificate lifetime and renewal.** SCEP renewal thresholds should comfortably precede
  expiry so devices never lose connectivity; monitor cert profile status in the report.
- **For SAML/Entra SSO**, keep the client and profile deployment Intune-side and let the head-end own
  the SAML trust — no secrets are provisioned to the device.

## Packaging (Windows/macOS)
- **Use the vendor's signed binaries.** Do not re-sign or repackage Cisco installers; use the exact
  entitled version your head-end supports (macOS PKG must stay Cisco-signed for Gatekeeper/detection).
- **Bundle the VPN client profile XML in the Win32/PKG package** for immediate connection defaults on
  Windows/macOS, and keep it in sync with any Intune VPN profile so the two never contradict.
- **Write precise detection rules** (MSI product code / binary version) so Intune reports install
  truth — vague detection produces false "installed"/"failed" noise.
- **Set install behavior to System** and match Cisco's supported OS/architecture in Requirements.

## Change control and rollback
- **Keep a one-click rollback ready:** exclude the group, or flip the Windows Win32 app to
  **Uninstall**. Test the rollback (Testing T8) before you ever need it.
- **Deploy inside a change window** and announce it — remote-access changes affect real users.
- **Version your inputs.** Track which installer version, XML profile, and gateway values a given
  rollout used, so you can reproduce or revert precisely.

## Operate and monitor
- **Run `CSCVPN-Report.ps1` on a schedule** (e.g. weekly) to track coverage drift as devices enroll
  and leave, and to catch profile *Error* states early.
- **Remediate safely.** `CSCVPN-Remediation.ps1` defaults to **-WhatIf** — always preview the planned
  actions, then re-run with `-WhatIf:$false`. Never let a remediation run act without a preview first.
- **Least-privilege admin.** Use Intune Administrator + Groups Administrator for the operator; reserve
  Global Administrator for tenant-wide changes only.

## Security hygiene
- **Never store VPN credentials in Intune profiles.** Use certificate or SAML auth; where
  username/password is unavoidable, let the client prompt — do not embed secrets.
- **Scope Per-App VPN deliberately.** Only tunnel the apps that need internal access; over-broad
  tunneling hurts performance and privacy.
- **Keep the client patched.** Update the app package when Cisco releases fixes; pilot the new version
  before fleet-wide expansion, same as any change.
