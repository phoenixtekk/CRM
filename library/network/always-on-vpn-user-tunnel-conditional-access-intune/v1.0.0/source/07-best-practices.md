# Best Practices — Windows Always On VPN: User Tunnel with Conditional Access via Intune

Field-proven practices for the assign-once, repeat-everywhere model. These make the user tunnel
predictable, reversible, and easy to operate at scale.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** The VPN profile, the user SCEP and
  trusted-root profiles, the Conditional Access policy, and the groups all follow
  `AOVPN – User Tunnel – …` / `PILOT – AOVPN User Tunnel Users` / `CA – AOVPN User Tunnel Access`. The
  discovery, validation, report, and remediation scripts find objects **by these names** — drift breaks
  automation and reporting.
- **One user tunnel, one profile.** Keep exactly one VPN profile for the user tunnel. Do not fork "test"
  copies in production; use assignment (pilot vs prod user group) to stage.
- **Keep pilot and production user groups separate and both assigned.** `PILOT – AOVPN User Tunnel Users`
  stays assigned after expansion so pilot members keep the tunnel and you retain a fast test cohort.

## User tunnel vs. device tunnel
- **Assign the user tunnel to USERS, not devices.** It is a per-user, post-sign-in tunnel authenticated by
  a **user** certificate — user-targeted assignment is what makes it behave correctly.
- **Run the device tunnel alongside it where you need pre-logon reachability** — that (and the full
  certificate lifecycle) is the **companion device-tunnel product**. The two coexist by design: device
  tunnel before sign-in, user tunnel after.

## Pilot-first, always
- **Never skip the pilot,** even for "simple" profile or policy changes. Every change to the VPN profile,
  the certificate profile, or the Conditional Access policy goes to `PILOT – AOVPN User Tunnel Users`
  first and passes the Testing gates before production.
- **Start Conditional Access in report-only.** Create `CA – AOVPN User Tunnel Access` **report-only**,
  review the Insights workbook, and only turn it **On** after T6 passes. Report-only is also your instant
  rollback.
- **Expand in waves.** For large fleets, add production sub-groups over several days and watch
  `AOVUT-Report.ps1` and the Entra sign-in logs between waves.

## Authentication and certificates (lean, cross-referenced)
- **Use a user certificate for silent auth.** Deliver it via `AOVPN – User Tunnel – User Cert (SCEP) –
  Windows` with the **Client Authentication** EKU, and ensure the **issuing CA is trusted by the VPN
  gateway** (head-end trust config per Microsoft docs).
- **Deploy the trusted root first,** then the user SCEP profile, then the VPN profile that references the
  cert — order matters so the cert exists and chains when the tunnel needs it.
- **Defer full PKI lifecycle to the companion device-tunnel product.** Issuing-CA design, NDES/Cloud PKI
  health, renewal thresholds, and revocation are handled there — here, keep the user-cert config minimal
  and correct.

## Trusted network detection and split tunnel
- **Set Trusted Network Detection to your corporate DNS suffix** so the tunnel suppresses on the corporate
  LAN and only comes up off-network — this avoids "tunnel inside the tunnel" and needless load.
- **Scope split-tunnel routes deliberately.** Route only the corporate ranges through the tunnel; full
  tunneling hurts performance and privacy unless a policy requires it.

## Conditional Access
- **Gate on device compliance, not just identity.** Pair **Require MFA** with **Require device to be
  marked as compliant** (or hybrid-joined) so an always-on tunnel is never always-open access.
- **Target specific cloud apps** the tunnel fronts — not "All cloud apps" — so the policy's blast radius
  is understood.
- **Always exclude break-glass accounts** from the policy so a misconfiguration can't lock everyone out.

## Change control and rollback
- **Keep a one-click rollback ready:** unassign the profiles from the group, and flip
  `CA – AOVPN User Tunnel Access` to **Report-only**. Test the rollback (Testing T9) before you ever need it.
- **Deploy inside a change window** and announce it — remote-access and sign-in changes affect real users.
- **Version your inputs.** Track which gateway FQDN, routes, SCEP settings, and CA grant a given rollout
  used, so you can reproduce or revert precisely.

## Operate and monitor
- **Run `AOVUT-Report.ps1` on a schedule** (e.g. weekly) to track coverage drift as users/devices come and
  go, and to catch profile *Error* states early.
- **Watch the Entra sign-in logs** for `CA – AOVPN User Tunnel Access` results after you enforce, to catch
  unexpected blocks quickly.
- **Remediate safely.** `AOVUT-Remediation.ps1` defaults to **-WhatIf** — always preview the planned
  actions, then re-run with `-WhatIf:$false`. Never let a remediation run act without a preview first.
- **Least-privilege admin.** Use Intune Administrator + Conditional Access Administrator + Groups
  Administrator for the operator; reserve Global Administrator for tenant-wide changes only.

## Security hygiene
- **Never store VPN credentials in the profile.** Use the user certificate for authentication — do not
  embed secrets.
- **Keep the compliance policy meaningful.** The Conditional Access device-compliance grant is only as
  strong as the compliance policy behind it (R8); keep its rules current.
