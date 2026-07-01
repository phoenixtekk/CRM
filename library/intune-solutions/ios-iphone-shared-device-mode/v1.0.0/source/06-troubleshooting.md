# 6. Troubleshooting — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Work top-down: confirm **enrollment** (DEM, no user affinity), then **supervision**, then **grouping**,
then **kiosk lock-down**, then the **Webex app**, then **calling**. Most issues are a device that
enrolled with a primary user, a device that isn't supervised, or the kiosk applied before Webex
installed.

## The iPhone enrolled with a primary user (not shared)
- **Wrong enrollment path.** It was enrolled with user affinity. Re-enroll via ADE with **Enroll
  without user affinity** (Implementation §7), or enroll signed in as the **`dem-ios-shared`** account.
- Confirm in **Devices → (device) → Properties**: **Primary user** must be empty, **Enrolled by** =
  the DEM account.

## Kiosk lock-down isn't holding (other apps reachable)
- **Device not supervised.** Single/multi-app kiosk requires **Supervised = Yes** (Properties). If it's
  unsupervised, re-enroll via ADE with Supervised enabled (Implementation §7).
- **Kiosk profile not applied.** Check `iOS Shared – Kiosk Lockdown – Pilot` shows **Succeeded** on the
  device and is assigned to **`iOS – Shared Devices`**.
- **App not installed yet.** The kiosk needs Webex installed to lock to — confirm Test 4 first.

## Cisco Webex didn't install
- **Assignment.** Webex must be **Required** to **`iOS – Shared Devices`** (Implementation §9); confirm
  the device is a group member.
- **VPP licensing.** If you deployed Webex via VPP, confirm device-based licenses are available and
  assigned. Force a device sync and re-check.

## The device isn't in the shared group
- **Static group:** add the device manually. **Dynamic group:** confirm the membership rule matches the
  ADE **enrollment profile name** used in Step 7, and allow time for dynamic evaluation.
- Re-run `IOSSDM-Validation.ps1` after the device appears in the group.

## Shared account can't sign into Webex
- **Webex licensing.** The shared account needs a Webex calling license in Cisco Webex Control Hub (R8).
- **Conditional Access.** If `CA – iOS Shared Webex` requires a compliant device, confirm the iPhone is
  **Compliant** (Test 3) — otherwise the shared account is correctly blocked. Read Entra → **Sign-in
  logs → Conditional Access**.
- **Wrong credentials.** Confirm the `Shared Webex – iOS Phones` account password (rotate if unsure).

## Calls won't connect (sign-in works)
- **Network/endpoints.** The Webex media/calling endpoints must be reachable (R10) — verify proxy/
  firewall allows Cisco Webex's published ranges.
- **Restrictions too tight.** Confirm `iOS Shared – Restrictions – Pilot` did not disable cellular/Wi-Fi
  or the microphone.
- **Webex calling service.** Confirm the calling plan/licensing is active in Webex Control Hub.

## Enrollment fails at Setup Assistant
- **APNs/ADE token lapsed.** Renew the **Apple MDM Push certificate** (R3) and the **ADE token** (R4) —
  an expired token blocks all iOS enrollment.
- **Serial not assigned.** Confirm the serial is in ABM and assigned to the `Intune – iOS Shared` MDM
  server, and the `iOS Shared – ADE – Pilot` profile is assigned (Implementation §8).

## Useful checkpoints
- **Intune:** Devices → (device) → **Properties** (primary user, supervised), **Device configuration**
  (kiosk/restrictions status), **Managed apps** (Webex install); Devices → Enrollment → Apple for
  APNs/ADE token status; Devices → Enrollment → **Device enrollment managers** for the DEM account.
- **Entra:** **Sign-in logs → Conditional Access** for the shared account.
- **Scripts:** re-run `IOSSDM-Validation.ps1` after each change to confirm the gate.
