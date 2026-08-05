# 7. Best Practices — Microsoft Edge for Business Enterprise Configuration & Security Baseline

These practices keep the managed Edge configuration precise, predictable, and reversible on corporate
Windows devices. They assume the deployment model in the Solution Overview: a named Settings Catalog
baseline (`Edge for Business - Baseline - Pilot`), a default-browser associations profile
(`Edge for Business - Default Browser - Pilot`), and the Microsoft Edge security baseline
(`Edge for Business - Security Baseline - Pilot`), deployed via Intune, pilot-first.

## Resolve Settings Catalog ↔ security baseline conflicts deliberately
- **Decide who owns each overlapping setting.** SmartScreen, extension controls, and password-manager
  settings can be set by *both* the Settings Catalog baseline and the Microsoft Edge security baseline. If
  both set the same policy to **different** values, the device reports a **conflict** and the setting may
  not apply. Choose one owner per setting and make the other agree (or leave it unset there).
- **Prefer the security baseline for the hardening floor, the Settings Catalog for org specifics.** Let
  the Edge security baseline carry Microsoft's recommended hardening; use `Edge for Business - Baseline -
  Pilot` for organization-specific choices (startup pages, IE mode, extension allow-list, update channel).
- **Document the ownership map.** Keep a short table of "setting → which object sets it → value" so the
  next admin does not reintroduce a conflict.

## Password manager: pair the "off" with an alternative
- **Never disable the browser password manager without the enterprise solution in place** (R3). Turning off
  `PasswordManagerEnabled` is only half the change; users need somewhere sanctioned to store credentials, or
  you generate tickets and shadow IT.
- **Communicate before you enforce.** A one-line notice ("Edge will no longer save passwords; use
  <enterprise vault>") prevents most confusion.

## Extension control: block-all, then allow
- **Start from `ExtensionInstallBlocklist = *` and allow-list explicitly.** A block-everything default with a
  short `ExtensionInstallAllowlist` is far safer than trying to enumerate bad extensions. Add
  `BlockExternalExtensions = Enabled` to stop out-of-store sideloading.
- **Record every allow-listed extension ID** (extension → ID → why approved) so the list stays auditable.
- **Use `ExtensionInstallForcelist` sparingly** — only for extensions the org genuinely wants everywhere.

## Default browser: enforce, but set expectations
- **Enforce with `DefaultAssociationsConfiguration`**, and know it is a **fleet default** applied at policy
  refresh, not a per-click lock. Communicate the change and keep the associations XML minimal (browser/HTML
  types only) so you do not accidentally reassign unrelated file types.
- **Rebuild the XML from a clean reference device** whenever Windows/Edge progIDs change across major
  releases, and re-deploy.

## IE mode: keep the site list short, current, and reachable
- **List only what genuinely needs IE**, with `Open in = IE11`. Every site you add is a legacy dependency
  you are choosing to keep alive — treat the list as a retirement backlog, not a dumping ground.
- **Host the site list reliably** (R9) and monitor that the URL stays reachable; an unreachable list
  silently disables IE mode.
- **Version the site list.** The policy points at a stable URL; change the file behind it and note the date
  and reason for each addition/removal.

## Sync & work-profile sign-in
- **Choose your sign-in posture explicitly.** `BrowserSignin = Force` gives a governed work profile and is
  the cleanest for Conditional Access; `Enable` leaves it optional. Decide once and apply consistently.
- **Be intentional about sync.** `SyncDisabled = Enabled` stops consumer sync of browser data; if you use
  Edge enterprise sync, leave it unmanaged and govern via profile instead. Do not half-configure both.

## Update channel & cadence
- **Pin the fleet to a supported channel (usually Stable)** with the Microsoft Edge Update policies, and set
  a predictable auto-update cadence so security fixes land without manual effort. Review after major Edge
  releases.

## Deploy pilot-first and reversibly
- **Assign every object to `Edge for Business - Pilot Devices`, never "All devices" first.** Expand in waves
  after each gate passes.
- **Rollback is unassignment.** Because these are Intune profiles/baselines, removing the assignment reverts
  behavior; keep the objects so you can re-target quickly.

## Operate and monitor
- **Report before you widen.** Run `EDGEBIZ-Report.ps1` each wave; only broaden when coverage matches the
  assigned group.
- **Remediate with `-WhatIf` first.** `EDGEBIZ-Remediation.ps1` and `EDGEBIZ-Set-ScopeTargeting.ps1` preview
  by default — read the plan, then apply.
- **Verify policy on the device with `edge://policy`.** It is the fastest ground truth for what actually
  applied, independent of Intune's reporting lag.

## Change control
- **Version the security baseline migration.** Microsoft periodically releases new **Edge security baseline
  versions** — review the diff and migrate `Edge for Business - Security Baseline - Pilot` deliberately
  rather than auto-adopting.
- **Confirm policy names after Edge upgrades.** Edge adds/renames policies frequently. After a major Edge
  release, re-run Discovery and spot-check `edge://policy` before expanding.
