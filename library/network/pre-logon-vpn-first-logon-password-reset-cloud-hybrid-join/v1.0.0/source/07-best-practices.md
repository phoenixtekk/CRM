# Best Practices — Pre-Logon VPN: First-Logon & Off-Network Password Reset

Field-proven practices for the decision + scenario + validation layer. These keep the pre-logon
decision defensible, the scenarios reliable, and the fleet free of unnecessary tunnels.

## Decide by join type first
- **Start from the join-type inventory, always.** Run `PREVPN-Discovery.ps1` before deciding anything.
  The first-logon / DC-reachability problem is a **hybrid/domain-joined** problem; deciding without the
  join-type mix leads to over-deploying to cloud-only devices.
- **Never deploy a pre-logon tunnel to Entra-joined (cloud-only) devices.** They authenticate against
  Entra in the cloud; a first sign-in and password change work without an on-prem DC. Use SSPR/TAP for
  their cloud password paths instead.
- **Let the matrix pick the approach, and record why.** Device tunnel for the Enterprise/Education +
  machine-cert + IKEv2 cohort (silent, no user action); SBL/PLAP where you already run Cisco Secure
  Client or can't meet that bar (user-initiated at the logon screen). Write the decision down.

## Keep the three surfaces coherent
- **Reference the companion objects by their exact names.** `AOVPN – Device Tunnel – ProfileXML –
  Windows` and `Cisco Secure Client – Pre-Logon (SBL) – Win32` are created in the companion products —
  never rename or fork them here; this product only decides and validates.
- **Don't rebuild the tunnel in this layer.** If you find yourself editing a ProfileXML or the SBL
  module, you're in the wrong product — do that work in the companion product so the build stays in one
  place.
- **Segment cohorts cleanly.** Use `PILOT – Pre-Logon First-Logon Users` and `PROD – Pre-Logon
  First-Logon Users` to stage validation and expansion; keep the pilot group assigned after expansion
  as a fast test cohort.

## Validate the scenarios, not just the plumbing
- **Always run T1 and T2 end to end on the pilot.** A tunnel that "exists" is not proof — prove that a
  **never-logged-on** user completes first logon off-network and that an **expired-password** user can
  change it at the lock screen. These two tests are the whole point.
- **Include an Entra-joined control in the pilot.** Confirm it signs in with **no** pre-logon path — it
  is your evidence that cloud-only devices don't need this deployment.
- **Confirm DC reachability separately.** The tunnel coming up and a DC being reachable through it are
  two different things — validate both (T3 and T4).

## Certificates and SKU (device tunnel)
- **Verify the machine cert and SKU before promising a silent tunnel.** The device tunnel is silent
  only when a valid **LocalMachine\My** machine certificate exists and the device is
  **Enterprise/Education**. Confirm both (T5/R6) or route those devices to SBL/PLAP.
- **Watch machine-cert lifetime.** A lapsed machine cert silently breaks the pre-logon tunnel — monitor
  renewal in the companion product so devices never lose the DC path at logon.

## SSPR is a complement, not a replacement
- **Enable SSPR/TAP for the cloud-capable paths**, but do not assume they remove the DC-path
  requirement for a **hybrid/domain-joined** device's lock-screen password change. Document exactly
  where SSPR helps (Entra-joined; directory reset via writeback) and where the DC path is still needed.

## Break-glass, always ready
- **Keep a documented fallback for every stranded-user case:** local administrator recovery, a
  **Temporary Access Pass** for cloud-capable first sign-in, and a "bring it on-network once" path.
  Test the fallback (T8) before you need it.
- **Onboard the very first device on a known network when in doubt.** For a brand-new hire, a single
  first logon on a trusted network primes the cached credential and removes the off-network first-logon
  risk entirely — a pragmatic fallback when pre-logon VPN isn't ready.

## Operate and monitor
- **Run `PREVPN-Report.ps1` on a schedule** to track pre-logon coverage of in-scope devices as the
  fleet changes, and to catch cloud-only devices that were targeted by mistake.
- **Remediate safely.** `PREVPN-Remediation.ps1` defaults to **-WhatIf** and only adjusts **group
  membership** for the chosen approach — it never creates VPN profiles. Preview first, then re-run with
  `-WhatIf:$false`.
- **Least-privilege admin.** Groups Administrator + Intune Administrator for the operator; reserve
  Global Administrator for tenant-wide changes only.
