# 5. Testing & Validation — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Validate against a **pilot shared iPhone** before expanding. Each test has an explicit **pass/fail
gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device
steps for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSSDM-Discovery.ps1`.
**Pass:** The **DEM account** is registered, the APNs certificate is **Active**, the ADE token is
present, the `iOS – Shared Devices` group exists, the `iOS Shared – Kiosk Lockdown – Pilot` and
`iOS Shared – Restrictions – Pilot` profiles exist, **Cisco Webex** is added (Required), and a
compliance policy exists.
**Fail:** Any missing → resolve before piloting.

## Test 2 — Enrolled by DEM, no user affinity
**Procedure:** Inspect the pilot iPhone in Intune → **Devices → (device) → Properties**; run
`IOSSDM-Validation.ps1`.
**Pass:** **Enrolled by** = the `dem-ios-shared` account; **Primary user** is **none/empty**;
**Supervised = Yes**.
**Fail:** A primary user is set → re-enroll without user affinity via ADE (Implementation §7) or via
the DEM account.

## Test 3 — Device is in the shared group and gets policy
**Procedure:** Confirm group membership and policy application.
**Pass:** The iPhone is a member of **`iOS – Shared Devices`** and the kiosk, restrictions, and
compliance policies show **applied/succeeded**.
**Fail:** Not a member → add it (or fix the dynamic rule), then re-sync.

## Test 4 — Cisco Webex installed
**Procedure:** Inspect the device's managed apps (Intune) and the Home screen.
**Pass:** **Cisco Webex** shows **Installed** and is present on the device.
**Fail:** Not installed → confirm the Required assignment to `iOS – Shared Devices` and force a sync.

## Test 5 — Kiosk lock-down holds
**Procedure:** On the pilot iPhone, attempt to leave Webex / reach Settings, App Store, or Safari.
**Pass:** In **single-app** mode the device stays in **Cisco Webex** and cannot be exited; in
**multi-app** mode only the allowed apps appear and everything else is hidden. App Store/Safari are
unavailable.
**Fail:** Other apps/Settings reachable → confirm the device is **Supervised** (Test 2) and the
`iOS Shared – Kiosk Lockdown – Pilot` profile applied.

## Test 6 — Shared org account signs in and calls
**Procedure:** In Webex, sign in with the **`Shared Webex – iOS Phones`** account and place a test call.
**Pass:** Sign-in succeeds with the shared account and a call connects (audio both ways).
**Fail:** Sign-in fails → check the account's Webex licensing (R8) and any Conditional Access (Test 8);
call fails → check network/calling endpoints (R10) and Webex calling licensing.

## Test 7 — Restrictions enforced
**Procedure:** Verify the `iOS Shared – Restrictions – Pilot` controls (e.g. App Store blocked, account
modification blocked, erase blocked).
**Pass:** The blocked actions are unavailable; calling-related functions (cellular/Wi-Fi, microphone)
still work.
**Fail:** A restriction not applied → re-check the profile assignment and device sync.

## Test 8 — (If used) Conditional Access for the shared account
**Procedure:** With `CA – iOS Shared Webex` in report-only, sign into Webex from the kiosk phone and
review Entra → **Sign-in logs → Conditional Access**.
**Pass:** The shared account satisfies **compliant device** from the kiosk iPhone.
**Fail:** Blocked → confirm the device is compliant (Test 3) and the CA grant is correct.

## Acceptance gate
Proceed to **Expand** only when Tests 1–7 pass (and Test 8 if CA is used): the pilot iPhone is
**DEM-enrolled with no primary user**, **supervised**, **locked to Cisco Webex**, signed in with the
**shared organization account**, and a **call connects**.
