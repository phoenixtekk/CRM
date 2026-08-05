# Sales Content — Remote Desktop (RDP) Security Hardening for Windows Endpoints (Intune)

## Hook
**Stop RDP being the door left ajar on every Windows endpoint.** Close the Remote Desktop settings that
vulnerability assessments flag on nearly every Windows client — with one named Intune Settings Catalog
profile, deployed pilot-first and fully reversible.

## The problem
Remote Desktop is enabled far more widely than most teams realize, and Windows ships it with permissive
defaults: connection encryption negotiable down to weak levels, no forced password prompt, local drives
redirected into the session, passwords savable in the client, and Solicited Remote Assistance left on.
Individually minor; together they are the classic "RDP is wide open" cluster — a favorite path for
lateral movement and credential exposure — and they resurface on assessment after assessment because no
one owns the fix.

## Resolves ~5 recurring assessment findings — in one profile
- **Client connection encryption level = High (128-bit)** — `MinEncryptionLevel = 3`.
- **Always prompt for password upon connection** — `fPromptForPassword = 1`.
- **Do not allow drive redirection** — `fDisableCdm = 1`.
- **Do not allow passwords to be saved** — `DisablePasswordSaving = 1`.
- **Solicited Remote Assistance = Disabled** — `fAllowToGetHelp = 0` (Offer Remote Assistance disabled too).

Plus defense-in-depth: **require Network Level Authentication** (`UserAuthentication = 1`), a pointer to
**Restricted Admin / Remote Credential Guard** for outbound RDP (cross-referenced to the credential-theft
hardening solution), and guidance to **limit who can log on via RDP**. It complements CIS and DISA STIG
baselines as a focused, explainable overlay.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — exact, ordered Intune steps with full navigation paths; the profile you create is named
  `RDP Hardening - Pilot` and reused through testing and troubleshooting, with every setting mapped to a
  registry value you can verify on the device.
- **Cheaper** — one fixed price, not an open consulting meter; reusable on every wave and every new fleet.
- **Tested** — a pilot-first method (**Assess → Configure → Pilot → Validate → Expand**) with explicit
  pass/fail gates, including the one breaking change (High encryption refuses legacy sub-128-bit clients)
  caught in the pilot, not in production.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete click-by-click guide, honest about the breaking change and the endpoint-vs-network / credential
  scope boundaries.
- **5 PowerShell scripts (Microsoft Graph)** — Discovery, Validation, Report (read-only), plus Remediation
  and Set-ScopeTargeting (default to `-WhatIf` preview).

## The repeatable way
Every solution follows the same repeatable shape, so each deployment feels familiar and low-risk — buy
once, reuse the playbook for the next wave and the next project.

## The bottom line
Every managed Windows endpoint enforces hardened RDP — strong encryption, forced password prompts, no
drive redirection, no saved passwords, and Remote Assistance closed — proven on a pilot before you scale,
without a consulting engagement.

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
