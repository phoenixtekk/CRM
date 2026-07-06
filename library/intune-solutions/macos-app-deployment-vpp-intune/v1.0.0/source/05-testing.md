# 5. Testing & Validation — macOS App Deployment & Apple VPP with Microsoft Intune

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the user experience.

## Test 1 — Tenant readiness (token + license sync)
**Procedure:** Run `MACVPP-Discovery.ps1`.
**Pass:** The VPP token **`VPP – Corporate (Location A)`** is **Active/Valid** (expiry > 30 days),
**last sync is recent**, and at least one **App Store app with synced licenses** is present.
**Fail:** Token missing/expiring within 30 days, or no synced apps → resolve before assigning apps.

## Test 2 — App Store (VPP) app assigned to the pilot
**Procedure:** In Intune → **Apps → macOS → (the store app) → Assignments**; confirm the assignment.
**Pass:** The app is **Required** to **`PILOT – macOS App Deployment`** with **License type = Device**.
**Fail:** Wrong group, wrong license type, or not assigned → correct the assignment (Implementation
Step 6).

## Test 3 — Silent install on a pilot Mac (device licensing)
**Procedure:** Sync a pilot Mac and wait for delivery.
**Pass:** The VPP app installs **silently** with **no Apple ID prompt and no App Store sign-in**, and
appears in `/Applications`.
**Fail:** The user is prompted for an Apple ID → the assignment is user-licensed, or the Mac is not
supervised/company-owned (Requirements R5, R8). Switch to device licensing and re-check.

## Test 4 — VPP license consumed for the device
**Procedure:** In Intune → **Apps → (the VPP app) → (VPP licenses/associated licenses)**, or run
`MACVPP-Validation.ps1 -Serial <serial>`.
**Pass:** A VPP license shows **consumed/assigned** to the pilot device; consumed count increased by
one.
**Fail:** No license consumed → confirm licenses synced (Test 1), the app is device-licensed (Test 2),
and the device checked in.

## Test 5 — Enterprise (LOB) app installs
**Procedure:** Confirm the signed `.pkg`/`.dmg` app on the pilot Mac (or `MACVPP-Validation.ps1`).
**Pass:** The LOB app is present in `/Applications` and Intune reports **Device install status =
Installed** for it.
**Fail:** Not installed → verify the package is **signed/notarized** (Requirements R7) and assigned to
the pilot group (Step 8); check `Console.app`/Intune install error for the reason.

## Test 6 — Install status reported in Intune
**Procedure:** In Intune → **Apps → (each app) → Device install status**.
**Pass:** The pilot device shows **Installed** for both the VPP app and the LOB app.
**Fail:** Shows **Failed/Pending** past a check-in cycle → see Troubleshooting; re-run
`MACVPP-Validation.ps1` after fixing.

## Test 7 — License headroom is sufficient
**Procedure:** Run `MACVPP-Report.ps1`.
**Pass:** Every deployed app has **consumed < total** licenses (headroom for the next wave); no app is
**out of licenses**.
**Fail:** An app at 100% consumption → acquire more licenses in ABM under Location A, then **Sync**
before expanding.

## Test 8 — Updates flow
**Procedure:** For a store app, confirm a newer App Store version updates on managed Macs; for LOB,
upload a newer signed `.pkg` (higher version) and confirm the update installs.
**Pass:** Managed Macs move to the newer version without user interaction (store) / after the package
update (LOB).
**Fail:** Version doesn't advance → confirm the app is **Required**, the device checks in, and (LOB)
the new package version/build is **higher** than the installed one.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot Mac — the App Store app installs
**silently and device-licensed**, the enterprise app installs, both report **Installed**, and license
headroom is confirmed.
