# Best Practices — The Managed-App Model

Guidance for running Cisco Secure Client per-app VPN on managed iOS/Android well, over time.

## Keep the tunnel truly per-app

- **Never** promote the profile to device-wide to "make it work." If an app won't tunnel, fix the
  **association**, not the scope. A device-wide VPN reintroduces the backhaul, battery, and privacy
  problems this solution exists to solve.
- On iOS, always keep **Automatic VPN = Per-app VPN** with **on-demand**; on Android keep the
  **allow-list** tight to named packages. Review both whenever you touch the profile.

## Managed = tunneled: enforce the "managed" half

- The association only works for **Intune-managed** app instances. Deploy every business app that
  should tunnel **through Intune** and, where possible, block/prevent unmanaged copies (e.g. require
  managed-app install, use app protection policies) so users can't accidentally run an untunneled
  personal copy.
- Keep an authoritative list of the **associated apps** (bundle IDs / package names). Treat it as the
  contract: an app is only in scope if it is on this list *and* managed.

## Name everything, reuse verbatim

- Use `Cisco Per-App VPN – iOS`, `Cisco Per-App VPN – Android`, `Cisco Per-App VPN – User Cert`,
  `PILOT – Per-App VPN Users`, `BROAD – Per-App VPN Users` exactly and consistently. Consistent names
  make the discovery, validation, report, and remediation scripts reliable and make audits trivial.

## Pilot first, expand in waves

- `PILOT – Per-App VPN Users` → validate all gates in `05-testing.md` → only then
  `BROAD – Per-App VPN Users`, in waves. Run `CPAVPN-Report.ps1` between waves to confirm coverage
  tracks expectation.

## Authentication hygiene

- Prefer **certificate authentication** (silent, per-app-friendly) via `Cisco Per-App VPN – User
  Cert`. Match subject/SAN and EKU to the head-end's expectation (per Cisco docs) and monitor
  **certificate expiry/renewal** — an expired cert silently breaks the tunnel for every associated
  app at once.
- Keep the **trusted root** deployed alongside the client cert so chain validation never fails.

## Respect the vendor boundary

- The Cisco head-end (connection profile, address pool, split-tunnel/split-DNS, posture, ISE policy)
  is **Cisco's domain** — change it in Cisco's consoles per **Cisco's official documentation**, and
  keep the Intune profile's **server address / connection name** in sync with it. When a tunnel issue
  is clearly head-end-side (routing, posture, address pool), escalate to the Cisco side rather than
  editing Intune blindly.

## Align with Conditional Access

- Put the same audience in `PILOT – Per-App VPN Users` and in the **Conditional Access** policy that
  requires **compliant, managed** devices for the business apps. Then the app that tunnels is also the
  app that must originate from a healthy, enrolled device — network scope and identity scope reinforce
  each other.

## Platform-specific notes

- **iOS:** keep target devices **supervised (ADE)** and **APNs** healthy — per-app association is most
  reliable there, and APNs is the delivery lifeline for all iOS policy.
- **Android:** keep **Managed Google Play** connected and reference apps by **package name**. Validate
  the allow-list after any app repackaging or package-name change.

## Operate with the scripts

- Run `CPAVPN-Discovery.ps1` before changes (read-only baseline), `CPAVPN-Validation.ps1` per device
  when investigating, `CPAVPN-Report.ps1` on a schedule for coverage, and `CPAVPN-Remediation.ps1`
  (default `-WhatIf`) to preview any association fix before applying it. Always preview, then apply.

## Change control and rollback

- Make VPN/association changes in a **change window** with the rollback ready (un-assign the profile
  from the group). Communicate to affected users, since it changes how business apps reach internal
  resources.
