# Sales Content — iOS iPhone Entra ID Shared Device Mode (Frontline SSO)

## Hook
**Shared iPhones your frontline can share safely.** Configure Entra ID Shared Device Mode via Intune —
each worker signs in once as themselves, and single sign-out clears their identity and data for the
next person, across Teams and MSAL apps.

## The problem
A pool of shift iPhones with one shared account — or a kiosk lockdown — leaves the previous worker's
mail, chats, and tokens on the device for the next person. Lockdown limits *which* app runs; it does
not give anyone a private session. And Apple's own Shared iPad only works on iPad hardware, so an
iPhone fleet has no OS-level multi-user mode to fall back on. **Entra ID Shared Device Mode is the
Microsoft-native way to give pooled iPhones a real per-user sign-in/sign-out experience.**

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — exact, ordered Intune/Entra steps with full navigation paths; every group, ADE
  profile, and app is named and reused through testing and troubleshooting.
- **Cheaper** — one fixed price, not an open consulting meter; reusable across every site and shift.
- **Tested** — pilot-first (**Assess → Configure → Pilot → Validate → Expand**), with an unambiguous
  acceptance gate: user A signs out, user B signs in **clean**, with no trace of A.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete click-by-click guide, honest about what SDM isolates (the Entra session + SDM-aware app
  data, not the whole OS) and about narrower iOS app coverage (anchor on Teams; verify LOB apps).
- **The detail teams miss** — the **Assigned** device group must be **owned by the Intune Provisioning
  Client** or no-affinity devices never populate it at enrollment. The guide and the remediation script
  handle it.
- **5 PowerShell scripts (Microsoft Graph)** — Discovery, Validation, Report (read-only), plus
  Remediation and Set-ScopeTargeting (default to `-WhatIf` preview).

## The repeatable way
Every solution follows the same repeatable shape, so each deployment feels familiar and low-risk — buy
once, reuse the playbook for the next site and the next shift.

## The bottom line
Pooled iPhones your frontline can share safely — each worker signed in as themselves, each sign-out a
clean hand-off — deployed and proven on a pilot before you scale, without a consulting engagement.

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
