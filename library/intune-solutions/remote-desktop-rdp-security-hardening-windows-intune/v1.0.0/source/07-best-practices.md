# 7. Best Practices — Remote Desktop (RDP) Security Hardening

These practices keep the endpoint RDP hardening precise, predictable, and reversible on managed
Windows 10/11 devices. They assume the deployment model in the Solution Overview: one named Settings
Catalog profile (**`RDP Hardening - Pilot`**) built from Administrative Templates settings, deployed via
Intune, pilot-first.

## Pilot the breaking change first
- **High encryption is the one setting that can break access.** `MinEncryptionLevel = 3` refuses
  sub-128-bit clients. Always run the **legacy-client test** (Testing, Test 5) on a piloted host before
  widening, and keep a list of any clients that must be upgraded.
- **Assign to a pilot device group, never "All devices" first.** Expand in waves only after each gate
  passes, and re-check legacy-client impact for each new population.

## One profile, one owner per setting
- **Keep all five findings plus NLA in the single `RDP Hardening - Pilot` profile** so the RDP posture
  is in one place, named, and easy to audit — every test and troubleshooting step refers back to it.
- **Avoid double-setting.** If a CIS or STIG baseline already sets an RDP value, decide which policy
  **owns** it and remove it from the other — two sources setting the same value is the most common
  "Conflict" in Device status.
- **Record each setting's registry anchor.** Keep a short table (setting → value → registry value name)
  so the next admin can verify on the device without guessing.

## Verify on the device, not just in the portal
- **Trust the registry, confirm the labels.** The Settings Catalog category wording can change; the
  registry anchors (`MinEncryptionLevel`, `fPromptForPassword`, `fDisableCdm`, `DisablePasswordSaving`,
  `fAllowToGetHelp`, `UserAuthentication`) do not. Verify the values on a pilot device as the definitive
  proof it applied.
- **Test a live RDP session,** not only Device status = Succeeded. Password prompt, no drive
  redirection, no saved password, and NLA are only truly proven from a real connection (Test 4).

## Harden host and client in the right place
- **Host-side settings on hosts; client-side on clients.** The RDSH settings (encryption, prompt,
  redirection, NLA) matter on machines that **accept** RDP; `DisablePasswordSaving` matters on machines
  that **initiate** it. Scope so each population actually receives the settings that apply to it (R4).
- **If a device never needs to host RDP, disable RDP there** rather than merely hardening it — a
  disabled listener is a smaller surface than a hardened one.

## Close Remote Assistance deliberately
- **Disable both Solicited and Offer Remote Assistance** unless you have a specific, controlled support
  workflow that needs it. If you keep it for a helpdesk, scope it narrowly and document the exception.

## Treat credential and network layers as adjacent projects
- **Restricted Admin / Remote Credential Guard is the credential-theft solution's job.** Cross-reference
  it, pilot it separately (it changes single-sign-on to the remote host), and don't fold it into this
  profile by default.
- **Pair with network controls.** Endpoint hardening complements — never replaces — RD Gateway,
  firewall/NSG rules, VPN, and JIT VM access. State this to stakeholders so "RDP is hardened" isn't
  mistaken for "RDP is off the internet."

## Operate and monitor
- **Report before you widen.** Run `RDPHARD-Report.ps1` each wave; only broaden when coverage matches
  the assigned group.
- **Remediate with `-WhatIf` first.** `RDPHARD-Remediation.ps1` and `RDPHARD-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply with `-WhatIf:$false`.
- **Rollback is unassignment.** Because this only adds a configuration profile, removing the assignment
  cleanly reverts behavior (Test 8) — no enrollment or image cleanup needed. Keep the profile so you can
  re-target quickly.

## Change control
- **Version scope changes.** When you add a setting, change the encryption level, or adjust the assigned
  group, note the date and reason; re-run Discovery and Report to confirm no regressions.
- **Review after Windows feature updates and baseline changes.** Confirm the RDP settings still apply and
  that a newly imported CIS/STIG baseline hasn't started competing for the same values before expanding.
