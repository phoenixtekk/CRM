# Executive Summary — Windows Interactive Logon & Network-Access Security Options Hardening (Intune)

A security assessment of a Windows fleet always leaves a short list of **Security Options and logon
policies** that no other hardening product owns — the settings that sit *between* the well-known
workstreams. The NTLM/SMB, RDP, and credential-theft products each carry their own findings; what is
left over are the **interactive-logon behaviors** and the **network-access controls at the logon
screen** that quietly widen the attack surface: a machine that will happily join an untrusted network
while on the corporate LAN, a smart card that can be pulled without locking the session, an automatic
sign-in that re-establishes the last user after an update reboot, and a network-selection UI exposed
before anyone has authenticated. This solution is the **hardening pack that closes exactly those
leftover findings** using **Microsoft Intune Settings Catalog** — no Group Policy, no imaging.

**A deliberately scoped, gap-only capability.** This package hardens **four** specific Windows
policies and nothing else:

- **Prohibit connection to non-domain networks when connected to a domain-authenticated network** —
  stops a bridged/dual-homed path off the trusted network (Windows Connection Manager,
  `fBlockNonDomain = 1`).
- **Interactive logon: Smart card removal behavior = Lock Workstation** — pulling the card locks the
  session instead of leaving it open (`scremoveoption = 1`).
- **Disable "Sign-in and lock last interactive user automatically after a restart"** — no automatic
  re-establishment of the last user's session after an update reboot (`DisableAutomaticRestartSignOn = 1`).
- **Do not display network selection UI** — hides the network-picker on the sign-in screen so an
  unauthenticated user cannot change connectivity (`DontDisplayNetworkSelectionUI = 1`).

It does **not** re-do the work owned by the NTLM/SMB hardening, RDP hardening, or credential-theft /
LSA-protection products — it complements them and complements a CIS/STIG baseline. It resolves roughly
**four** Windows Client assessment findings that those products leave behind.

**Honest about user impact.** Disabling automatic restart sign-on means that after a Windows Update
reboot, the last interactive user is **not** silently signed back in and locked — the user must log in
again. That is the intended, more-secure behavior; this package calls it out so you can set the
expectation before rollout rather than field surprised tickets.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** A single named **Settings Catalog** profile —
  **`Interactive Logon & Network-Access Hardening - Pilot`** — carrying the four settings, deployed
  pilot-first and fully reversible by unassigning it.
- **Verify-don't-invent.** Every exact CSP/Settings-Catalog path and value is given, and the ones that
  Microsoft renames between releases are flagged **verify in your tenant** rather than assumed.
- **Pilot-first, reversible.** The standard shape — **Assess → Configure → Pilot → Validate →
  Expand** — with explicit pass/fail gates, a negative test that nothing else changed, and five
  ready-to-run PowerShell scripts (Microsoft Graph; discovery/validation/reporting are read-only,
  remediation and targeting default to a safe preview).

**Outcome:** the leftover interactive-logon and network-access Security-Options findings closed across
the Windows fleet — hardened, proven on a pilot before you scale, without a consulting engagement and
without touching how the devices are enrolled or imaged.
