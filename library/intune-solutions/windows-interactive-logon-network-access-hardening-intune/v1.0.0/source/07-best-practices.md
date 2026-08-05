# 7. Best Practices — Windows Interactive Logon & Network-Access Security Options Hardening

These practices keep the hardening pack precise, predictable, and reversible on enrolled Windows 10/11
devices. They assume the deployment model in the Solution Overview: a single named **Settings Catalog**
profile carrying the four interactive-logon and network-access controls, deployed via Intune,
pilot-first.

## Own each setting once
- **This pack is gap-only — don't co-own settings.** Before deploying, confirm your NTLM/SMB, RDP,
  credential-theft, and CIS/STIG baselines do **not** already set any of these four. Two profiles that
  set the same policy differently produce a **conflict** ("Error" in Device status).
- **One profile per concern.** Keep these four in the single named profile
  **`Interactive Logon & Network-Access Hardening - Pilot`** so the owner of each Security-Options
  finding is obvious. If a baseline must own one of the four, remove it here.

## Communicate the user-visible changes before you enable them
- **Automatic restart sign-on off = re-login after updates.** Send the one-line notice from
  Requirements R6 to the pilot group and again before each expansion wave. This single behavior drives
  most of the "is it broken?" tickets — pre-empt it.
- **Smart-card removal locks the screen.** On card sites, remind users to keep the card in while
  working; the lock-on-removal is the intended protection.
- **No network picker at sign-in.** If users occasionally need to pick Wi-Fi before logging in,
  pre-provision the corporate Wi-Fi with a separate Wi-Fi profile so hiding the picker doesn't strand
  them.

## Scope narrowly, then widen
- **Assign to `SEC - Interactive Logon Hardening Pilot`, never "All devices" first.** Expand in waves
  after each gate passes.
- **Rollback is unassignment.** Because this only adds a configuration profile, removing the
  assignment reverts the four settings — no imaging or account cleanup. Keep the profile so you can
  re-target quickly.

## Get the values right, and verify them
- **Use the intended values exactly:** Windows Connection Manager block **Enabled** (`fBlockNonDomain =
  1`); smart-card removal **Lock Workstation** (`scremoveoption = 1`); automatic restart sign-on GPO
  **Disabled** (`DisableAutomaticRestartSignOn = 1`); do not display network selection UI **Enabled**
  (`DontDisplayNetworkSelectionUI = 1`).
- **Verify catalog labels and CSP names in your tenant.** Microsoft renames Settings Catalog display
  strings and occasionally the `settingDefinitionId` values; confirm current names before a wide
  rollout, and update the scripts' identifiers to match if they have drifted.
- **Mind the "Disabled means on" inversion.** Control #3 is the one that trips people up: you set the
  ADMX policy to **Disabled** to *disable* automatic restart sign-on. Double-check this one on the
  pilot with the registry spot-check (Testing, Test 4).

## Operate and monitor
- **Report before you widen.** Run `WINSECOPT-Report.ps1` each wave; only broaden when coverage matches
  the assigned group.
- **Remediate with `-WhatIf` first.** `WINSECOPT-Remediation.ps1` and
  `WINSECOPT-Set-ScopeTargeting.ps1` preview by default — read the plan, then apply with
  `-WhatIf:$false`.
- **Re-check ownership after baseline changes.** Whenever you update a security baseline, re-run
  Discovery to confirm the baseline hasn't started to co-own one of these four settings.

## Change control
- **Version scope changes.** When you adjust a value or the assignment, note the date and reason;
  re-run Discovery and Report to confirm no regressions.
- **Review after major Windows upgrades.** Confirm the four settings still apply and the registry paths
  still match after significant Windows feature updates before expanding further.
