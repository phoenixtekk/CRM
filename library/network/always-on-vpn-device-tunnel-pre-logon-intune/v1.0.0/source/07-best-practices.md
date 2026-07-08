# Best Practices — Windows Always On VPN Device Tunnel (Pre-Logon) via Intune

Field-proven practices for the assign-once, repeat-everywhere model. These make the device-tunnel
deployment predictable, reversible, and safe to operate at scale — especially because it touches the
pre-logon boot path.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** The two certificate profiles, the
  Custom ProfileXML profile, the device groups, and the filter all follow
  `AOVPN – Device Tunnel – …` / `PILOT – AOVPN Device Tunnel – Devices`. The discovery, validation,
  report, and remediation scripts find objects **by these names** — drift breaks automation and
  reporting.
- **Keep the VPN profile name identical everywhere.** The VPNv2 profile name is `AOVPN Device Tunnel`
  in the OMA-URI path, inside the ProfileXML, and in every `Get-VpnConnection` check. A mismatch here
  produces a profile that looks deployed but can't be found by name.
- **One device-tunnel profile per device — only.** Windows allows **only one** device-tunnel profile.
  Never deploy two ProfileXML Custom profiles that both set `DeviceTunnel=true`; use assignment
  (pilot vs prod device group) to stage, not duplicate profiles.

## Device context, always
- **Assign the ProfileXML to a DEVICE group, never a user group.** The `./Device/` OMA-URI runs in
  SYSTEM/device context; a user-group assignment silently does nothing. This is the single most common
  device-tunnel mistake — make the device-group assignment a checklist item.
- **Use device groups for the certificate profiles too.** The machine certificate is a **Device**-type
  certificate in `LocalMachine\My`; target the same device groups so cert and ProfileXML land on the
  same machines.

## Pilot-first, always
- **Never skip the pilot,** even for a "small" ProfileXML change. Every change to the ProfileXML or the
  certificate policy goes to `PILOT – AOVPN Device Tunnel – Devices` first and passes the Testing gates
  — including the **pre-logon** test — before production.
- **Pilot with a first-logon device.** Include at least one device where a *brand-new* user with **no
  cached credential** logs on, to prove the whole point of the device tunnel actually works.
- **Expand in waves.** For large fleets, add production device sub-groups over several days and watch
  `AOVDT-Report.ps1` between waves rather than assigning everyone at once.

## Certificates and the lifecycle
- **Deploy the trusted root first, then SCEP, then the ProfileXML** — order matters so the machine
  certificate exists and chains correctly before the tunnel needs it.
- **Issue a Device certificate with Client Authentication EKU.** The device tunnel has no user at boot;
  a User-type certificate or a missing Client Authentication EKU will not authenticate.
- **Set a comfortable SCEP renewal threshold** (e.g. 20%) so certificates renew **before** expiry — a
  lapsed machine certificate silently kills the pre-logon tunnel. Watch cert profile status in the
  report.
- **Ensure the head-end trusts the issuing CA and presents a valid server certificate** (Server
  Authentication EKU, subject matching the gateway FQDN). This head-end trust config is deferred to
  Microsoft docs, but it is the other half of IKEv2 mutual auth — provide your network team the issuing
  CA chain.

## ProfileXML discipline
- **Keep the device tunnel minimal.** Carry only the routes the machine needs pre-logon (domain
  controllers, management/PKI subnets) — not a full tunnel. Over-broad routing hurts performance and is
  unnecessary for the device tunnel's job.
- **IKEv2 only — plan for it.** There is no SSTP fallback; ensure the IKEv2 ports/path to the gateway
  are reachable from the networks your devices boot on, or the device tunnel simply won't come up.
- **Version your ProfileXML.** Track which ProfileXML (gateway, routes, NRPT) and which certificate
  policy a rollout used, so you can reproduce or revert precisely.

## Change control and rollback
- **Keep a one-click rollback ready:** remove the device-group assignment, or push a Custom profile
  that removes the `AOVPN Device Tunnel` VPNv2 profile. Test the rollback (Testing T8) on a disposable
  device **before** you ever need it — this is a pre-logon path.
- **Deploy inside a change window** and announce it — a misbehaving device tunnel affects boot/logon
  for real users.

## Operate and monitor
- **Run `AOVDT-Report.ps1` on a schedule** (e.g. weekly) to track coverage drift as devices enroll and
  leave, and to catch profile *Error* / certificate-expiry states early.
- **Remediate safely.** `AOVDT-Remediation.ps1` defaults to **-WhatIf** — always preview the planned
  actions, then re-run with `-WhatIf:$false`. Never let a remediation run act without a preview first.
- **Least-privilege admin.** Use Intune Administrator + Groups Administrator for the operator; reserve
  Global Administrator for tenant-wide changes only.

## Security hygiene
- **No credentials in the profile.** The device tunnel authenticates with a machine certificate only —
  never embed secrets in the ProfileXML.
- **Protect the machine key.** Prefer TPM-backed key storage for the SCEP certificate so the device
  identity can't be trivially exported.
- **Scope routes deliberately.** Only tunnel the internal subnets the machine genuinely needs before
  logon; the user tunnel (a separate deployment) handles user-context traffic.
