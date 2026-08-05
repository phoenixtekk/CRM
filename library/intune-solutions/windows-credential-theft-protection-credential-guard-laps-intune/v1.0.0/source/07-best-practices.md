# 7. Best Practices — Windows Credential Theft Protection

These practices keep the credential-theft defense precise, safe, and reversible on corporate Windows
10/11 endpoints. They assume the deployment model in the Solution Overview: six named Intune profiles
deployed via **Assess → Configure → Pilot → Validate → Expand**, VBS controls on capable hardware,
audit-first.

## Assess hardware before you enable VBS
- **Readiness-gate Credential Guard and LSASS PPL.** Run `CREDGUARD-Discovery.ps1 -LocalReadiness` and
  target only **TPM 2.0 / UEFI / Secure Boot / virtualization-capable** devices. Assigning VBS controls
  to unsupported hardware just generates errors.
- **Build a capable-device group.** Keep `Credential Guard - Pilot` and `LSASS Protection (RunAsPPL) -
  Pilot` scoped to that group; let the low-risk controls (WDigest, WinRM, Remote Credential Guard) and
  LAPS go broader.

## Roll out lock mode deliberately
- **Pilot without the UEFI lock; enforce with it.** Use **Enabled without lock** while proving
  compatibility (easy rollback by unassigning), then **Enabled with UEFI lock** for production so malware
  cannot silently disable VBS.
- **Plan the sticky rollback up front.** Document that UEFI-locked VBS is removed by the documented
  procedure (often console/physical access), not a profile unassign — set that expectation with change
  management before the production wave.

## Audit LSASS protection first — always
- **Never flip RunAsPPL fleet-wide blind.** Deploy audit-first, watch **CodeIntegrity/LSA operational**
  logs for would-block events (e.g. 3065/3066), remediate the named plug-in/driver, *then* enforce. This
  is the single biggest way to avoid a broken-SmartCard/EDR incident.

## Keep the low-risk controls simple and enforced
- **WDigest and WinRM are cheap wins.** Modern Windows often already sets `UseLogonCredential = 0`, but
  **enforce and prove it** so an audit finding is closed with evidence. Same for WinRM `DisableRunAs = 1`.
- **Restrict credential delegation on the client, harden the host separately.** This package owns the
  **outbound** Remote Credential Guard setting; pair it with the **RDP hardening** solution for the
  host-side (`AllowProtectedCreds`, Restricted Admin, NLA). Don't duplicate the host settings here.

## Operate Windows LAPS well
- **Use built-in Windows LAPS, not the legacy MSI**, and back up to **Entra ID only** unless you have a
  hybrid requirement. Set a sane rotation (e.g. 30 days), strong length/complexity, and a post-auth reset.
- **Lock down retrieval.** Grant `deviceLocalCredentials/password/read` narrowly and log who retrieves;
  the password is only as safe as the read permission.
- **Manage a named admin account where possible** rather than the built-in Administrator, so LAPS
  rotation is unambiguous.

## Deploy pilot-first and reversibly
- **Assign to `Credential Protection - Pilot`, never "All devices" first.** Expand in waves after each
  gate passes.
- **One control at a time when debugging.** Because each control is its own named profile, you can
  unassign or narrow exactly the one that misbehaves without touching the others.

## Operate and monitor
- **Report before you widen.** Run `CREDGUARD-Report.ps1` each wave; only broaden when coverage and
  runtime state match the assigned group.
- **Remediate with `-WhatIf` first.** `CREDGUARD-Remediation.ps1` and `CREDGUARD-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Watch the runtime state, not just policy status.** A profile can show "Succeeded" while Credential
  Guard isn't *running* on incapable hardware — validate `Win32_DeviceGuard` and the registry values.

## Change control
- **Version scope changes.** When you flip a lock mode, add a device group, or change a LAPS parameter,
  note the date and reason; re-run Discovery and Report to confirm no regressions.
- **Review after major Windows upgrades.** Confirm Credential Guard still runs, LSASS is still protected,
  and LAPS still backs up after significant feature updates before expanding further.
