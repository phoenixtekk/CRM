# 7. Best Practices — Android Enterprise App Management via Managed Google Play (Intune)

## Catalog governance
- **Approve deliberately, not broadly.** Every approved app is visible in the managed work Play Store —
  approve only what you deliver, identified by **exact package name + publisher**, and keep an owned list.
- **Set permission-change handling on purpose.** Choose how an app behaves when it requests **new
  permissions** on update (keep-approved vs re-review). Re-review is safer for sensitive apps; keep-approved
  avoids apps silently dropping out of the catalog — decide per app and record it.
- **Prefer store apps; use private LOB only when you must.** Private publishing adds a Google-side
  developer-account dependency and a slower change loop — reserve it for genuinely internal apps.

## Assignment discipline
- **The `assign` action replaces ALL assignments.** Never hand-edit assignments blind — read the current
  set first (`ANDROIDAPP-Discovery.ps1` / `-WhatIf`), then write the **complete** intended set. This is
  the #1 way teams accidentally drop a group.
- **Match intent to enrollment model.** Required for fully managed / corporate-owned work profile /
  dedicated; Available for work-profile BYOD. Don't push Required to BYOD unless that is truly intended.
- **Assigned groups, not Dynamic, for app targeting** — predictable membership avoids apps appearing on
  the wrong devices as dynamic rules churn.

## Managed configuration
- **Pre-configure everything you can.** Push accounts, server URLs, and feature flags via app-config
  policies so users get a zero-touch first run — fewer setup tickets, consistent config.
- **Pick the right profile applicability.** Author separate app-config policies for personally-owned
  work profile vs fully managed/dedicated/corporate-owned — the available keys and behavior differ.
- **OEMConfig is the sanctioned OEM path.** Drive Samsung Knox / Zebra settings through their OEMConfig
  app's schema rather than ad-hoc device settings; treat the schema/keys as vendor-authoritative.

## App protection (APP / MAM)
- **Layer APP on top of device policy** for managed devices, and use **MAM-only** APP as the primary
  control on unenrolled / work-profile BYOD where you don't manage the whole device.
- **Standardize a baseline APP policy** (PIN, encryption, block copy/paste + save-as to personal,
  conditional launch on min OS/patch) and reuse it, rather than bespoke policies per app.

## Update-track control
- **Pilot updates on a Beta / closed track** to a small group before the fleet moves. Keep Production
  on the stable track. Set **auto-update mode** intentionally (e.g. high priority for security-critical
  apps).
- **Don't let tracks drift.** Re-run `ANDROIDAPP-Discovery.ps1` periodically to confirm each app is on
  the intended track and mode.

## Change safety
- **Pilot-first, always** — prove the four gates on a device per model before expanding.
- **High-impact = separate change window.** Connector re-binding, enrollment-model changes, and the
  **AMAPI** migration can affect existing devices and may involve **re-enrollment** — **verify against
  current Microsoft guidance / your tenant**; never bundle them with routine app changes.
- **Keep a rollback ready** — the current assignment set (from `-WhatIf`) is your restore point; unassign
  / revert config / revert track to recover.
- **Least privilege** — do routine app work as **Intune Administrator**; reserve Global Admin for the
  initial managed Google Play binding.

## Hygiene
- **No secrets in automation.** Scripts authenticate interactively via `Connect-MgGraph` with least
  scopes — never embed credentials, tokens, or app secrets.
- **Document per app:** type, package name, intent per group, managed config keys, APP policy, and track.
