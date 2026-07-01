# 7. Best Practices — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Field-proven guidance for running a fleet of locked-down, shared iPhones.

## Enrollment & ownership model
- **Always enroll without user affinity.** Shared devices must have **no primary user** — use the ADE
  profile's **Enroll without user affinity** option, or enroll via the DEM account. A primary user on
  a shared phone breaks the model.
- **Prefer ADE over manual DEM enrollment.** ABM + ADE gives zero-touch, supervised, locked enrollment;
  keep the DEM account as the path for any device you must enroll by hand (Apple Configurator).
- **Watch the DEM cap.** A single DEM account enrolls a large but finite number of devices; for big
  fleets, split across multiple DEM accounts and document which account owns which batch.
- **Name everything by intent** — `DEM – iOS Shared Devices`, `iOS – Shared Devices`,
  `iOS Shared – Kiosk Lockdown – Pilot` — so the configuration is self-documenting and auditable.

## Lock-down (kiosk)
- **Supervise first, then lock.** Kiosk single/multi-app mode only works on supervised devices — confirm
  **Supervised = Yes** before expecting the lock-down to hold.
- **Single-app for pure calling; multi-app if you need the native Phone app.** Single full-screen app
  is the tightest lock; switch to multi-app only when staff genuinely need a second app, and hide
  everything else.
- **Don't over-restrict the call path.** Keep cellular/Wi-Fi, microphone, and Webex's networking
  enabled — a restriction that blocks the call defeats the purpose.
- **Stage restrictions in report/pilot first.** Apply the restrictions profile to one device and
  confirm calling still works before fleet-wide rollout.

## Shared account hygiene
- **Treat the shared Webex account as privileged.** Rotate its password on a schedule, store it in a
  password manager, and gate it with **Conditional Access** (compliant device) so it only works from a
  managed kiosk phone.
- **Decide your sign-out policy.** For truly shared use, decide whether Webex stays signed in between
  shifts or staff sign in/out — document it and configure accordingly.
- **Avoid per-user data on a shared device** — the device is a pool resource; keep personal data off it.

## App deployment
- **Deploy Webex Required before applying the kiosk.** The kiosk needs an installed app to lock to;
  push Webex first, confirm it installs, then enforce the kiosk.
- **Use VPP/ABM licensing for Webex where possible** — device-based VPP licensing fits shared,
  no-user-affinity devices better than per-user store installs.
- **Pin the bundle ID.** Lock to Cisco Webex by bundle ID (`com.cisco.squared`) so the kiosk targets
  the right app unambiguously.

## Rollout & operations
- **Pilot one phone end to end** — enroll, lock, sign in, place a call — before expanding.
- **Expand in waves**, validating each with `IOSSDM-Validation.ps1` before widening.
- **Report regularly** with `IOSSDM-DeviceReport.ps1`: enrollment account, supervision, kiosk state,
  Webex install, and compliance across the whole shared fleet.
- **Keep a runbook** of the DEM account(s), the shared group, the kiosk/restrictions/compliance
  profiles, the Webex app, and the shared Webex account — the moving parts that define the fleet.
