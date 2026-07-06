# 7. Best Practices — macOS App Deployment & Apple VPP with Microsoft Intune

Field-proven guidance to keep the deployment reliable, correctly licensed, and low-maintenance.

## Licensing model
- **Default to device licensing** for company-owned Macs. It installs silently, needs **no Apple ID
  or App Store sign-in**, and reclaims the license automatically when a device retires.
- **Reserve user licensing** for the rare app that genuinely requires it. Budget for the extra
  friction: users must be **invited**, **accept VPP terms**, and sign in to the App Store.
- **Right-size license counts.** Track **consumed vs. total** per app (`MACVPP-Report.ps1`) and keep
  headroom so a rollout wave never stalls **out of licenses**. Buy more in ABM under **Location A**
  before you expand, then **Sync**.
- **Reclaim on retire/unassign.** Device licenses return to the pool automatically; verify reclamation
  after large retirements so counts stay accurate.

## Token & license-sync lifecycle (the #1 cause of outages)
- **The VPP token expires annually and a lapse stops sync and new installs.** Treat renewal as a
  scheduled task, not a surprise.
- **Renew with the same managed Apple ID** that owns the token, for the **same location**. Document
  that Apple ID and the location in your runbook (Requirements R4).
- **Schedule `MACVPP-Discovery.ps1`** to run regularly and alert on a token within 30 days of expiry
  or a stale last-sync time.
- **Keep one token per location, clearly named** (`VPP – Corporate (Location A)`) so licenses and
  renewals are unambiguous. Acquire all apps you deploy under that one location.

## App type selection
- **App Store → VPP.** If it's on the App Store, deploy it as a **VPP (App Store)** app so licensing is
  tracked and installs are silent.
- **Own/vendor app with a signed `.pkg`/`.dmg` → managed LOB/DMG.** Get managed install, update, and
  reporting.
- **Only fall back to unmanaged PKG** when the managed types can't run the installer (scripts, files
  outside `/Applications`). Accept that it's install-once with no license/uninstall management.
- **Always sign (and notarize where required)** enterprise packages so Gatekeeper doesn't block them.

## Assignment & targeting hygiene
- **Pilot first, expand in waves.** Assign to **`PILOT – macOS App Deployment`**, validate, then widen
  with `MACVPP-Set-ScopeTargeting.ps1` (preview with `-WhatIf` before applying).
- **Prefer Required for hands-off delivery**; use **Available** (Company Portal) for opt-in apps.
- **Assign to device groups** for device-licensed VPP apps so licensing and targeting align.
- **Name and reuse objects** — the token, the pilot group, and each app — rather than creating
  duplicates per wave.

## Updates & versioning
- **Let store apps update automatically**; confirm managed Macs advance to new App Store versions.
- **For LOB, always bump version/build** on the new `.pkg` so Intune recognizes it as an update.
- **Test a new LOB package on the pilot** before broad release, exactly as you did the first install.

## Operations & documentation
- **Keep a runbook** of the managed Apple ID, ABM location, token name, token expiry date, and the app
  inventory (type + licensing model) — the values that, if lost, are painful to recover.
- **Report monthly** with `MACVPP-Report.ps1`: apps deployed, install coverage, and VPP
  consumed-vs-total per app.
- **Re-validate after changes** with `MACVPP-Validation.ps1` so each change still meets the gate.

## Security & posture
- **Deploy only acquired, approved apps**; VPP keeps the catalog controlled and licensed.
- **Combine with a macOS compliance/security baseline** (separate solutions) so app delivery lands on a
  managed, compliant device.
- **Do not TLS-inspect Apple VPP/push endpoints** — it breaks license sync and install (Requirements
  R9).
