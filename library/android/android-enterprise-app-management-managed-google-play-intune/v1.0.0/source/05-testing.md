# 5. Testing & Validation — Android Enterprise App Management via Managed Google Play (Intune)

Validate on the **pilot** first, one enrolled device **per enrollment model** you target. Each test has
a **pass/fail** signal. Do not expand until all four gates pass on every targeted model.

## Test matrix (run per enrollment model)

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 Delivery — Required** | Assign an app as **Required** to the pilot group; sync the device | App installs **silently**, appears in the work profile / on the managed home screen | App never installs; stuck "pending" |
| 2 | **G1 Delivery — Available** | Assign an app as **Available for enrolled devices** (work-profile BYOD) | App is **listed in the work Play Store** and installs on tap | App not offered in the work Play Store |
| 3 | **G2 Managed config** | Attach an app-config policy with known keys (e.g. a server URL / account) | App opens **pre-configured**; the pushed values are present | App opens blank / prompts for setup |
| 4 | **G2 OEMConfig** (if used) | Push an OEM key via the OEM's OEMConfig app | The OEM setting is applied on the device | OEM setting unchanged |
| 5 | **G3 App protection** | Apply an Android APP policy; open the app's corporate data | PIN prompt appears; copy/paste / save-as blocked per policy | Data controls not enforced |
| 6 | **G4 Update track** | Assign the app on the **intended track** with a chosen auto-update mode | Installed build matches the track; updates follow the mode | App on the wrong track / not updating as set |
| 7 | **Scope / uninstall** | Set a Required app's intent to **Uninstall** for a test group | App is removed from the device | App remains |

## Automated checks
- **`ANDROIDAPP-Scope.ps1`** — managed Google Play binding connected + **app sync current** (pre-flight).
- **`ANDROIDAPP-Discovery.ps1`** — inventories approved managed Google Play apps and their
  assignment posture (intent, group, track, auto-update mode) so you can confirm what is targeted.
- **`ANDROIDAPP-AssignConfig.ps1 -WhatIf`** — prints the exact assignment + whether an app-config policy
  is attached for the app's package, **without writing**.
- **`ANDROIDAPP-AppProtection.ps1`** (read mode) — lists Android app protection policies + assignments.
- **`ANDROIDAPP-Validation.ps1`** — end-to-end report: per app, does it have an assignment, a managed
  config, an app protection policy, and a defined track/auto-update mode? Flags gaps.

## Evidence to capture
- Screenshots: app installed (work profile / managed home screen), app **pre-configured**, PIN prompt.
- `ANDROIDAPP-Discovery.ps1` / `ANDROIDAPP-Validation.ps1` output (CSV) showing intent, track, config, APP.
- The managed Google Play **approval settings** chosen for each app (permission-change handling).

## Exit criteria (before Expand)
- [ ] G1 Delivery — Required installs silently **and** Available appears, on every targeted model
- [ ] G2 Configuration — app arrives pre-configured (and OEM keys applied, if used)
- [ ] G3 Protection — APP controls enforced as configured (if APP in scope)
- [ ] G4 Update track — apps on the intended track, honoring auto-update mode
- [ ] Uninstall intent verified removes an app
- [ ] `ANDROIDAPP-Validation.ps1` shows no unexpected gaps for the pilot apps
