# 6. Troubleshooting — macOS App Deployment & Apple VPP with Microsoft Intune

Work top-down: confirm the **token & license sync** first, then **assignment**, then the **device**
(install), then **licensing**. Most failures are an expired/unsynced VPP token, a wrong license type,
an unsigned package, or a Mac that isn't supervised/managed.

## VPP apps don't appear in Intune / licenses show zero
- **Token not synced.** Intune → **`VPP – Corporate (Location A)` → Sync**; allow a few minutes (Apple
  rate-limits). Confirm with `MACVPP-Discovery.ps1`.
- **App not acquired in ABM.** The app must be **Get**-acquired under **Location A** first
  (Requirements R2), then synced.
- **Wrong location/token.** Licenses are per location — make sure the app was acquired in the same
  location whose token you connected (R2/R3).

## Token is expired or about to expire
- **Renew, don't recreate.** In ABM download a **fresh** `.vpptoken` for Location A (same managed
  Apple ID), then Intune → token → **Renew** and upload. A lapse **stops sync and new installs**.
- Run `MACVPP-Discovery.ps1` — it flags a token within 30 days of expiry.

## App Store app won't install on the Mac
- **Device not managed/checked in.** Intune → **Devices → macOS** must show the device; **Sync** it
  (Requirements R5).
- **Out of licenses.** `MACVPP-Report.ps1` — if consumed = total, acquire more in ABM under Location A
  and **Sync** (Requirements R2).
- **Assignment missing/wrong group.** Confirm the app is **Required** to **`PILOT – macOS App
  Deployment`** (Implementation Step 6).
- **Network blocks Apple.** Ensure `vpp.itunes.apple.com` / App Store / content endpoints are reachable
  and **not** TLS-inspected (Requirements R9).

## User is prompted for an Apple ID (expected silent)
- **The app is user-licensed, not device-licensed.** Set **License type = Device** on the assignment
  (Step 6) so it installs silently.
- **Mac not supervised/company-owned.** Device licensing expects a supervised, corporate Mac
  (Requirements R5). Fix ownership/supervision, or accept user licensing and invite the user.

## VPP license not consumed for a device
- **Licenses not synced** (Test 1) or **app not device-licensed** (Test 2) — correct and re-check.
- **Device hasn't checked in** — **Sync** the device and re-run `MACVPP-Validation.ps1`.

## Enterprise (LOB) `.pkg`/`.dmg` fails to install
- **Package not signed/notarized.** Gatekeeper blocks it — verify with `pkgutil --check-signature`
  (Requirements R7); re-sign with a **Developer ID Installer** cert and notarize.
- **Wrong/missing bundle ID or version** on the LOB upload — Intune can't detect install; re-enter the
  correct **bundle ID** and **build/version** (Implementation Step 7).
- **Not a distribution/component PKG** — some raw payloads don't install as managed; if it can't be
  made into a managed `.pkg`, use the **unmanaged PKG** type (Step 7 note).

## LOB update doesn't take
- **Version/build not higher.** Intune only updates when the new package's version/build **exceeds**
  the installed one — bump it and re-upload (Best Practices → Updates).
- **Device didn't check in** — **Sync** and re-check **Device install status**.

## Install status stuck "Pending"/"Failed" in Intune
- Give it a check-in cycle; then on the Mac inspect **Console.app** filtered for `MDM` /
  `AppInstall`, and the Intune app's **install error** detail. Re-run `MACVPP-Validation.ps1` after
  fixing.

## Token / sync expiry (preventive)
- The **VPP token expires annually** and **blocks sync + installs** if lapsed. Schedule
  `MACVPP-Discovery.ps1` (or `MACVPP-Remediation.ps1`) to run regularly; it flags anything within 30
  days and can re-sync the token. Always renew with the **same managed Apple ID** and location.

## Useful checkpoints
- **Intune:** Apps → macOS → (app) → **Device install status**; Apps → (VPP app) → **VPP licenses**;
  Tenant administration → **Connectors and tokens → Apple VPP tokens**.
- **Apple Business Manager:** **Apps** (license counts per location); **Locations** (the location
  exists); token owner (managed Apple ID).
- **On the Mac:** `/Applications` (app present); **System Settings → General → Device Management**
  (managed); **Console.app** for install logs.
- **Scripts:** re-run `MACVPP-Validation.ps1` after each change to confirm the gate.
