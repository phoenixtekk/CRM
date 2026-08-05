# Sales Content — Windows Interactive Logon & Network-Access Security Options Hardening (Intune)

## Hook
**Close the Security-Options findings no other product owns.** Harden the four leftover
interactive-logon and network-access controls on Windows 10/11 through one Intune Settings Catalog
profile — the gap-only pack that catches what your NTLM/SMB, RDP, and credential-theft products leave
behind.

## The problem
Every Windows fleet assessment ends with a short tail of **Security Options and logon findings** that
none of the big hardening workstreams own: a machine that will bridge to an untrusted network while on
the corporate LAN, a smart card that can be pulled without locking the session, an automatic sign-in
that re-establishes the last user after an update reboot, and a network picker exposed at the sign-in
screen before anyone has authenticated. They are easy to miss because they sit *between* the
NTLM/SMB, RDP, and credential-theft products — and a CIS/STIG baseline flags them but doesn't always
deploy them.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — exact, ordered Intune Settings Catalog steps with full navigation paths; the one
  profile you create is named and reused through testing and troubleshooting.
- **Cheaper** — one fixed price, not an open consulting meter; reusable on every wave and every new
  device fleet.
- **Tested** — a pilot-first method (**Assess → Configure → Pilot → Validate → Expand**) with explicit
  pass/fail gates, registry spot-checks, and read-only validation scripts.

## The four controls
- **Prohibit connection to non-domain networks** while on a domain-authenticated network
  (`fBlockNonDomain = 1`).
- **Smart card removal behavior = Lock Workstation** (`scremoveoption = 1`).
- **Disable automatic restart sign-on** — no silent re-sign-in after an update reboot
  (`DisableAutomaticRestartSignOn = 1`).
- **Do not display network selection UI** — no network picker at sign-in
  (`DontDisplayNetworkSelectionUI = 1`).

## Honest about user impact
Disabling automatic restart sign-on means users **sign in again after an update reboot** — the
intended, more-secure behavior. The guide gives you the one-line notice to set that expectation before
rollout, so it isn't mistaken for a fault.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete click-by-click guide, gap-only and explicit about how it complements NTLM/SMB, RDP,
  credential-theft, and CIS/STIG baselines.
- **5 PowerShell scripts (Microsoft Graph)** — Discovery, Validation, Report (read-only), plus
  Remediation and Set-ScopeTargeting (default to `-WhatIf` preview).

## The repeatable way
Every solution follows the same repeatable shape, so each deployment feels familiar and low-risk — buy
once, reuse the playbook for the next wave and the next project.

## The bottom line
The leftover interactive-logon and network-access Security-Options findings closed across the Windows
fleet — hardened and proven on a pilot before you scale, without a consulting engagement and without
touching how the devices are enrolled or imaged.

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
